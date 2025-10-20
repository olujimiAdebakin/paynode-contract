// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPGatewaySettings} from "../interface/IPGatewaySettings.sol";
import {IPayNodeAccessManager} from "../interface/IAccessManager.sol";
import {PGatewaySettings} from "./PGatewaySettings.sol";
import "./PGatewayStructs.sol";

/**
 * @title PayNode Gateway
 * @notice Non-custodial payment aggregator with parallel settlement and provider intent registry
 * @dev Implements upgradeable pattern, uses IPayNodeAccessManager for access control and reentrancy protection,
 *      and IPGatewaySettings for configuration. Uses PGatewayStructs for shared data structures.
 */
contract PGateway is Initializable, PausableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

    // Access Manager and Settings
    IPayNodeAccessManager public accessManager;
    IPGatewaySettings public settings;

    // Core Mappings
    mapping(bytes32 => PGatewayStructs.Order) public orders;
    mapping(bytes32 => PGatewayStructs.SettlementProposal) public proposals;
    mapping(address => PGatewayStructs.ProviderIntent) public providerIntents;
    mapping(address => PGatewayStructs.ProviderReputation) public providerReputation;
    mapping(address => uint256) public userNonce;
    mapping(bytes32 => bool) public proposalExecuted;

    /* ========== EVENTS ========== */

    /// @notice Emitted when a provider registers intent to provide liquidity
    /// @param provider Address of the provider
    /// @param currency Currency code (e.g., "USDT", "NGN", "USD")
    /// @param availableAmount Amount available for settlement
    /// @param commitmentWindow Commitment period for accepting settlements
    /// @param expiresAt Timestamp when the intent expires
    event IntentRegistered(
        address indexed provider,
        string indexed currency,
        uint256 availableAmount,
        uint256 commitmentWindow,
        uint256 expiresAt
    );

    /// @notice Emitted when a provider updates their available capacity
    /// @param provider Address of the provider
    /// @param currency Currency code
    /// @param newAmount Updated available amount
    /// @param timestamp Time of update
    event IntentUpdated(address indexed provider, string indexed currency, uint256 newAmount, uint256 timestamp);

    /// @notice Emitted when a provider intent expires automatically
    /// @param provider Address of the provider
    /// @param currency Currency code
    event IntentExpired(address indexed provider, string indexed currency);

    /// @notice Emitted when a provider releases reserved capacity
    /// @param provider Address of the provider
    /// @param currency Currency code
    /// @param releaseAmount Amount released
    /// @param reason Reason for release
    event IntentReleased(address indexed provider, string indexed currency, uint256 releaseAmount, string reason);

    /// @notice Emitted when a new user order is created
    /// @param orderId Unique identifier of the order
    /// @param user Address of the user who created the order
    /// @param token ERC20 token address used for payment
    /// @param amount Order amount
    /// @param tier Tier classification of the order
    /// @param expiresAt Expiration timestamp of the order
    event OrderCreated(
        bytes32 indexed orderId,
        address indexed user,
        address token,
        uint256 amount,
        PGatewayStructs.OrderTier tier,
        uint256 expiresAt
    );

    /// @notice Emitted when a provider creates a settlement proposal
    /// @param proposalId Unique identifier for the proposal
    /// @param orderId Associated order ID
    /// @param provider Address of the provider
    /// @param amount Proposed settlement amount
    /// @param feeBps Proposed fee in basis points
    /// @param deadline Proposal expiration time
    event SettlementProposalCreated(
        bytes32 indexed proposalId,
        bytes32 indexed orderId,
        address indexed provider,
        uint256 amount,
        uint64 feeBps,
        uint256 deadline
    );

    /// @notice Emitted when a settlement proposal is accepted
    /// @param proposalId Accepted proposal ID
    /// @param orderId Associated order ID
    /// @param provider Address of the provider
    /// @param timestamp Acceptance timestamp
    event SettlementProposalAccepted(
        bytes32 indexed proposalId, bytes32 indexed orderId, address indexed provider, uint256 timestamp
    );

    /// @notice Emitted when a proposal is rejected
    /// @param proposalId Proposal ID
    /// @param provider Address of the rejecting provider
    /// @param reason Reason for rejection
    event SettlementProposalRejected(bytes32 indexed proposalId, address indexed provider, string reason);

    /// @notice Emitted when a proposal times out
    /// @param proposalId Proposal ID
    /// @param provider Address of the provider
    event SettlementProposalTimeout(bytes32 indexed proposalId, address indexed provider);

    /// @notice Emitted after a successful settlement execution
    /// @param orderId Order ID
    /// @param proposalId Proposal ID used for settlement
    /// @param provider Address of the provider
    /// @param amount Settled amount
    /// @param feeBps Fee applied in basis points
    /// @param protocolFee Protocol’s share of the fee
    event SettlementExecuted(
        bytes32 indexed orderId,
        bytes32 indexed proposalId,
        address indexed provider,
        uint256 amount,
        uint64 feeBps,
        uint256 protocolFee,
        uint46 integratorFee
    );

    /// @notice Emitted when an order is refunded
    /// @param orderId Order ID
    /// @param user Address of the user
    /// @param amount Refunded amount
    /// @param reason Reason for refund
    event OrderRefunded(bytes32 indexed orderId, address indexed user, uint256 amount, string reason);

    /// @notice Emitted when a provider’s reputation is updated
    /// @param provider Address of the provider
    /// @param successfulOrders Count of successful orders
    /// @param failedOrders Count of failed orders
    /// @param noShowCount Count of times provider didn’t respond
    event ProviderReputationUpdated(
        address indexed provider, uint256 successfulOrders, uint256 failedOrders, uint256 noShowCount
    );

    /// @notice Emitted when a provider is blacklisted
    /// @param provider Address of the provider
    /// @param reason Reason for blacklisting
    event ProviderBlacklisted(address indexed provider, string reason);

    /// @notice Emitted when a provider is flagged as fraudulent
    /// @param provider Address of the provider
    event ProviderFraudFlagged(address indexed provider);

    /* ========== ERRORS ========== */

    error InvalidAmount();
    error InvalidAddress();
    error InvalidFee();
    error InvalidOrder();
    error InvalidProposal();
    error InvalidIntent();
    error IntentNotExpired();
    error OrderExpired();
    error Unauthorized();
    // error ProviderBlacklisted();
    error TokenNotSupported();

    /* ========== MODIFIERS ========== */

    /// @notice Ensures the caller is the aggregator
    modifier onlyAggregator() {
        require(accessManager.hasRole(accessManager.AGGREGATOR_ROLE(), msg.sender), "Unauthorized");
        _;
    }

    /// @notice Ensures the caller is not blacklisted
    modifier whenNotBlacklisted() {
        require(!accessManager.isBlacklisted(msg.sender), "UserBlacklisted");
        _;
    }

    /// @notice Ensures the caller is a registered provider
    modifier onlyProvider() {
        require(providerIntents[msg.sender].provider != address(0), "NotRegisteredProvider");
        _;
    }

    /// @notice Ensures the token is supported
    modifier validToken(address _token) {
        require(settings.isTokenSupported(_token), "TokenNotSupported");
        _;
    }

    /// @notice Ensures the order exists
    modifier validOrder(bytes32 _orderId) {
        require(orders[_orderId].user != address(0), "OrderNotFound");
        _;
    }

    /* ========== INITIALIZATION ========== */

    /// @notice Initializes the contract with access manager and settings
    /// @param _accessManager Address of the PayNodeAccessManager contract
    /// @param _settings Address of the PGatewaySettings contract
    function initialize(address _accessManager, address _settings) external initializer {
        require(_accessManager != address(0) && _settings != address(0), "InvalidAddress");

        __Pausable_init();
        __UUPSUpgradeable_init();

        accessManager = IPayNodeAccessManager(_accessManager);
        settings = IPGatewaySettings(_settings);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /// @notice Pauses the contract
    /// @dev Requires DEFAULT_ADMIN_ROLE
    function pause() external {
        require(accessManager.executeNonReentrant(msg.sender, accessManager.DEFAULT_ADMIN_ROLE()), "Unauthorized");
        _pause();
    }

    /// @notice Unpauses the contract
    /// @dev Requires DEFAULT_ADMIN_ROLE
    function unpause() external {
        require(accessManager.executeNonReentrant(msg.sender, accessManager.DEFAULT_ADMIN_ROLE()), "Unauthorized");
        _unpause();
    }

    /// @notice Authorizes contract upgrades
    /// @param newImplementation Address of the new implementation contract
    /// @dev Requires ADMIN_ROLE
    function _authorizeUpgrade(address newImplementation) internal view override {
        require(accessManager.hasRole(accessManager.ADMIN_ROLE(), msg.sender), "Unauthorized");
    }

    /* ========== PROVIDER INTENT FUNCTIONS ========== */

    /// @notice Registers provider intent with available capacity
    /// @param _currency Currency code (e.g., "USDT", "NGN", "USD")
    /// @param _availableAmount Amount provider can handle
    /// @param _minFeeBps Minimum fee in basis points
    /// @param _maxFeeBps Maximum fee in basis points
    /// @param _commitmentWindow Time window for provider to accept proposal
    function registerIntent(
        string calldata _currency,
        uint256 _availableAmount,
        uint64 _minFeeBps,
        uint64 _maxFeeBps,
        uint256 _commitmentWindow
    ) external whenNotPaused whenNotBlacklisted {
        require(accessManager.executeProviderNonReentrant(msg.sender), "InvalidProvider");
        require(_availableAmount > 0, "InvalidAmount");
        require(_minFeeBps <= _maxFeeBps, "InvalidFee");
        require(_maxFeeBps <= settings.maxProtocolFee(), "InvalidFee");
        require(_commitmentWindow > 0, "InvalidDuration");

        address provider = msg.sender;
        require(!providerReputation[provider].isBlacklisted, "ProviderBlacklisted");

        uint256 expiresAt = block.timestamp + settings.intentExpiry();

        providerIntents[provider] = PGatewayStructs.ProviderIntent({
            provider: provider,
            currency: _currency,
            availableAmount: _availableAmount,
            minFeeBps: _minFeeBps,
            maxFeeBps: _maxFeeBps,
            registeredAt: block.timestamp,
            expiresAt: expiresAt,
            commitmentWindow: _commitmentWindow,
            isActive: true
        });

        if (providerReputation[provider].provider == address(0)) {
            providerReputation[provider].provider = provider;
        }

        emit IntentRegistered(provider, _currency, _availableAmount, _commitmentWindow, expiresAt);
    }

    /// @notice Updates existing provider intent
    /// @param _currency Currency code
    /// @param _newAmount New available amount
    function updateIntent(string calldata _currency, uint256 _newAmount) external onlyProvider whenNotPaused {
        require(accessManager.executeProviderNonReentrant(msg.sender), "InvalidProvider");
        require(_newAmount > 0, "InvalidAmount");

        PGatewayStructs.ProviderIntent storage intent = providerIntents[msg.sender];
        require(intent.isActive, "InvalidIntent");

        intent.availableAmount = _newAmount;
        intent.registeredAt = block.timestamp;
        intent.expiresAt = block.timestamp + settings.intentExpiry();

        emit IntentUpdated(msg.sender, _currency, _newAmount, block.timestamp);
    }

    /// @notice Expires provider intent
    /// @param _provider Provider address
    function expireIntent(address _provider) external onlyAggregator {
        require(accessManager.executeAggregatorNonReentrant(msg.sender), "Unauthorized");
        PGatewayStructs.ProviderIntent storage intent = providerIntents[_provider];
        require(intent.isActive, "InvalidIntent");
        require(block.timestamp > intent.expiresAt, "IntentNotExpired");

        intent.isActive = false;
        emit IntentExpired(_provider, intent.currency);
    }

    /// @notice Reserves capacity when a proposal is sent
    /// @param _provider Provider address
    /// @param _amount Amount to reserve
    function reserveIntent(address _provider, uint256 _amount) external onlyAggregator {
        require(accessManager.executeAggregatorNonReentrant(msg.sender), "Unauthorized");
        PGatewayStructs.ProviderIntent storage intent = providerIntents[_provider];
        require(intent.isActive, "InvalidIntent");
        require(intent.availableAmount >= _amount, "InvalidAmount");

        intent.availableAmount -= _amount;
    }

    /// @notice Releases reserved capacity if proposal is rejected or times out
    /// @param _provider Provider address
    /// @param _amount Amount to release
    /// @param _reason Reason for release
    function releaseIntent(address _provider, uint256 _amount, string calldata _reason) external onlyAggregator {
        require(accessManager.executeAggregatorNonReentrant(msg.sender), "Unauthorized");
        PGatewayStructs.ProviderIntent storage intent = providerIntents[_provider];
        intent.availableAmount += _amount;
        emit IntentReleased(_provider, intent.currency, _amount, _reason);
    }

    /// @notice Gets active provider intent
    /// @param _provider Provider address
    /// @return ProviderIntent struct containing intent details
    function getProviderIntent(address _provider) external view returns (PGatewayStructs.ProviderIntent memory) {
        return providerIntents[_provider];
    }

    /* ========== ORDER CREATION FUNCTIONS ========== */

    /// @notice Creates a new payment order
    /// @param _token ERC20 token address
    /// @param _amount Order amount
    /// @param _refundAddress Address for refunds
    /// @return orderId Generated unique order ID
    function createOrder(address _token, uint256 _amount, address _refundAddress, string calldata _messageHash)
        external
        whenNotPaused
        whenNotBlacklisted
        validToken(_token)
        returns (bytes32 orderId)
    {
        require(_amount > 0, "InvalidAmount");
        require(_refundAddress != address(0), "InvalidAddress");
        require(accessManager.executeNonReentrant(msg.sender, bytes32(0)), "Unauthorized");

        PGatewayStructs.OrderTier tier = _determineTier(_amount);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        userNonce[msg.sender]++;
        orderId = keccak256(abi.encode(msg.sender, userNonce[msg.sender], block.chainid));

        orders[orderId] = PGatewayStructs.Order({
            orderId: orderId,
            user: msg.sender,
            token: _token,
            amount: _amount,
            tier: tier,
            status: PGatewayStructs.OrderStatus.PENDING,
            refundAddress: _refundAddress,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + settings.orderExpiryWindow(),
            acceptedProposalId: bytes32(0),
            fulfilledByProvider: address(0),
            integrator: settings.aggregatorAddress(),
            integratorFee: settings.integratorFeePercent() 
        });

        emit OrderCreated(orderId, msg.sender, _token, _amount, tier, orders[orderId].expiresAt);
        return orderId;
    }

    /// @notice Determines order tier based on amount
    /// @param _amount Order amount
    /// @return OrderTier enum value
    function _determineTier(uint256 _amount) internal view returns (PGatewayStructs.OrderTier) {
        if (_amount < settings.ALPHA_TIER_LIMIT()) return PGatewayStructs.OrderTier.ALPHA;
        if (_amount < settings.BETA_TIER_LIMIT()) return PGatewayStructs.OrderTier.BETA;
        if (_amount < settings.DELTA_TIER_LIMIT()) return PGatewayStructs.OrderTier.DELTA;
        if (_amount < settings.OMEGA_TIER_LIMIT()) return PGatewayStructs.OrderTier.OMEGA;
        return PGatewayStructs.OrderTier.TITAN;
    }

    /// @notice Gets order details
    /// @param _orderId Order ID
    /// @return Order struct containing order data
    function getOrder(bytes32 _orderId) external view validOrder(_orderId) returns (PGatewayStructs.Order memory) {
        return orders[_orderId];
    }

    /* ========== SETTLEMENT PROPOSAL FUNCTIONS ========== */

    /// @notice Creates a settlement proposal for an order
    /// @param _orderId Associated order ID
    /// @param _provider Provider address
    /// @param _proposedFeeBps Proposed fee in basis points
    /// @return proposalId Generated proposal ID
    function createProposal(bytes32 _orderId, address _provider, uint64 _proposedFeeBps)
        external
        onlyAggregator
        validOrder(_orderId)
        returns (bytes32 proposalId)
    {
        require(accessManager.executeAggregatorNonReentrant(msg.sender), "Unauthorized");
        PGatewayStructs.Order storage order = orders[_orderId];
        require(order.status == PGatewayStructs.OrderStatus.PENDING, "InvalidOrder");
        require(block.timestamp < order.expiresAt, "OrderExpired");

        PGatewayStructs.ProviderIntent memory intent = providerIntents[_provider];
        require(intent.isActive, "InvalidIntent");
        require(intent.availableAmount >= order.amount, "InvalidAmount");
        require(_proposedFeeBps >= intent.minFeeBps && _proposedFeeBps <= intent.maxFeeBps, "InvalidFee");

        proposalId = keccak256(abi.encode(_orderId, _provider, block.timestamp, block.number));
        uint256 deadline = block.timestamp + settings.proposalTimeout();

        proposals[proposalId] = PGatewayStructs.SettlementProposal({
            proposalId: proposalId,
            orderId: _orderId,
            provider: _provider,
            proposedAmount: order.amount,
            proposedFeeBps: _proposedFeeBps,
            proposedAt: block.timestamp,
            proposalDeadline: deadline,
            status: PGatewayStructs.ProposalStatus.PENDING
        });

        order.status = PGatewayStructs.OrderStatus.PROPOSED;
        emit SettlementProposalCreated(proposalId, _orderId, _provider, order.amount, _proposedFeeBps, deadline);
        return proposalId;
    }

    /// @notice Provider accepts a settlement proposal
    /// @param _proposalId Proposal ID to accept
    function acceptProposal(bytes32 _proposalId) external onlyProvider whenNotPaused {
        require(accessManager.executeProviderNonReentrant(msg.sender), "InvalidProvider");
        PGatewayStructs.SettlementProposal storage proposal = proposals[_proposalId];
        require(proposal.provider == msg.sender, "Unauthorized");
        require(proposal.status == PGatewayStructs.ProposalStatus.PENDING, "InvalidProposal");
        require(block.timestamp < proposal.proposalDeadline, "InvalidProposal");

        proposal.status = PGatewayStructs.ProposalStatus.ACCEPTED;
        PGatewayStructs.Order storage order = orders[proposal.orderId];
        order.status = PGatewayStructs.OrderStatus.ACCEPTED;
        order.acceptedProposalId = _proposalId;
        order.fulfilledByProvider = msg.sender;

        emit SettlementProposalAccepted(_proposalId, proposal.orderId, msg.sender, block.timestamp);
    }

    /// @notice Provider rejects a settlement proposal
    /// @param _proposalId Proposal ID to reject
    /// @param _reason Reason for rejection
    function rejectProposal(bytes32 _proposalId, string calldata _reason) external onlyProvider {
        require(accessManager.executeProviderNonReentrant(msg.sender), "InvalidProvider");
        PGatewayStructs.SettlementProposal storage proposal = proposals[_proposalId];
        require(proposal.provider == msg.sender, "Unauthorized");
        require(proposal.status == PGatewayStructs.ProposalStatus.PENDING, "InvalidProposal");

        proposal.status = PGatewayStructs.ProposalStatus.REJECTED;
        providerReputation[msg.sender].noShowCount++;
        emit SettlementProposalRejected(_proposalId, msg.sender, _reason);
    }

    /// @notice Marks a proposal as timed out
    /// @param _proposalId Proposal ID
    function timeoutProposal(bytes32 _proposalId) external onlyAggregator {
        require(accessManager.executeAggregatorNonReentrant(msg.sender), "Unauthorized");
        PGatewayStructs.SettlementProposal storage proposal = proposals[_proposalId];
        require(proposal.status == PGatewayStructs.ProposalStatus.PENDING, "InvalidProposal");
        require(block.timestamp > proposal.proposalDeadline, "InvalidProposal");

        proposal.status = PGatewayStructs.ProposalStatus.TIMEOUT;
        emit SettlementProposalTimeout(_proposalId, proposal.provider);
    }

    /// @notice Gets settlement proposal details
    /// @param _proposalId Proposal ID
    /// @return SettlementProposal struct with proposal details
    function getProposal(bytes32 _proposalId) external view returns (PGatewayStructs.SettlementProposal memory) {
        return proposals[_proposalId];
    }

    /* ========== SETTLEMENT EXECUTION FUNCTIONS ========== */

    /// @notice Executes settlement after proposal acceptance
    /// @param _proposalId Accepted proposal ID
    function executeSettlement(bytes32 _proposalId) external onlyAggregator {
        require(accessManager.executeAggregatorNonReentrant(msg.sender), "Unauthorized");
        PGatewayStructs.SettlementProposal storage proposal = proposals[_proposalId];
        require(proposal.status == PGatewayStructs.ProposalStatus.ACCEPTED, "InvalidProposal");
        require(!proposalExecuted[_proposalId], "InvalidProposal");

        PGatewayStructs.Order storage order = orders[proposal.orderId];
        require(order.status == PGatewayStructs.OrderStatus.ACCEPTED, "InvalidOrder");

        uint256 integratorFee = (proposal.proposedAmount * settings.integratorFeePercent()) / settings.MAX_BPS();
        uint256 protocolFee = (proposal.proposedAmount * settings.protocolFeePercent()) / settings.MAX_BPS();
        uint256 providerFee = (proposal.proposedAmount * proposal.proposedFeeBps) / settings.MAX_BPS();
        uint256 providerAmount = proposal.proposedAmount - protocolFee;

        IERC20(order.token).safeTransfer(settings.treasuryAddress(), protocolFee);
        IERC20(order.token).safeTransfer(order.integrator, integratorFee);
        IERC20(order.token).safeTransfer(proposal.provider, providerAmount);

        proposalExecuted[_proposalId] = true;
        order.status = PGatewayStructs.OrderStatus.FULFILLED;

        _updateProviderSuccess(proposal.provider, block.timestamp - proposal.proposedAt);

        emit SettlementExecuted(
            proposal.orderId, _proposalId, proposal.provider, providerAmount, proposal.proposedFeeBps, protocolFee, integratorFee
        );
    }

    /* ========== REFUND FUNCTIONS ========== */

    /// @notice Refunds an order if no provider accepts within timeout
    /// @param _orderId Order ID to refund
    function refundOrder(bytes32 _orderId) external onlyAggregator validOrder(_orderId) {
        require(accessManager.executeAggregatorNonReentrant(msg.sender), "Unauthorized");
        PGatewayStructs.Order storage order = orders[_orderId];
        require(order.status != PGatewayStructs.OrderStatus.FULFILLED, "InvalidOrder");
        require(order.status != PGatewayStructs.OrderStatus.REFUNDED, "InvalidOrder");
        require(block.timestamp > order.expiresAt, "OrderNotExpired");

        order.status = PGatewayStructs.OrderStatus.REFUNDED;
        IERC20(order.token).safeTransfer(order.refundAddress, order.amount);

        emit OrderRefunded(_orderId, order.user, order.amount, "OrderTimeout");
    }

    /// @notice Allows user to request a refund
    /// @param _orderId Order ID to refund
    function requestRefund(bytes32 _orderId) external validOrder(_orderId) {
        require(accessManager.executeNonReentrant(msg.sender, bytes32(0)), "Unauthorized");
        PGatewayStructs.Order storage order = orders[_orderId];
        require(order.user == msg.sender, "Unauthorized");
        require(
            order.status == PGatewayStructs.OrderStatus.PENDING || order.status == PGatewayStructs.OrderStatus.PROPOSED,
            "InvalidOrder"
        );
        require(block.timestamp > order.expiresAt, "OrderNotExpired");

        order.status = PGatewayStructs.OrderStatus.CANCELLED;
        IERC20(order.token).safeTransfer(order.refundAddress, order.amount);

        emit OrderRefunded(_orderId, msg.sender, order.amount, "UserRequested");
    }

    /* ========== REPUTATION FUNCTIONS ========== */

    /// @notice Updates provider success metrics
    /// @param _provider Provider address
    /// @param _settlementTime Time taken to settle
    function _updateProviderSuccess(address _provider, uint256 _settlementTime) internal {
        PGatewayStructs.ProviderReputation storage rep = providerReputation[_provider];
        rep.totalOrders++;
        rep.successfulOrders++;
        rep.totalSettlementTime += _settlementTime;
        rep.lastUpdated = block.timestamp;

        emit ProviderReputationUpdated(_provider, rep.successfulOrders, rep.failedOrders, rep.noShowCount);
    }

    /// @notice Flags a provider as fraudulent
    /// @param _provider Provider address
    function flagFraudulent(address _provider) external onlyAggregator {
        require(accessManager.executeAggregatorNonReentrant(msg.sender), "Unauthorized");
        require(providerReputation[_provider].provider != address(0), "InvalidAddress");
        providerReputation[_provider].isFraudulent = true;
        providerIntents[_provider].isActive = false;

        emit ProviderFraudFlagged(_provider);
    }

    /// @notice Blacklists a provider
    /// @param _provider Provider address
    /// @param _reason Reason for blacklisting
    function blacklistProvider(address _provider, string calldata _reason) external {
        require(accessManager.executeNonReentrant(msg.sender, accessManager.DEFAULT_ADMIN_ROLE()), "Unauthorized");
        providerReputation[_provider].isBlacklisted = true;
        providerIntents[_provider].isActive = false;

        emit ProviderBlacklisted(_provider, _reason);
    }

    /// @notice Gets provider reputation data
    /// @param _provider Provider address
    /// @return ProviderReputation struct with reputation metrics
    function getProviderReputation(address _provider)
        external
        view
        returns (PGatewayStructs.ProviderReputation memory)
    {
        return providerReputation[_provider];
    }

    /* ========== UTILITY FUNCTIONS ========== */

    /// @notice Gets user nonce for replay protection
    /// @param _user User address
    /// @return nonce Current nonce
    function getUserNonce(address _user) external view returns (uint256) {
        return userNonce[_user];
    }

    // Reserve for upgrades
    uint256[50] private __gap;
}

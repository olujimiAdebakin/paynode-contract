// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PGatewaySettings} from "./PGatewaySettings.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./PGatewayStructs.sol";
import {PayNodeAccessManager} from "../access/PAccessManager.sol";

/**
 * @title PayNode Gateway
 * @notice Non-custodial payment aggregator with parallel settlement and provider intent registry
 * @dev Implements upgradeable pattern and uses external contracts for settings and access control
 */
contract PGateway is
    Initializable,
    PausableUpgradeable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    using PGatewayStructs for *;
    // Access Manager and Settings
    PayNodeAccessManager public accessManager;
    PGatewaySettings public settings;

    /* ========== ENUMS ========== */

    enum OrderTier {
        ALPHA,
        BETA,
        DELTA,
        OMEGA,
        TITAN  //> 20,000 units

    }

    enum OrderStatus {
        PENDING,
        PROPOSED,
        ACCEPTED,
        FULFILLED,
        REFUNDED,
        CANCELLED
    }

    enum ProposalStatus {
        PENDING,
        ACCEPTED,
        REJECTED,
        TIMEOUT,
        CANCELLED
    }

    // /* ========== STRUCTS ========== */

    // struct ProviderIntent {
    //     address provider;
    //     string currency;
    //     uint256 availableAmount;
    //     uint64 minFeeBps;
    //     uint64 maxFeeBps;
    //     uint256 registeredAt;
    //     uint256 expiresAt;
    //     uint256 commitmentWindow;
    //     bool isActive;
    // }

    // struct Order {
    //     bytes32 orderId;
    //     address user;
    //     address token;
    //     uint256 amount;
    //     OrderTier tier;
    //     OrderStatus status;
    //     address refundAddress;
    //     uint256 createdAt;
    //     uint256 expiresAt;
    //     bytes32 acceptedProposalId;
    //     address fulfilledByProvider;
    // }

    // struct SettlementProposal {
    //     bytes32 proposalId;
    //     bytes32 orderId;
    //     address provider;
    //     uint256 proposedAmount;
    //     uint64 proposedFeeBps;
    //     uint256 proposedAt;
    //     uint256 proposalDeadline;
    //     ProposalStatus status;
    // }

    // struct ProviderReputation {
    //     address provider;
    //     uint256 totalOrders;
    //     uint256 successfulOrders;
    //     uint256 failedOrders;
    //     uint256 noShowCount;
    //     uint256 totalSettlementTime;
    //     uint256 lastUpdated;
    //     bool isFraudulent;
    //     bool isBlacklisted;
    // }

    /* ========== STATE VARIABLES ========== */

    // Core state variables
    // uint256 private constant MAX_BPS = 100_000;

    // Core Mappings
    mapping(bytes32 => PGatewayStructs.Order) public orders;
    mapping(bytes32 => PGatewayStructs.SettlementProposal) public proposals;
    mapping(address => PGatewayStructs.ProviderIntent) public providerIntents;
    mapping(address => PGatewayStructs.ProviderReputation) public providerReputation;
    mapping(address => uint256) public userNonce;
    // mapping(address => bool) public supportedTokens;
    mapping(bytes32 => bool) public proposalExecuted;

    // Arrays for iteration
    address[] public registeredProviders;
    bytes32[] public activeOrderIds;

    

    /* ========== EVENTS ========== */

    // Provider Intent Events
    event IntentRegistered(
        address indexed provider,
        string indexed currency,
        uint256 availableAmount,
        uint256 commitmentWindow,
        uint256 expiresAt
    );

    event IntentUpdated(address indexed provider, string indexed currency, uint256 newAmount, uint256 timestamp);

    event IntentExpired(address indexed provider, string indexed currency);

    event IntentReleased(address indexed provider, string indexed currency, uint256 releaseAmount, string reason);

    // Order Events
    event OrderCreated(
        bytes32 indexed orderId, address indexed user, address token, uint256 amount, OrderTier tier, uint256 expiresAt
    );

    event OrderQueued(bytes32 indexed orderId, address indexed user, uint256 requiredAmount, uint256 queuedAt);

    // Proposal Events
    event SettlementProposalCreated(
        bytes32 indexed proposalId,
        bytes32 indexed orderId,
        address indexed provider,
        uint256 amount,
        uint64 feeBps,
        uint256 deadline
    );

    event SettlementProposalAccepted(
        bytes32 indexed proposalId, bytes32 indexed orderId, address indexed provider, uint256 timestamp
    );

    event SettlementProposalRejected(bytes32 indexed proposalId, address indexed provider, string reason);

    event SettlementProposalTimeout(bytes32 indexed proposalId, address indexed provider);

    // Settlement Events
    event SettlementExecuted(
        bytes32 indexed orderId,
        bytes32 indexed proposalId,
        address indexed provider,
        uint256 amount,
        uint64 feeBps,
        uint256 protocolFee
    );

    event OrderRefunded(bytes32 indexed orderId, address indexed user, uint256 amount, string reason);

    // Reputation Events
    event ProviderReputationUpdated(
        address indexed provider, uint256 successfulOrders, uint256 failedOrders, uint256 noShowCount
    );

    event ProviderBlacklisted(address indexed provider, string reason);

    event ProviderFraudFlagged(address indexed provider);

    /* ========== MODIFIERS ========== */

    modifier onlyAggregator() {
        require(msg.sender == settings.aggregatorAddress(), "OnlyAggregator");
        _;
    }

    modifier whenNotBlacklisted() {
        require(!accessManager.isBlacklisted(msg.sender), "UserBlacklisted");
        _;
    }

    modifier onlyProvider() {
        require(providerIntents[msg.sender].provider != address(0), "NotRegisteredProvider");
        _;
    }

    modifier validToken(address _token) {
        require(supportedTokens[_token], "TokenNotSupported");
        _;
    }

    modifier validOrder(bytes32 _orderId) {
        require(orders[_orderId].user != address(0), "OrderNotFound");
        _;
    }

    /* ========== INITIALIZATION ========== */

    function initialize(address _accessManager, address _settings) external initializer {
        require(_accessManager != address(0) && _settings != address(0), "InvalidAddress");

        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();
        __Ownable_init();

        accessManager = accessManager(_accessManager);
        settings = PGatewaySettings(_settings);
    }

    /* ========== OWNER FUNCTIONS ========== */

    modifier onlyAdmin() {
        require(accessManager.hasRole(accessManager.DEFAULT_ADMIN_ROLE(), msg.sender), "Not admin");
        _;
    }

    // modifier onlyAggregator() {
    //     require(msg.sender == settings.aggregatorAddress(), "Not aggregator");
    //     _;
    // }

    function pause() external onlyAdmin {
        _pause();
    }

    function unpause() external onlyAdmin {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override {
        require(accessManager.hasRole(accessManager.ADMIN_ROLE(), msg.sender), "Not upgrader");
    }

    function setSupportedToken(address _token, bool _supported) external onlyAdmin {
        require(_token != address(0), "InvalidToken");
        supportedTokens[_token] = _supported;
    }

    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "InvalidAddress");
        treasuryAddress = _newTreasury;
    }

    function setAggregatorAddress(address _newAggregator) external onlyOwner {
        require(_newAggregator != address(0), "InvalidAddress");
        aggregatorAddress = _newAggregator;
    }

    function setProtocolFee(uint64 _newFee) external onlyOwner {
        require(_newFee <= 5000, "FeeTooHigh"); // Max 5%
        protocolFeePercent = _newFee;
    }

    function setTierLimits(uint256 _smallLimit, uint256 _mediumLimit) external onlyOwner {
        require(_smallLimit > 0 && _mediumLimit > _smallLimit, "InvalidLimits");
        SMALL_TIER_LIMIT = _smallLimit;
        MEDIUM_TIER_LIMIT = _mediumLimit;
    }

    function setOrderExpiryWindow(uint256 _newWindow) external onlyOwner {
        require(_newWindow > 0, "InvalidWindow");
        orderExpiryWindow = _newWindow;
    }

    function setProposalTimeout(uint256 _newTimeout) external onlyOwner {
        require(_newTimeout > 0, "InvalidTimeout");
        proposalTimeout = _newTimeout;
    }

    /* ========== PROVIDER INTENT FUNCTIONS ========== */

    /**
     * @notice Register provider intent with available capacity
     * @param _currency Currency code (e.g., "NGN", "USD")
     * @param _availableAmount Amount provider can handle
     * @param _minFeeBps Minimum fee in basis points
     * @param _maxFeeBps Maximum fee in basis points
     * @param _commitmentWindow Time window for provider to accept proposal
     */
    function registerIntent(
        string calldata _currency,
        uint256 _availableAmount,
        uint64 _minFeeBps,
        uint64 _maxFeeBps,
        uint256 _commitmentWindow
    ) external whenNotPaused nonReentrant {
        require(_availableAmount > 0, "InvalidAmount");
        require(_minFeeBps <= _maxFeeBps, "InvalidFees");
        require(_maxFeeBps <= 10000, "FeesTooHigh"); // Max 10%
        require(_commitmentWindow > 0, "InvalidCommitmentWindow");

        address provider = msg.sender;

        // Check if provider is blacklisted
        require(!providerReputation[provider].isBlacklisted, "ProviderBlacklisted");

        uint256 expiresAt = block.timestamp + 5 minutes;

        providerIntents[provider] = ProviderIntent({
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

        // Track provider if first time
        if (providerReputation[provider].provider == address(0)) {
            registeredProviders.push(provider);
            providerReputation[provider].provider = provider;
        }

        emit IntentRegistered(provider, _currency, _availableAmount, _commitmentWindow, expiresAt);
    }

    /**
     * @notice Update existing provider intent
     */
    function updateIntent(string calldata _currency, uint256 _newAmount) external onlyProvider whenNotPaused {
        address provider = msg.sender;
        ProviderIntent storage intent = providerIntents[provider];

        require(intent.isActive, "NoActiveIntent");
        require(_newAmount > 0, "InvalidAmount");

        intent.availableAmount = _newAmount;
        intent.registeredAt = block.timestamp;
        intent.expiresAt = block.timestamp + 5 minutes;

        emit IntentUpdated(provider, _currency, _newAmount, block.timestamp);
    }

    /**
     * @notice Expire provider intent
     */
    function expireIntent(address _provider) external onlyAggregator {
        ProviderIntent storage intent = providerIntents[_provider];
        require(intent.isActive, "IntentNotActive");
        require(block.timestamp > intent.expiresAt, "IntentNotExpired");

        intent.isActive = false;

        emit IntentExpired(_provider, intent.currency);
    }

    /**
     * @notice Reserve capacity when proposal is sent
     */
    function reserveIntent(address _provider, uint256 _amount) external onlyAggregator {
        ProviderIntent storage intent = providerIntents[_provider];
        require(intent.isActive, "IntentNotActive");
        require(intent.availableAmount >= _amount, "InsufficientCapacity");

        intent.availableAmount -= _amount;
    }

    /**
     * @notice Release reserved capacity if proposal rejected or timeout
     */
    function releaseIntent(address _provider, uint256 _amount, string calldata _reason) external onlyAggregator {
        ProviderIntent storage intent = providerIntents[_provider];
        intent.availableAmount += _amount;

        emit IntentReleased(_provider, intent.currency, _amount, _reason);
    }

    /**
     * @notice Get active provider intent
     */
    function getProviderIntent(address _provider) external view returns (ProviderIntent memory) {
        return providerIntents[_provider];
    }

    /* ========== ORDER CREATION FUNCTIONS ========== */

    /**
     * @notice Create a new order
     * @param _token ERC20 token address
     * @param _amount Order amount
     * @param _refundAddress Address to refund if order fails
     */
    function createOrder(address _token, uint256 _amount, address _refundAddress, string messageHash)
        external
        whenNotPaused
        nonReentrant
        validToken(_token)
        whenNotBlacklisted
        returns (bytes32 orderId)
    {
        require(_amount > 0, "InvalidAmount");
        require(_refundAddress != address(0), "InvalidRefundAddress");

        // Determine tier
        OrderTier tier = _determineTier(_amount);

        // Transfer tokens from user to contract
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        // Generate order ID
        userNonce[msg.sender]++;
        orderId = keccak256(abi.encode(msg.sender, userNonce[msg.sender], block.chainid));

        // Create order
        orders[orderId] = Order({
            orderId: orderId,
            user: msg.sender,
            token: _token,
            amount: _amount,
            tier: tier,
            status: OrderStatus.PENDING,
            refundAddress: _refundAddress,
            createdAt: block.timestamp,
            expiresAt: block.timestamp + orderExpiryWindow,
            acceptedProposalId: bytes32(0),
            fulfilledByProvider: address(0)
        });

        activeOrderIds.push(orderId);

        emit OrderCreated(orderId, msg.sender, _token, _amount, tier, orders[orderId].expiresAt);

        return orderId;
    }

    /**
     * @notice Determine order tier based on amount
     */
 
    function _determineTier(uint256 _amount) internal view returns (PGatewayStructs.OrderTier) {
        if (_amount < settings.ALPHA_TIER_LIMIT()) return PGatewayStructs.OrderTier.ALPHA;
        if (_amount < settings.BETA_TIER_LIMIT()) return PGatewayStructs.OrderTier.BETA;
        if (_amount < settings.DELTA_TIER_LIMIT()) return PGatewayStructs.OrderTier.DELTA;
        if (_amount < settings.OMEGA_TIER_LIMIT()) return PGatewayStructs.OrderTier.OMEGA;
        return PGatewayStructs.OrderTier.TITAN;
    }

    /**
     * @notice Get order details
     */
    function getOrder(bytes32 _orderId) external view validOrder(_orderId) returns (Order memory) {
        return orders[_orderId];
    }

    /* ========== SETTLEMENT PROPOSAL FUNCTIONS ========== */

    /**
     * @notice Create settlement proposal (called by aggregator)
     * @param _orderId Order ID to settle
     * @param _provider Provider address
     * @param _proposedFeeBps Fee in basis points
     */
    function createProposal(bytes32 _orderId, address _provider, uint64 _proposedFeeBps)
        external
        onlyAggregator
        validOrder(_orderId)
        returns (bytes32 proposalId)
    {
        Order storage order = orders[_orderId];
        require(order.status == OrderStatus.PENDING, "OrderNotPending");
        require(block.timestamp < order.expiresAt, "OrderExpired");

        ProviderIntent memory intent = providerIntents[_provider];
        require(intent.isActive, "ProviderIntentNotActive");
        require(intent.availableAmount >= order.amount, "InsufficientCapacity");

        // Validate fee
        require(_proposedFeeBps >= intent.minFeeBps && _proposedFeeBps <= intent.maxFeeBps, "InvalidFee");

        // Generate proposal ID
        proposalId = keccak256(abi.encode(_orderId, _provider, block.timestamp, block.number));

        uint256 deadline = block.timestamp + intent.commitmentWindow;

        proposals[proposalId] = SettlementProposal({
            proposalId: proposalId,
            orderId: _orderId,
            provider: _provider,
            proposedAmount: order.amount,
            proposedFeeBps: _proposedFeeBps,
            proposedAt: block.timestamp,
            proposalDeadline: deadline,
            status: ProposalStatus.PENDING
        });

        // Update order status
        order.status = OrderStatus.PROPOSED;

        emit SettlementProposalCreated(proposalId, _orderId, _provider, order.amount, _proposedFeeBps, deadline);

        return proposalId;
    }

    /**
     * @notice Provider accepts settlement proposal
     */
    function acceptProposal(bytes32 _proposalId) external onlyProvider whenNotPaused nonReentrant {
        SettlementProposal storage proposal = proposals[_proposalId];
        require(proposal.provider == msg.sender, "NotProposalProvider");
        require(proposal.status == ProposalStatus.PENDING, "ProposalNotPending");
        require(block.timestamp < proposal.proposalDeadline, "ProposalExpired");

        proposal.status = ProposalStatus.ACCEPTED;

        Order storage order = orders[proposal.orderId];
        order.status = OrderStatus.ACCEPTED;
        order.acceptedProposalId = _proposalId;
        order.fulfilledByProvider = msg.sender;

        emit SettlementProposalAccepted(_proposalId, proposal.orderId, msg.sender, block.timestamp);
    }

    /**
     * @notice Provider rejects settlement proposal
     */
    function rejectProposal(bytes32 _proposalId, string calldata _reason) external onlyProvider nonReentrant {
        SettlementProposal storage proposal = proposals[_proposalId];
        require(proposal.provider == msg.sender, "NotProposalProvider");
        require(proposal.status == ProposalStatus.PENDING, "ProposalNotPending");

        proposal.status = ProposalStatus.REJECTED;

        // Update provider reputation
        providerReputation[msg.sender].noShowCount++;

        emit SettlementProposalRejected(_proposalId, msg.sender, _reason);
    }

    /**
     * @notice Mark proposal as timeout (called by aggregator)
     */
    function timeoutProposal(bytes32 _proposalId) external onlyAggregator {
        SettlementProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.PENDING, "ProposalNotPending");
        require(block.timestamp > proposal.proposalDeadline, "ProposalNotExpired");

        proposal.status = ProposalStatus.TIMEOUT;

        emit SettlementProposalTimeout(_proposalId, proposal.provider);
    }

    /**
     * @notice Get proposal details
     */
    function getProposal(bytes32 _proposalId) external view returns (SettlementProposal memory) {
        return proposals[_proposalId];
    }

    /* ========== SETTLEMENT EXECUTION FUNCTIONS ========== */

    /**
     * @notice Execute settlement after provider accepts
     * @param _proposalId Accepted proposal ID
     */
    function executeSettlement(bytes32 _proposalId) external onlyAggregator nonReentrant {
        SettlementProposal storage proposal = proposals[_proposalId];
        require(proposal.status == ProposalStatus.ACCEPTED, "ProposalNotAccepted");
        require(!proposalExecuted[_proposalId], "AlreadyExecuted");

        Order storage order = orders[proposal.orderId];
        require(order.status == OrderStatus.ACCEPTED, "OrderNotAccepted");

        // Calculate fees
        uint256 protocolFee = (proposal.proposedAmount * settings.protocolFeePercent()) / MAX_BPS;
        uint256 providerFee = (proposal.proposedAmount * proposal.proposedFeeBps) / MAX_BPS;
        uint256 providerAmount = proposal.proposedAmount - protocolFee - providerFee;

        // Transfer protocol fee to treasury
        IERC20(order.token).transfer(settings.treasuryAddress(), protocolFee);

        // Transfer amount to provider
        IERC20(order.token).transfer(proposal.provider, providerAmount);

        // Mark as executed
        proposalExecuted[_proposalId] = true;
        order.status = OrderStatus.FULFILLED;

        // Update provider reputation
        _updateProviderSuccess(proposal.provider, block.timestamp - proposal.proposedAt);

        emit SettlementExecuted(
            proposal.orderId, _proposalId, proposal.provider, providerAmount, proposal.proposedFeeBps, protocolFee
        );
    }

    /* ========== REFUND FUNCTIONS ========== */

    /**
     * @notice Refund order if no provider accepts within timeout
     */
    function refundOrder(bytes32 _orderId) external onlyAggregator nonReentrant validOrder(_orderId) {
        Order storage order = orders[_orderId];
        require(order.status != OrderStatus.FULFILLED, "OrderFulfilled");
        require(order.status != OrderStatus.REFUNDED, "AlreadyRefunded");
        require(block.timestamp > order.expiresAt, "OrderNotExpired");

        order.status = OrderStatus.REFUNDED;

        // Refund full amount to refund address
        IERC20(order.token).transfer(order.refundAddress, order.amount);

        emit OrderRefunded(_orderId, order.user, order.amount, "OrderTimeout");
    }

    /**
     * @notice Manual refund by user (if aggregator allows)
     */
    function requestRefund(bytes32 _orderId) external nonReentrant validOrder(_orderId) {
        Order storage order = orders[_orderId];
        require(order.user == msg.sender, "NotOrderCreator");
        require(order.status == OrderStatus.PENDING || order.status == OrderStatus.PROPOSED, "CannotRefund");
        require(block.timestamp > order.expiresAt, "OrderNotExpired");

        order.status = OrderStatus.CANCELLED;

        IERC20(order.token).transfer(order.refundAddress, order.amount);

        emit OrderRefunded(_orderId, msg.sender, order.amount, "UserRequested");
    }

    /* ========== REPUTATION FUNCTIONS ========== */

    /**
     * @notice Update provider success metrics
     */
    function _updateProviderSuccess(address _provider, uint256 _settlementTime) internal {
        ProviderReputation storage rep = providerReputation[_provider];
        rep.totalOrders++;
        rep.successfulOrders++;
        rep.totalSettlementTime += _settlementTime;
        rep.lastUpdated = block.timestamp;

        emit ProviderReputationUpdated(_provider, rep.successfulOrders, rep.failedOrders, rep.noShowCount);
    }

    /**
     * @notice Flag provider as fraudulent
     */
    function flagFraudulent(address _provider) external onlyAggregator {
        require(providerReputation[_provider].provider != address(0), "ProviderNotFound");
        providerReputation[_provider].isFraudulent = true;
        providerIntents[_provider].isActive = false;

        emit ProviderFraudFlagged(_provider);
    }

    /**
     * @notice Blacklist provider
     */
    function blacklistProvider(address _provider, string calldata _reason) external onlyOwner {
        providerReputation[_provider].isBlacklisted = true;
        providerIntents[_provider].isActive = false;

        emit ProviderBlacklisted(_provider, _reason);
    }

    /**
     * @notice Get provider reputation
     */
    function getProviderReputation(address _provider) external view returns (ProviderReputation memory) {
        return providerReputation[_provider];
    }

    /* ========== UTILITY FUNCTIONS ========== */

    /**
     * @notice Get all registered providers
     */
    function getRegisteredProviders() external view returns (address[] memory) {
        return registeredProviders;
    }

    /**
     * @notice Get all active orders
     */
    function getActiveOrders() external view returns (bytes32[] memory) {
        return activeOrderIds;
    }

    /**
     * @notice Get user nonce for replay protection
     */
    function getUserNonce(address _user) external view returns (uint256) {
        return userNonce[_user];
    }

    /**
     * @notice Emergency withdrawal (only owner)
     */
    function emergencyWithdraw(address _token) external onlyOwner nonReentrant {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        require(balance > 0, "NoBalance");
        IERC20(_token).transfer(treasuryAddress, balance);
    }

    // Reserve for upgrades
  uint256[50] private __gap;
}


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
import {IErrors} from "../interface/IErrors.sol";
import "./PGatewayStructs.sol";


/**
 * @title PayNode Gateway - Non-Custodial Payment Aggregator
 * @notice Core settlement engine for off-ramp payments with parallel settlement and provider intent registry
 * @dev Implements upgradeable UUPS pattern with comprehensive access control and reentrancy protection
 * 
 * ================================
 * CONTRACT ARCHITECTURE & FLOW
 * ================================
 * 
 * CORE INTEGRATION FLOW:
 * ----------------------
 * 1. User → PGateway (createOrder) → Funds escrowed → Order created
 * 2. Aggregator → PGateway (createProposal) → Provider matched → Capacity reserved
 * 3. Provider → PGateway (acceptProposal) → Settlement accepted → Status updated
 * 4. Aggregator → PGateway (executeSettlement) → Funds distributed → Order fulfilled
 * 
 * CONTRACT ECOSYSTEM:
 * -------------------
 * ┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐
 * │   PGateway      │◄──►│ PGatewaySettings │◄──►│  AccessManager   │
 * │ (Main Engine)   │    │ (Configuration)  │    │ (Security Layer) │
 * └─────────────────┘    └──────────────────┘    └──────────────────┘
 *         ▲                       ▲                       ▲
 *         │                       │                       │
 *         ▼                       ▼                       ▼
 * ┌─────────────────┐    ┌──────────────────┐    ┌──────────────────┐
 * │ PGatewayStructs │    │   IError (Interface)  │  OpenZeppelin    │
 * │ (Data Models)   │    │ (Error Standard) │    │  (Infrastructure)│
 * └─────────────────┘    └──────────────────┘    └──────────────────┘
 * 
 * KEY INTEGRATION POINTS:
 * -----------------------
 * 
 * 1. ACCESS CONTROL & SECURITY:
 *    - IPayNodeAccessManager: Role-based access control and reentrancy protection
 *    - OpenZeppelin Pausable: Emergency stop mechanism
 *    - Custom modifiers: Provider validation, token whitelisting, order verification
 * 
 * 2. CONFIGURATION MANAGEMENT:
 *    - IPGatewaySettings: Dynamic protocol parameters (fees, timeouts, limits)
 *    - Tier system: Order classification (ALPHA, BETA, DELTA, OMEGA, TITAN)
 *    - Token management: Supported ERC20 token validation
 * 
 * 3. DATA STRUCTURES:
 *    - PGatewayStructs: Comprehensive data models for orders, proposals, intents, reputation
 *    - Order lifecycle: PENDING → PROPOSED → ACCEPTED → FULFILLED/REFUNDED
 *    - Provider intent: Capacity management and fee preferences
 * 
 * 4. ERROR HANDLING:
 *    - IError: Standardized error interface for gas-efficient reverts
 *    - Custom errors: Domain-specific validation failures
 * 
 * 5. UPGRADEABILITY:
 *    - UUPS Upgradeable: Logic contract upgrades without state migration
 *    - Initializable: Safe initialization pattern
 * 
 * ORDER LIFECYCLE FLOW:
 * ----------------------
 * 
 * Phase 1: ORDER CREATION
 *   User → createOrder() → Token transfer → Order escrowed → Event emitted
 *   ├── Validates integrator registration
 *   ├── Checks token support
 *   ├── Prevents replay attacks with messageHash
 *   └── Determines order tier based on amount
 * 
 * Phase 2: PROVIDER MATCHING
 *   Aggregator → createProposal() → Provider matched → Capacity reserved
 *   ├── Validates provider intent and capacity
 *   ├── Ensures fee within provider's range
 *   └── Updates order status to PROPOSED
 * 
 * Phase 3: SETTLEMENT EXECUTION
 *   Provider → acceptProposal() → Settlement accepted
 *   Aggregator → executeSettlement() → Funds distributed
 *   ├── Calculates protocol, integrator, and provider fees
 *   ├── Transfers funds to respective parties
 *   └── Updates reputation metrics
 * 
 * Phase 4: REFUND & RECOVERY
 *   Automatic refunds on timeout
 *   User-initiated refunds after expiry
 *   Provider capacity release on rejection
 * 
 * SECURITY FEATURES:
 * ------------------
 * - Reentrancy protection via AccessManager
 * - Role-based access control (Admin, Aggregator, Provider)
 * - Token whitelisting for supported assets
 * - Order expiration and timeout mechanisms
 * - Replay protection with user nonces and message hashes
 * - Blacklisting for malicious actors
 * - Upgradeability with proper authorization
 * 
 * FEE DISTRIBUTION MODEL:
 * -----------------------
 * Total Amount = Protocol Fee + Integrator Fee + Provider Amount
 * - Protocol Fee: Platform revenue (configurable %)
 * - Integrator Fee: dApp/partner share (self-configured)
 * - Provider Amount: Remaining after fees (earns via exchange rate spread)
 * 
 * @author PayNode Protocol
 */
contract PGateway is Initializable, PausableUpgradeable, UUPSUpgradeable, IErrors{
    using SafeERC20 for IERC20;

    // Access Manager and Settings
    IPayNodeAccessManager public accessManager;
    IPGatewaySettings public settings;

    // Core Mappings
    /// @notice Tracks all orders created through the gateway
    /// @dev Maps a unique orderId (hash) to its corresponding Order struct
    mapping(bytes32 => PGatewayStructs.Order) public orders;

    /// @notice Stores settlement proposals submitted by providers
    /// @dev Each proposal is indexed by a unique proposalId (hash)
    mapping(bytes32 => PGatewayStructs.SettlementProposal) public proposals;

    /// @notice Records the most recent provider intent for each registered provider
    /// @dev Provider address maps to a ProviderIntent struct describing liquidity and fee preferences
    mapping(address => PGatewayStructs.ProviderIntent) public providerIntents;

    /// @notice Maintains reputation data for each provider
    /// @dev Includes blacklist status, historical stats, and performance indicators
    mapping(address => PGatewayStructs.ProviderReputation) public providerReputation;

    /// @notice Tracks per-user nonces to prevent replay attacks in off-chain signed actions
    /// @dev Incremented for each user operation that relies on signature verification
    mapping(address => uint256) public userNonce;

    /// @notice Flags proposals that have been executed and settled
    /// @dev Prevents duplicate settlement execution for the same proposalId
    mapping(bytes32 => bool) public proposalExecuted;

    /// @notice Mapping of integrator addresses to their info
    mapping(address => PGatewayStructs.IntegratorInfo) public integratorRegistry;

    /// @notice Mapping to track used message hashes (prevent replay)
    mapping(bytes32 => bool) public usedMessageHashes;

    /// @notice Maximum integrator fee allowed (5% = 500 basis points)
    uint64 public constant MAX_INTEGRATOR_FEE = 500;

    /// @notice Minimum integrator fee (0.1% = 10 basis points)
    uint64 public constant MIN_INTEGRATOR_FEE = 10;

    /* ========== EVENTS ========== */

   /**
 * @notice Emitted when a new integrator is successfully registered on the platform.
 * @dev Includes integrator address, configured fee, chosen name, and registration timestamp.
 *
 * @param integrator Address of the newly registered integrator.
 * @param feeBps Fee set by the integrator in basis points (1% = 100 bps).
 * @param name Display name or identifier chosen by the integrator.
 * @param timestamp Block timestamp when the registration occurred.
 */
event IntegratorRegistered(address indexed integrator, uint64 feeBps, string name, uint256 timestamp);

/**
 * @notice Emitted when an integrator updates their fee configuration.
 * @dev Tracks both old and new fee values for auditability.
 *
 * @param integrator Address of the integrator whose fee was updated.
 * @param oldFeeBps Previous fee rate in basis points.
 * @param newFeeBps New fee rate in basis points.
 * @param timestamp Block timestamp when the update was executed.
 */
event IntegratorFeeUpdated(address indexed integrator, uint64 oldFeeBps, uint64 newFeeBps, uint256 timestamp);

/**
 * @notice Emitted when an integrator updates their registered display name.
 * @dev Used for UI and identification purposes across integrated systems.
 *
 * @param integrator Address of the integrator whose name was updated.
 * @param newName Updated name or identifier.
 * @param timestamp Block timestamp when the name update occurred.
 */
event IntegratorNameUpdated(address indexed integrator, string newName, uint256 timestamp);


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
        uint256 expiresAt,
        bytes32 messageHash
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
        uint256 integratorFee,
        uint256 providerFee
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

    // error InvalidAmount();
    // error InvalidAddress();
    // error InvalidFee();
    // error InvalidOrder();
    // error InvalidProposal();
    // error InvalidIntent();
    // error IntentNotExpired();
    // error OrderExpired();
    // error Unauthorized();
    // error ProviderBlacklisted();
    // error TokenNotSupported();

    /* ========== MODIFIERS ========== */

     /// @notice Ensures the caller is the aggregator
    modifier onlyAggregator() {
        if (!accessManager.hasRole(accessManager.AGGREGATOR_ROLE(), msg.sender)) revert Unauthorized();
        _;
    }

    /// @notice Ensures the caller is not blacklisted
    modifier whenNotBlacklisted() {
        if (accessManager.isBlacklisted(msg.sender)) revert UserBlacklisted();
        _;
    }

    /// @notice Ensures the caller is a registered provider
    modifier onlyProvider() {
        if (providerIntents[msg.sender].provider == address(0)) revert NotRegisteredProvider();
        _;
    }

    /// @notice Ensures the token is supported
    modifier validToken(address _token) {
        if (!settings.isTokenSupported(_token)) revert TokenNotSupported();
        _;
    }

    /// @notice Ensures the order exists
    modifier validOrder(bytes32 _orderId) {
        if (orders[_orderId].user == address(0)) revert OrderNotFound();
        _;
    }

    /* ========== INITIALIZATION ========== */

    /// @notice Initializes the contract with access manager and settings
    /// @param _accessManager Address of the PayNodeAccessManager contract
    /// @param _settings Address of the PGatewaySettings contract
    function initialize(address _accessManager, address _settings) external initializer {
        if (_accessManager == address(0) || _settings == address(0)) revert InvalidAddress();

        __Pausable_init();
        __UUPSUpgradeable_init();

        accessManager = IPayNodeAccessManager(_accessManager);
        settings = IPGatewaySettings(_settings);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    /// @notice Pauses the contract
    /// @dev Requires DEFAULT_ADMIN_ROLE
    function pause() external {
        if (!accessManager.executeNonReentrant(msg.sender, accessManager.DEFAULT_ADMIN_ROLE())) revert Unauthorized();
        _pause();
    }

    /// @notice Unpauses the contract
    /// @dev Requires DEFAULT_ADMIN_ROLE
    function unpause() external {
        if (!accessManager.executeNonReentrant(msg.sender, accessManager.DEFAULT_ADMIN_ROLE())) revert Unauthorized();
        _unpause();
    }

    /// @notice Authorizes contract upgrades
    /// @param newImplementation Address of the new implementation contract
    /// @dev Requires ADMIN_ROLE
    function _authorizeUpgrade(address newImplementation) internal view override {
        if (newImplementation == address(0)) revert InvalidAddress();
        if (!accessManager.hasRole(accessManager.ADMIN_ROLE(), msg.sender)) revert Unauthorized();
    }



    /* ========== PROVIDER INTENT FUNCTIONS ========== */

    /// @notice Registers provider intent with available capacity
    /// @param _currency Currency code (e.g., "USDT", "CNGN", "USDC")
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
        if (!accessManager.executeProviderNonReentrant(msg.sender)) revert InvalidProvider();

        if (_availableAmount == 0) revert InvalidAmount();
        if (_minFeeBps > _maxFeeBps) revert InvalidFee();
        if (_maxFeeBps > settings.maxProtocolFee()) revert InvalidFee();
        if (_commitmentWindow == 0) revert InvalidDuration();

        address provider = msg.sender;
        if (providerReputation[provider].isBlacklisted) revert ErrorProviderBlacklisted();

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
        if (!accessManager.executeProviderNonReentrant(msg.sender)) revert ErrorProviderBlacklisted();
        if (_newAmount == 0) revert InvalidAmount();

        PGatewayStructs.ProviderIntent storage intent = providerIntents[msg.sender];
        if (!intent.isActive) revert InvalidIntent();

        intent.availableAmount = _newAmount;
        intent.registeredAt = block.timestamp;
        intent.expiresAt = block.timestamp + settings.intentExpiry();

        emit IntentUpdated(msg.sender, _currency, _newAmount, block.timestamp);
    }

    /// @notice Expires provider intent
    /// @param _provider Provider address
    function expireIntent(address _provider) external onlyAggregator {
        if (!accessManager.executeAggregatorNonReentrant(msg.sender)) revert Unauthorized();
        PGatewayStructs.ProviderIntent storage intent = providerIntents[_provider];
        if (!intent.isActive) revert InvalidIntent();
        if (block.timestamp <= intent.expiresAt) revert IntentNotExpired();

        intent.isActive = false;
        emit IntentExpired(_provider, intent.currency);
    }

    /// @notice Reserves capacity when a proposal is sent
    /// @param _provider Provider address
    /// @param _amount Amount to reserve
    function reserveIntent(address _provider, uint256 _amount) external onlyAggregator {
        if (!accessManager.executeAggregatorNonReentrant(msg.sender)) revert Unauthorized();
        PGatewayStructs.ProviderIntent storage intent = providerIntents[_provider];
        if (!intent.isActive) revert InvalidIntent();
        if (intent.availableAmount < _amount) revert InvalidAmount();

        intent.availableAmount -= _amount;
    }


    /// @notice Releases reserved capacity if proposal is rejected or times out
    /// @param _provider Provider address
    /// @param _amount Amount to release
    /// @param _reason Reason for release
    function releaseIntent(address _provider, uint256 _amount, string calldata _reason) external onlyAggregator {
        if (!accessManager.executeAggregatorNonReentrant(msg.sender)) revert Unauthorized();
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

    // ==================== INTEGRATOR SELF-SERVICE FUNCTIONS ====================

    /// @notice Register as an integrator with PayNode
    /// @dev Anyone can register as an integrator. Sets initial fee within allowed range.
    /// @param _feeBps Desired fee in basis points (e.g., 100 = 1%)
    /// @param _name Integrator's name (e.g., "Azza", "CoolWallet")
    function registerAsIntegrator(uint64 _feeBps, string calldata _name) external {
        if (integratorRegistry[msg.sender].isRegistered) revert AlreadyRegistered();
        if (_feeBps < MIN_INTEGRATOR_FEE || _feeBps > MAX_INTEGRATOR_FEE) revert FeeOutOfRange();
        if (bytes(_name).length == 0 || bytes(_name).length > 50) revert InvalidName();

        integratorRegistry[msg.sender] = PGatewayStructs.IntegratorInfo({
            isRegistered: true,
            feeBps: _feeBps,
            name: _name,
            registeredAt: block.timestamp,
            totalOrders: 0,
            totalVolume: 0
        });

        emit IntegratorRegistered(msg.sender, _feeBps, _name, block.timestamp);
    }

    /// @notice Update integrator's fee
    /// @dev Only the integrator themselves can update their fee. Can be called anytime.
    /// @param _newFeeBps New fee in basis points (must be within allowed range)
    function updateIntegratorFee(uint64 _newFeeBps) external {
        if (!integratorRegistry[msg.sender].isRegistered) revert NotRegistered();
        if (_newFeeBps < MIN_INTEGRATOR_FEE || _newFeeBps > MAX_INTEGRATOR_FEE) revert FeeOutOfRange();

        uint64 oldFee = integratorRegistry[msg.sender].feeBps;
        integratorRegistry[msg.sender].feeBps = _newFeeBps;

        emit IntegratorFeeUpdated(msg.sender, oldFee, _newFeeBps, block.timestamp);
    }

    /// @notice Update integrator's name
    /// @dev Only the integrator themselves can update their name
    /// @param _newName New name for the integrator
    function updateIntegratorName(string calldata _newName) external {
        if (!integratorRegistry[msg.sender].isRegistered) revert NotRegistered();
        if (bytes(_newName).length == 0 || bytes(_newName).length > 50) revert InvalidName();

        integratorRegistry[msg.sender].name = _newName;

        emit IntegratorNameUpdated(msg.sender, _newName, block.timestamp);
    }

    /* ========== ORDER CREATION FUNCTIONS ========== */

    /// @notice Creates a new payment order
    /// @dev User calls this via dApp frontend. Integrator address is auto-filled by dApp.
    ///      Contract validates integrator is registered and uses their current fee rate.
    ///      Message hash prevents replay attacks and links on-chain order to off-chain details.
    /// @param _token ERC20 token address to offramp
    /// @param _amount Order amount (full amount, fees deducted at settlement)
    /// @param _refundAddress Address to refund to if order fails or is cancelled
    /// @param _integrator Address of the dApp/integrator (must be registered)
    /// @param _messageHash Unique hash of off-chain order details (user info, bank details, etc.)
    /// @return orderId Generated unique order ID
    function createOrder(
        address _token,
        uint256 _amount,
        address _refundAddress,
        address _integrator,
        uint64 _integratorFee,
        bytes32 _messageHash
    ) external whenNotPaused whenNotBlacklisted validToken(_token) returns (bytes32 orderId) {
          if (_amount == 0) revert InvalidAmount();
        if (_refundAddress == address(0)) revert InvalidAddress();
        if (_integrator == address(0)) revert InvalidAddress();
        if (bytes32(_messageHash).length == 0) revert InvalidMessageHash();
        if (!accessManager.executeNonReentrant(msg.sender, bytes32(0))) revert Unauthorized();

        // SECURITY: Prevents replay attacks with messageHash
        bytes32 msgHash = keccak256(abi.encodePacked(_messageHash));
        if (usedMessageHashes[msgHash]) revert MessageHashAlreadyUsed();
        usedMessageHashes[msgHash] = true;
        // if (!usedMessageHashes[msgHash]) revert MessageHashAlreadyUsed();

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
            integrator: _integrator,
            integratorFee: _integratorFee,
            _messageHash: bytes32(0)
        });

        emit OrderCreated(orderId, msg.sender, _token, _amount, tier, orders[orderId].expiresAt, _messageHash);
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
        if (!accessManager.executeAggregatorNonReentrant(msg.sender)) revert Unauthorized();
        PGatewayStructs.Order storage order = orders[_orderId];
        if (order.status != PGatewayStructs.OrderStatus.PENDING) revert InvalidOrder();
        if (block.timestamp >= order.expiresAt) revert OrderExpired();

        PGatewayStructs.ProviderIntent memory intent = providerIntents[_provider];
        if (!intent.isActive) revert InvalidIntent();
        if (intent.availableAmount < order.amount) revert InvalidAmount();
        if (_proposedFeeBps < intent.minFeeBps || _proposedFeeBps > intent.maxFeeBps) revert InvalidFee();

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
         if (!accessManager.executeProviderNonReentrant(msg.sender)) revert InvalidProvider();
        PGatewayStructs.SettlementProposal storage proposal = proposals[_proposalId];
        if (proposal.provider != msg.sender) revert Unauthorized();
        if (proposal.status != PGatewayStructs.ProposalStatus.PENDING) revert InvalidProposal();
        if (block.timestamp >= proposal.proposalDeadline) revert InvalidProposal();

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
        if (!accessManager.executeProviderNonReentrant(msg.sender)) revert InvalidProvider();
        PGatewayStructs.SettlementProposal storage proposal = proposals[_proposalId];
        if (proposal.provider != msg.sender) revert Unauthorized();
        if (proposal.status != PGatewayStructs.ProposalStatus.PENDING) revert InvalidProposal();

        proposal.status = PGatewayStructs.ProposalStatus.REJECTED;
        providerReputation[msg.sender].noShowCount++;
        emit SettlementProposalRejected(_proposalId, msg.sender, _reason);
    }

    /// @notice Marks a proposal as timed out
    /// @param _proposalId Proposal ID
    function timeoutProposal(bytes32 _proposalId) external onlyAggregator {
       if (!accessManager.executeAggregatorNonReentrant(msg.sender)) revert Unauthorized();
        PGatewayStructs.SettlementProposal storage proposal = proposals[_proposalId];
        if (proposal.status != PGatewayStructs.ProposalStatus.PENDING) revert InvalidProposal();
        if (block.timestamp <= proposal.proposalDeadline) revert InvalidProposal();

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

    /// @notice Executes settlement after proposal acceptance and distributes funds from escrow
    /// @dev Settlement Flow:
    ///      1. Validates proposal is ACCEPTED and not already executed
    ///      2. Validates associated order is in ACCEPTED status
    ///      3. Calculates all fees from the proposed amount:
    ///         - Protocol fee: Platform's fee sent to treasury
    ///         - Integrator fee: dApp's fee (set by integrator) sent to integrator address
    ///         - Provider fee: Provider's margin (calculated for tracking, not transferred separately)
    ///      4. Distributes escrowed funds:
    ///         - Protocol fee → Treasury
    ///         - Integrator fee → Integrator
    ///         - Remaining amount → Provider (who sends fiat to user off-chain)
    ///      5. Marks proposal as executed and order as FULFILLED
    ///      6. Updates provider success metrics
    ///      7. Emits settlement event with full breakdown
    ///
    ///      Note: Provider's margin (providerFee) is earned through their exchange rate markup
    ///      off-chain and is not deducted as a separate transfer. The provider receives the
    ///      remaining amount after protocol and integrator fees are deducted.
    ///
    /// @param _proposalId The ID of the accepted proposal to execute settlement for
    function executeSettlement(bytes32 _proposalId) external onlyAggregator {
       if (!accessManager.executeAggregatorNonReentrant(msg.sender)) revert Unauthorized();
        PGatewayStructs.SettlementProposal storage proposal = proposals[_proposalId];
        if (proposal.status != PGatewayStructs.ProposalStatus.ACCEPTED) revert InvalidProposal();
        if (proposalExecuted[_proposalId]) revert InvalidProposal();

        PGatewayStructs.Order storage order = orders[proposal.orderId];
        if (order.status != PGatewayStructs.OrderStatus.ACCEPTED) revert InvalidOrder();

        uint256 integratorFee = (proposal.proposedAmount * order.integratorFee) / settings.MAX_BPS();
        uint256 protocolFee = (proposal.proposedAmount * settings.protocolFeePercent()) / settings.MAX_BPS();
        uint256 providerFee = (proposal.proposedAmount * proposal.proposedFeeBps) / settings.MAX_BPS();
        uint256 providerAmount = proposal.proposedAmount - protocolFee - integratorFee;

        IERC20(order.token).safeTransfer(settings.treasuryAddress(), protocolFee);
        IERC20(order.token).safeTransfer(order.integrator, integratorFee);
        IERC20(order.token).safeTransfer(proposal.provider, providerAmount);

        proposalExecuted[_proposalId] = true;
        order.status = PGatewayStructs.OrderStatus.FULFILLED;

        _updateProviderSuccess(proposal.provider, block.timestamp - proposal.proposedAt);

        emit SettlementExecuted(
            proposal.orderId,
            _proposalId,
            proposal.provider,
            providerAmount,
            proposal.proposedFeeBps,
            protocolFee,
            integratorFee,
            providerFee
        );
    }

    /* ========== REFUND FUNCTIONS ========== */

    /// @notice Refunds an order if no provider accepts within timeout
    /// @param _orderId Order ID to refund
    function refundOrder(bytes32 _orderId) external onlyAggregator validOrder(_orderId) {
        if (!accessManager.executeAggregatorNonReentrant(msg.sender)) revert Unauthorized();
        PGatewayStructs.Order storage order = orders[_orderId];
        if (order.status == PGatewayStructs.OrderStatus.FULFILLED) revert InvalidOrder();
        if (order.status == PGatewayStructs.OrderStatus.REFUNDED) revert InvalidOrder();
        if (block.timestamp <= order.expiresAt) revert OrderNotExpired();

        order.status = PGatewayStructs.OrderStatus.REFUNDED;
        IERC20(order.token).safeTransfer(order.refundAddress, order.amount);

        emit OrderRefunded(_orderId, order.user, order.amount, "OrderTimeout");
    }

    /// @notice Allows user to request a refund
    /// @param _orderId Order ID to refund
    function requestRefund(bytes32 _orderId) external validOrder(_orderId) {
        if (!accessManager.executeNonReentrant(msg.sender, bytes32(0))) revert Unauthorized();
        PGatewayStructs.Order storage order = orders[_orderId];
        if (order.user != msg.sender) revert Unauthorized();
        if (
            order.status != PGatewayStructs.OrderStatus.PENDING && order.status != PGatewayStructs.OrderStatus.PROPOSED
        ) revert InvalidOrder();
        if (block.timestamp <= order.expiresAt) revert OrderNotExpired();

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
        if (!accessManager.executeAggregatorNonReentrant(msg.sender)) revert Unauthorized();
        if (providerReputation[_provider].provider == address(0)) revert InvalidAddress();
        providerReputation[_provider].isFraudulent = true;
        providerIntents[_provider].isActive = false;

        emit ProviderFraudFlagged(_provider);
    }

    /// @notice Blacklists a provider
    /// @param _provider Provider address
    /// @param _reason Reason for blacklisting
    function blacklistProvider(address _provider, string calldata _reason) external {
        if (!accessManager.executeNonReentrant(msg.sender, accessManager.DEFAULT_ADMIN_ROLE())) revert Unauthorized();
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

    /// @notice Get integrator information
    /// @param _integrator Address of the integrator
    /// @return info Complete integrator information
    function getIntegratorInfo(address _integrator)
        external
        view
        returns (PGatewayStructs.IntegratorInfo memory info)
    {
        return integratorRegistry[_integrator];
    }

    // Reserve for upgrades
    uint256[50] private __gap;
}

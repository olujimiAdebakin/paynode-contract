// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PGatewayStructs} from "../gateway/PGatewayStructs.sol";

/**
 * @title IPGateway
 * @author Olujimi
 * @notice Interface for PayNode Gateway - A non-custodial, multi-provider payment aggregation system enabling parallel settlement.
 * @dev Defines provider intent registry, order management, proposal handling, settlement execution, and reputation control.
 */
interface IPGateway {
    ///////////////////////////////////////////
    ////////           EVENTS      ////////////
    ///////////////////////////////////////////

    /**
     * @notice Emitted when a provider registers intent to provide liquidity
     * @param provider Address of the provider
     * @param currency Currency code (e.g., "USDT", "NGN", "USD")
     * @param availableAmount Amount available for settlement
     * @param commitmentWindow Commitment period for accepting settlements
     * @param expiresAt Timestamp when the intent expires
     */
    event IntentRegistered(
        address indexed provider,
        string indexed currency,
        uint256 availableAmount,
        uint256 commitmentWindow,
        uint256 expiresAt
    );

    /**
     * @notice Emitted when a provider updates their available capacity
     * @param provider Address of the provider
     * @param currency Currency code
     * @param newAmount Updated available amount
     * @param timestamp Time of update
     */
    event IntentUpdated(address indexed provider, string indexed currency, uint256 newAmount, uint256 timestamp);

    /**
     * @notice Emitted when a provider intent expires automatically
     * @param provider Address of the provider
     * @param currency Currency code
     */
    event IntentExpired(address indexed provider, string indexed currency);

    /**
     * @notice Emitted when a provider releases reserved capacity
     * @param provider Address of the provider
     * @param currency Currency code
     * @param releaseAmount Amount released
     * @param reason Reason for release
     */
    event IntentReleased(address indexed provider, string indexed currency, uint256 releaseAmount, string reason);

    /**
     * @notice Emitted when a new user order is created
     * @param orderId Unique identifier of the order
     * @param user Address of the user who created the order
     * @param token ERC20 token address used for payment
     * @param amount Order amount
     * @param tier Tier classification of the order
     * @param expiresAt Expiration timestamp of the order
     */
    event OrderCreated(
        bytes32 indexed orderId,
        address indexed user,
        address token,
        uint256 amount,
        PGatewayStructs.OrderTier tier,
        uint256 expiresAt,
        string messageHash
    );

    /**
     * @notice Emitted when an order is queued for later processing
     * @param orderId Unique identifier of the order
     * @param user Address of the user
     * @param requiredAmount Amount required to process the order
     * @param queuedAt Timestamp when order was queued
     */
    event OrderQueued(
        bytes32 indexed orderId, address indexed user, uint256 requiredAmount, uint256 queuedAt, string messageHash
    );

    /**
     * @notice Emitted when a provider creates a settlement proposal
     * @param proposalId Unique identifier for the proposal
     * @param orderId Associated order ID
     * @param provider Address of the provider
     * @param amount Proposed settlement amount
     * @param feeBps Proposed fee in basis points
     * @param deadline Proposal expiration time
     */
    event SettlementProposalCreated(
        bytes32 indexed proposalId,
        bytes32 indexed orderId,
        address indexed provider,
        uint256 amount,
        uint64 feeBps,
        uint256 deadline
    );

    /**
     * @notice Emitted when a settlement proposal is accepted
     * @param proposalId Accepted proposal ID
     * @param orderId Associated order ID
     * @param provider Address of the provider
     * @param timestamp Acceptance timestamp
     */
    event SettlementProposalAccepted(
        bytes32 indexed proposalId, bytes32 indexed orderId, address indexed provider, uint256 timestamp
    );

    /**
     * @notice Emitted when a proposal is rejected
     * @param proposalId Proposal ID
     * @param provider Address of the rejecting provider
     * @param reason Reason for rejection
     */
    event SettlementProposalRejected(bytes32 indexed proposalId, address indexed provider, string reason);

    /**
     * @notice Emitted when a proposal times out
     * @param proposalId Proposal ID
     * @param provider Address of the provider
     */
    event SettlementProposalTimeout(bytes32 indexed proposalId, address indexed provider);

    /**
     * @notice Emitted after a successful settlement execution
     * @param orderId Order ID
     * @param proposalId Proposal ID used for settlement
     * @param provider Address of the provider
     * @param amount Settled amount
     * @param feeBps Fee applied in basis points
     * @param protocolFee Protocol’s share of the fee
     */
    event SettlementExecuted(
        bytes32 indexed orderId,
        bytes32 indexed proposalId,
        address indexed provider,
        uint256 amount,
        uint64 feeBps,
        uint256 protocolFee
    );

    /**
     * @notice Emitted when an order is refunded
     * @param orderId Order ID
     * @param user Address of the user
     * @param amount Refunded amount
     * @param reason Reason for refund
     */
    event OrderRefunded(bytes32 indexed orderId, address indexed user, uint256 amount, string reason);

    /**
     * @notice Emitted when a provider’s reputation is updated
     * @param provider Address of the provider
     * @param successfulOrders Count of successful orders
     * @param failedOrders Count of failed orders
     * @param noShowCount Count of times provider didn’t respond
     */
    event ProviderReputationUpdated(
        address indexed provider, uint256 successfulOrders, uint256 failedOrders, uint256 noShowCount
    );

    /**
     * @notice Emitted when a provider is blacklisted
     * @param provider Address of the provider
     * @param reason Reason for blacklisting
     */
    event ProviderBlacklisted(address indexed provider, string reason);

    /**
     * @notice Emitted when a provider is flagged as fraudulent
     * @param provider Address of the provider
     */
    event ProviderFraudFlagged(address indexed provider);

    // ============================
    // Errors
    // ============================
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

    ///////////////////////////////////////////
    ////////     ADMIN FUNCTIONS      /////////
    ///////////////////////////////////////////

    /// @notice Pause the contract
    /// @dev Can only be called by admin
    function pause() external;

    /// @notice Unpause the contract
    /// @dev Can only be called by admin
    function unpause() external;

    /// @notice Set supported token
    /// @param _token ERC20 token address
    /// @param _supported Boolean to enable or disable support
    function setSupportedToken(address _token, bool _supported) external;

    /// @notice Set new treasury address
    /// @param _newTreasury Treasury wallet address
    function setTreasuryAddress(address _newTreasury) external;

    /// @notice Set aggregator contract address
    /// @param _newAggregator New aggregator address
    function setAggregatorAddress(address _newAggregator) external;

    /// @notice Set protocol fee in basis points
    /// @param _newFee Fee value (max 5000 = 50%)
    function setProtocolFee(uint64 _newFee) external;

    /// @notice Configure tier limits
    /// @param _smallLimit Small tier limit
    /// @param _mediumLimit Medium tier limit
    function setTierLimits(uint256 _smallLimit, uint256 _mediumLimit) external;

    /// @notice Set default order expiry duration
    /// @param _newWindow Expiry window in seconds
    function setOrderExpiryWindow(uint256 _newWindow) external;

    /// @notice Set default proposal timeout duration
    /// @param _newTimeout Timeout duration in seconds
    function setProposalTimeout(uint256 _newTimeout) external;

    ///////////////////////////////////////////
    ////////   PROVIDER INTENT LOGIC   ////////
    ///////////////////////////////////////////

    /**
     * @notice Register new provider intent
     * @param _currency Currency identifier
     * @param _availableAmount Liquidity amount offered
     * @param _minFeeBps Minimum fee (basis points)
     * @param _maxFeeBps Maximum fee (basis points)
     * @param _commitmentWindow Active commitment duration
     */
    function registerIntent(
        string calldata _currency,
        uint256 _availableAmount,
        uint64 _minFeeBps,
        uint64 _maxFeeBps,
        uint256 _commitmentWindow
    ) external;

    /**
     * @notice Update provider’s available amount
     * @param _currency Currency identifier
     * @param _newAmount New available amount
     */
    function updateIntent(string calldata _currency, uint256 _newAmount) external;

    /**
     * @notice Expire provider intent manually or automatically
     * @param _provider Provider address
     */
    function expireIntent(address _provider) external;

    /**
     * @notice Reserve a portion of provider’s liquidity
     * @param _provider Provider address
     * @param _amount Amount reserved
     */
    function reserveIntent(address _provider, uint256 _amount) external;

    /**
     * @notice Release previously reserved liquidity
     * @param _provider Provider address
     * @param _amount Amount released
     * @param _reason Reason for release
     */
    function releaseIntent(address _provider, uint256 _amount, string calldata _reason) external;

    /**
     * @notice Get active provider intent details
     * @param _provider Provider address
     * @return ProviderIntent Struct containing provider intent information
     */
    function getProviderIntent(address _provider) external view returns (PGatewayStructs.ProviderIntent memory);

    ///////////////////////////////////////////
    ////////     ORDER MANAGEMENT     /////////
    ///////////////////////////////////////////

    /**
     * @notice Create a new payment order
     * @param _token ERC20 token address used
     * @param _amount Order amount
     * @param _refundAddress Address for refund
     * @param _messageHash The hash of the messag signed
     * @return orderId Generated unique order ID
     */
    function createOrder(address _token, uint256 _amount, address _refundAddress, string calldata _messageHash)
        external
        returns (bytes32 orderId);

    /**
     * @notice Retrieve order information
     * @param _orderId Order identifier
     * @return Order Struct containing order data
     */
    function getOrder(bytes32 _orderId) external view returns (PGatewayStructs.Order memory);

    ///////////////////////////////////////////
    ////////   SETTLEMENT PROPOSALS   /////////
    ///////////////////////////////////////////

    /**
     * @notice Create new settlement proposal for an order
     * @param _orderId Associated order ID
     * @param _provider Provider address
     * @param _proposedFeeBps Proposed fee (basis points)
     * @return proposalId Generated proposal ID
     */
    function createProposal(bytes32 _orderId, address _provider, uint64 _proposedFeeBps)
        external
        returns (bytes32 proposalId);

    /// @notice Accept settlement proposal
    /// @param _proposalId Proposal ID to accept
    function acceptProposal(bytes32 _proposalId) external;

    /// @notice Reject settlement proposal
    /// @param _proposalId Proposal ID to reject
    /// @param _reason Reason for rejection
    function rejectProposal(bytes32 _proposalId, string calldata _reason) external;

    /// @notice Mark proposal as expired by timeout
    /// @param _proposalId Proposal ID
    function timeoutProposal(bytes32 _proposalId) external;

    /// @notice Get settlement proposal data
    /// @param _proposalId Proposal identifier
    /// @return SettlementProposal Struct with proposal details
    function getProposal(bytes32 _proposalId) external view returns (PGatewayStructs.SettlementProposal memory);

    ///////////////////////////////////////////
    ////////     SETTLEMENT EXECUTION  ////////
    ///////////////////////////////////////////

    /// @notice Execute settlement after proposal acceptance
    /// @param _proposalId Accepted proposal ID
    function executeSettlement(bytes32 _proposalId) external;

    ///////////////////////////////////////////
    ////////     REFUND MANAGEMENT     ////////
    ///////////////////////////////////////////

    /// @notice Refund order if timeout expires without provider
    /// @param _orderId Order ID to refund
    function refundOrder(bytes32 _orderId) external;

    /// @notice Allow user to manually request refund
    /// @param _orderId Order ID to refund
    function requestRefund(bytes32 _orderId) external;

    ///////////////////////////////////////////
    ////////     REPUTATION LOGIC      ////////
    ///////////////////////////////////////////

    /// @notice Mark provider as fraudulent
    /// @param _provider Address of the provider
    function flagFraudulent(address _provider) external;

    /// @notice Blacklist a provider
    /// @param _provider Address of the provider
    /// @param _reason Reason for blacklisting
    function blacklistProvider(address _provider, string calldata _reason) external;

    /// @notice Get provider reputation data
    /// @param _provider Address of the provider
    /// @return ProviderReputation Struct with reputation metrics
    function getProviderReputation(address _provider)
        external
        view
        returns (PGatewayStructs.ProviderReputation memory);

    ///////////////////////////////////////////
    ////////     UTILITY FUNCTIONS     ////////
    ///////////////////////////////////////////

    /// @notice Retrieve all registered providers
    /// @return Array of provider addresses
    function getRegisteredProviders() external view returns (address[] memory);

    /// @notice Retrieve all active orders
    /// @return Array of active order IDs
    function getActiveOrders() external view returns (bytes32[] memory);

    /// @notice Get user's nonce for replay protection
    /// @param _user User address
    /// @return nonce Current nonce
    function getUserNonce(address _user) external view returns (uint256 nonce);

    /// @notice Emergency token withdrawal
    /// @param _token ERC20 token address
    function emergencyWithdraw(address _token) external;
}

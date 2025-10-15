// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {PGatewayStructs} from "../";

/**
 * @title IPGateway
 * @notice Interface for PayNode Gateway - Non-custodial payment aggregator with parallel settlement
 * @dev Defines provider intent registry, order management, and settlement proposal handling
 */
interface IPGateway is PGatewayStructs {
    // ============================
    // Events
    // ============================

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

    // ============================
    // Admin Functions
    // ============================

    /// @notice Pause the contract
    function pause() external;

    /// @notice Unpause the contract
    function unpause() external;

    /// @notice Set supported token
    /// @param _token Token address
    /// @param _supported True to support, false to remove
    function setSupportedToken(address _token, bool _supported) external;

    /// @notice Set treasury address
    /// @param _newTreasury New treasury address
    function setTreasuryAddress(address _newTreasury) external;

    /// @notice Set aggregator address
    /// @param _newAggregator New aggregator address
    function setAggregatorAddress(address _newAggregator) external;

    /// @notice Set protocol fee percentage
    /// @param _newFee New fee in basis points (max 5000)
    function setProtocolFee(uint64 _newFee) external;

    /// @notice Set tier limits
    /// @param _smallLimit Small tier limit
    /// @param _mediumLimit Medium tier limit
    function setTierLimits(uint256 _smallLimit, uint256 _mediumLimit) external;

    /// @notice Set order expiry window
    /// @param _newWindow New expiry window in seconds
    function setOrderExpiryWindow(uint256 _newWindow) external;

    /// @notice Set proposal timeout duration
    /// @param _newTimeout New timeout in seconds
    function setProposalTimeout(uint256 _newTimeout) external;

    // ============================
    // Provider Intent Functions
    // ============================

    /// @notice Register provider intent with available capacity
    /// @param _currency Currency code
    /// @param _availableAmount Amount provider can handle
    /// @param _minFeeBps Minimum fee in basis points
    /// @param _maxFeeBps Maximum fee in basis points
    /// @param _commitmentWindow Time window for provider to accept
    function registerIntent(
        string calldata _currency,
        uint256 _availableAmount,
        uint64 _minFeeBps,
        uint64 _maxFeeBps,
        uint256 _commitmentWindow
    ) external;

    /// @notice Update existing provider intent
    /// @param _currency Currency code
    /// @param _newAmount New available amount
    function updateIntent(string calldata _currency, uint256 _newAmount) external;

    /// @notice Expire provider intent
    /// @param _provider Provider address
    function expireIntent(address _provider) external;

    /// @notice Reserve capacity when proposal is sent
    /// @param _provider Provider address
    /// @param _amount Amount to reserve
    function reserveIntent(address _provider, uint256 _amount) external;

    /// @notice Release reserved capacity
    /// @param _provider Provider address
    /// @param _amount Amount to release
    /// @param _reason Reason for release
    function releaseIntent(address _provider, uint256 _amount, string calldata _reason) external;

    /// @notice Get active provider intent
    /// @param _provider Provider address
    /// @return Provider intent details
    function getProviderIntent(address _provider) external view returns (ProviderIntent memory);

    // ============================
    // Order Creation Functions
    // ============================

    /// @notice Create a new order
    /// @param _token ERC20 token address
    /// @param _amount Order amount
    /// @param _refundAddress Address to refund if order fails
    /// @return orderId Generated order ID
    function createOrder(address _token, uint256 _amount, address _refundAddress)
        external
        returns (bytes32 orderId);

    /// @notice Get order details
    /// @param _orderId Order ID
    /// @return Order details
    function getOrder(bytes32 _orderId) external view returns (Order memory);

    // ============================
    // Settlement Proposal Functions
    // ============================

    /// @notice Create settlement proposal
    /// @param _orderId Order ID to settle
    /// @param _provider Provider address
    /// @param _proposedFeeBps Fee in basis points
    /// @return proposalId Generated proposal ID
    function createProposal(bytes32 _orderId, address _provider, uint64 _proposedFeeBps)
        external
        returns (bytes32 proposalId);

    /// @notice Provider accepts settlement proposal
    /// @param _proposalId Proposal ID to accept
    function acceptProposal(bytes32 _proposalId) external;

    /// @notice Provider rejects settlement proposal
    /// @param _proposalId Proposal ID to reject
    /// @param _reason Reason for rejection
    function rejectProposal(bytes32 _proposalId, string calldata _reason) external;

    /// @notice Mark proposal as timeout
    /// @param _proposalId Proposal ID
    function timeoutProposal(bytes32 _proposalId) external;

    /// @notice Get proposal details
    /// @param _proposalId Proposal ID
    /// @return Proposal details
    function getProposal(bytes32 _proposalId) external view returns (SettlementProposal memory);

    // ============================
    // Settlement Execution Functions
    // ============================

    /// @notice Execute settlement after provider accepts
    /// @param _proposalId Accepted proposal ID
    function executeSettlement(bytes32 _proposalId) external;

    // ============================
    // Refund Functions
    // ============================

    /// @notice Refund order if no provider accepts within timeout
    /// @param _orderId Order ID to refund
    function refundOrder(bytes32 _orderId) external;

    /// @notice Manual refund by user
    /// @param _orderId Order ID to refund
    function requestRefund(bytes32 _orderId) external;

    // ============================
    // Reputation Functions
    // ============================

    /// @notice Flag provider as fraudulent
    /// @param _provider Provider address
    function flagFraudulent(address _provider) external;

    /// @notice Blacklist provider
    /// @param _provider Provider address
    /// @param _reason Reason for blacklisting
    function blacklistProvider(address _provider, string calldata _reason) external;

    /// @notice Get provider reputation
    /// @param _provider Provider address
    /// @return Provider reputation details
    function getProviderReputation(address _provider) external view returns (ProviderReputation memory);

    // ============================
    // Utility Functions
    // ============================

    /// @notice Get all registered providers
    /// @return Array of provider addresses
    function getRegisteredProviders() external view returns (address[] memory);

    /// @notice Get all active orders
    /// @return Array of active order IDs
    function getActiveOrders() external view returns (bytes32[] memory);

    /// @notice Get user nonce for replay protection
    /// @param _user User address
    /// @return Current nonce value
    function getUserNonce(address _user) external view returns (uint256);

    /// @notice Emergency withdrawal
    /// @param _token Token address to withdraw
    function emergencyWithdraw(address _token) external;
}
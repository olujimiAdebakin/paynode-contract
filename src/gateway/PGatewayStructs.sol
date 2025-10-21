// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title PGatewayStructs
 * @notice Defines the core data structures and enums used across the PayNode Gateway protocol.
 * @dev This contract serves as a shared schema layer for the PayNode ecosystem, ensuring consistent
 * type definitions across modules like PGatewayCore, PGatewayStorage, and PGatewaySettings.
 * @author Olujimi
 */
library PGatewayStructs {
    /* ========== ENUMS ========== */

    /**
     * @notice Defines order tier levels based on transaction amount ranges.
     * @dev Used to determine fee tiers, routing logic, and provider eligibility.
     */
    enum OrderTier {
        ALPHA, // < 3,000
        BETA, // 3,000 - 5,000
        DELTA, // 5,000 - 7,000
        OMEGA, // 7,000 - 10,000
        TITAN // > 10,000

    }

    /**
     * @notice Represents the lifecycle state of an order.
     * @dev Transitions follow logical flow: PENDING → PROPOSED → ACCEPTED → FULFILLED/REFUNDED/CANCELLED.
     */
    enum OrderStatus {
        PENDING,
        PROPOSED,
        ACCEPTED,
        FULFILLED,
        REFUNDED,
        CANCELLED
    }

    /**
     * @notice Represents the current lifecycle stage of a provider's settlement proposal.
     * @dev Each proposal references an order and can expire or be cancelled independently.
     */
    enum ProposalStatus {
        PENDING,
        ACCEPTED,
        REJECTED,
        TIMEOUT,
        CANCELLED
    }

    /* ========== STRUCTS ========== */


struct IntegratorInfo {
    bool isRegistered;         // Whether integrator has registered
    uint64 feeBps;             // Integrator's self-set fee in basis points
    string name;               // Integrator's name/identifier
    uint256 registeredAt;      // Timestamp of registration
    uint256 totalOrders;       // Total orders from this integrator
    uint256 totalVolume;       // Total volume processed
}

    struct InitiateGatewaySettingsParams {
    address initialOwner;
    address treasury;
    address aggregator;
    uint64 protocolFee;
    uint256 alphaLimit;
    uint256 betaLimit;
    uint256 deltaLimit;
    address integrator;
    uint64 integratorFee;
    uint256 omegaLimit;
    uint256 titanLimit;
    uint256 orderExpiryWindow;
    uint256 proposalTimeout;
    uint256 intentExpiry;
}

    /**
     * @title ProviderIntent
     * @notice Defines a provider's available liquidity and operational parameters.
     * @dev Registered providers expose their available balance, fee range, and active time window.
     * @param provider Address of the liquidity provider.
     * @param currency The token or fiat currency symbol the provider supports (e.g., "USDC").
     * @param availableAmount Total amount the provider is willing to allocate for settlements.
     * @param minFeeBps Minimum acceptable fee in basis points (1 basis point = 0.01%).
     * @param maxFeeBps Maximum fee provider may charge, also in basis points.
     * @param registeredAt Timestamp when the provider registered this intent.
     * @param expiresAt Timestamp when the provider’s intent expires and becomes inactive.
     * @param commitmentWindow Minimum duration the provider must remain available after accepting an order.
     * @param isActive Whether the provider is currently active and accepting new requests.
     */
    struct ProviderIntent {
        address provider;
        string currency;
        uint256 availableAmount;
        uint64 minFeeBps;
        uint64 maxFeeBps;
        uint256 registeredAt;
        uint256 expiresAt;
        uint256 commitmentWindow;
        bool isActive;
    }

    /**
     * @title Order
     * @notice Represents a user's payment or settlement order in the PayNode Gateway.
     * @dev Each order can have multiple settlement proposals and transitions through lifecycle states.
     * @param orderId Unique hash-based identifier for the order.
     * @param user Address of the user initiating the order.
     * @param token ERC20 token address used for payment.
     * @param amount Amount of tokens involved in the order.
     * @param tier Tier classification based on amount (see {OrderTier}).
     * @param status Current lifecycle state of the order.
     * @param refundAddress Address where refunds should be sent if order fails or expires.
     * @param createdAt Timestamp when the order was created.
     * @param expiresAt Timestamp after which the order is considered expired.
     * @param acceptedProposalId The proposalId of the accepted provider offer, if any.
     * @param fulfilledByProvider Address of the provider who fulfilled the order.
     */
    struct Order {
        bytes32 orderId;
        address user;
        address token;
        uint256 amount;
        OrderTier tier;
        OrderStatus status;
        address refundAddress;
        uint256 createdAt;
        uint256 expiresAt;
        bytes32 acceptedProposalId;
        address fulfilledByProvider;
        address integrator; // dApp or partner that integrated PayNode
        uint256 integratorFee;
        bytes32 _messageHash;
    }

    /**
     * @title SettlementProposal
     * @notice Defines a provider's proposed settlement terms for a specific order.
     * @dev Each proposal includes fee rate, proposed payout, and its own deadline.
     * @param proposalId Unique identifier for the proposal.
     * @param orderId Associated order’s unique identifier.
     * @param provider Address of the provider submitting the proposal.
     * @param proposedAmount Amount provider proposes to settle.
     * @param proposedFeeBps Fee charged by the provider in basis points.
     * @param proposedAt Timestamp when proposal was submitted.
     * @param proposalDeadline Deadline after which proposal becomes invalid.
     * @param status Current lifecycle state of the proposal (see {ProposalStatus}).
     */
    struct SettlementProposal {
        bytes32 proposalId;
        bytes32 orderId;
        address provider;
        uint256 proposedAmount;
        uint64 proposedFeeBps;
        uint256 proposedAt;
        uint256 proposalDeadline;
        ProposalStatus status;
    }

    /**
     * @title ProviderReputation
     * @notice Tracks a provider’s on-chain performance and reliability metrics.
     * @dev Used for scoring, fraud detection, and automated provider ranking.
     * @param provider Provider address this record refers to.
     * @param totalOrders Total number of orders assigned to this provider.
     * @param successfulOrders Number of successfully completed orders.
     * @param failedOrders Number of failed or cancelled orders.
     * @param noShowCount Number of accepted orders that were never fulfilled.
     * @param totalSettlementTime Sum of durations for all settlements, used to calculate averages.
     * @param lastUpdated Timestamp when this record was last modified.
     * @param isFraudulent Whether the provider was flagged for suspicious activity.
     * @param isBlacklisted Whether the provider is banned from participating.
     */
    struct ProviderReputation {
        address provider;
        uint256 totalOrders;
        uint256 successfulOrders;
        uint256 failedOrders;
        uint256 noShowCount;
        uint256 totalSettlementTime;
        uint256 lastUpdated;
        bool isFraudulent;
        bool isBlacklisted;
    }
}

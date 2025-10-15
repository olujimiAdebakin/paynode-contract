// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract PGatewayStructs {
    /* ========== ENUMS ========== */
    enum OrderTier {
        SMALL,
        MEDIUM,
        LARGE
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

    /* ========== STRUCTS ========== */
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
    }

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

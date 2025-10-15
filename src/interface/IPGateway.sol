// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./PGatewayStructs.sol";

interface IPGateway {
    /* ========== PROVIDER INTENT ========== */
    function registerIntent(
        string calldata _currency,
        uint256 _availableAmount,
        uint64 _minFeeBps,
        uint64 _maxFeeBps,
        uint256 _commitmentWindow
    ) external;

    function updateIntent(
        string calldata _currency,
        uint256 _newAmount
    ) external;

    function expireIntent(address _provider) external;

    /* ========== ORDER ========== */
    function createOrder(
        address _token,
        uint256 _amount,
        address _refundAddress
    ) external returns (bytes32);

    function getOrder(bytes32 _orderId) external view returns (PGatewayStructs.Order memory);

    /* ========== PROPOSAL ========== */
    function createProposal(
        bytes32 _orderId,
        address _provider,
        uint64 _proposedFeeBps
    ) external returns (bytes32);

    function acceptProposal(bytes32 _proposalId) external;

    function rejectProposal(bytes32 _proposalId, string calldata _reason) external;

    function timeoutProposal(bytes32 _proposalId) external;

    function getProposal(bytes32 _proposalId) external view returns (PGatewayStructs.SettlementProposal memory);

    /* ========== SETTLEMENT ========== */
    function executeSettlement(bytes32 _proposalId) external;

    /* ========== REFUND ========== */
    function refundOrder(bytes32 _orderId) external;
    function requestRefund(bytes32 _orderId) external;

    /* ========== REPUTATION ========== */
    function getProviderReputation(address _provider) external view returns (PGatewayStructs.ProviderReputation memory);
}

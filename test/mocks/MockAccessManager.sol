// test/mocks/MockAccessManager.sol
pragma solidity ^0.8.24;

import {IPayNodeAccessManager} from "../../src/interface/IAccessManager.sol";


contract MockAccessManager is IPayNodeAccessManager {
    // Role Constants
    bytes32 public constant override ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant override OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant override DISPUTE_MANAGER_ROLE = keccak256("DISPUTE_MANAGER_ROLE");
    bytes32 public constant override PLATFORM_SERVICE_ROLE = keccak256("PLATFORM_SERVICE_ROLE");
    bytes32 public constant override DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant override AGGREGATOR_ROLE = keccak256("AGGREGATOR_ROLE");
    bytes32 public constant override FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant override PROVIDER_ROLE = keccak256("PROVIDER_ROLE");

    // System Flag Constants
    bytes32 public constant override TRADING_ENABLED = keccak256("TRADING_ENABLED");
    bytes32 public constant override WITHDRAWALS_ENABLED = keccak256("WITHDRAWALS_ENABLED");

    // State Variables
    bool public override systemLocked;
    address public override pasarAdmin;
    address public override superAdmin;
    uint256 public override MIN_DELAY = 2 days;

    // Storage
    mapping(bytes32 => mapping(address => bool)) public roles;
    mapping(bytes32 => bool) public override systemFlags;
    mapping(address => bool) public override isBlacklisted;
    mapping(bytes32 => PendingAdminChange) public pendingAdminChanges;
    
    // Reentrancy protection
    bool private reentrancyLock;

    struct PendingAdminChange {
        address newAdmin;
        bool isSuperAdmin;
        uint256 scheduleTime;
        bool exists;
    }

    constructor(address _superAdmin) {
        superAdmin = _superAdmin;
        pasarAdmin = _superAdmin;
        roles[DEFAULT_ADMIN_ROLE][_superAdmin] = true;
        roles[ADMIN_ROLE][_superAdmin] = true;
        
        // Set default system flags
        systemFlags[TRADING_ENABLED] = true;
        systemFlags[WITHDRAWALS_ENABLED] = true;
    }

    // ============================
    // Role Management
    // ============================

    function grantRole(bytes32 role, address account) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        roles[role][account] = true;
        emit RoleAssigned(account, role, msg.sender);
    }

    function revokeRole(bytes32 role, address account) external {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        roles[role][account] = false;
        emit RoleRevoked(account, role, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return roles[role][account];
    }

    function getAccountRoles(address account) external view override returns (bytes32[] memory) {
        // Simplified implementation for testing
        bytes32[] memory accountRoles = new bytes32[](7);
        uint256 count = 0;
        
        if (hasRole(ADMIN_ROLE, account)) accountRoles[count++] = ADMIN_ROLE;
        if (hasRole(OPERATOR_ROLE, account)) accountRoles[count++] = OPERATOR_ROLE;
        if (hasRole(DISPUTE_MANAGER_ROLE, account)) accountRoles[count++] = DISPUTE_MANAGER_ROLE;
        if (hasRole(PLATFORM_SERVICE_ROLE, account)) accountRoles[count++] = PLATFORM_SERVICE_ROLE;
        if (hasRole(DEFAULT_ADMIN_ROLE, account)) accountRoles[count++] = DEFAULT_ADMIN_ROLE;
        if (hasRole(AGGREGATOR_ROLE, account)) accountRoles[count++] = AGGREGATOR_ROLE;
        if (hasRole(FEE_MANAGER_ROLE, account)) accountRoles[count++] = FEE_MANAGER_ROLE;
        if (hasRole(PROVIDER_ROLE, account)) accountRoles[count++] = PROVIDER_ROLE;
        
        // Resize array to actual count
        bytes32[] memory result = new bytes32[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = accountRoles[i];
        }
        return result;
    }

    function isOperator(address account) external view override returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    // ============================
    // System Flag Management
    // ============================

    function setSystemFlag(bytes32 flag, bool status) external override {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        systemFlags[flag] = status;
        emit SystemFlagUpdated(flag, status, msg.sender);
    }

    // ============================
    // Blacklist Management
    // ============================

    function setBlacklistStatus(address user, bool status) external override {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        isBlacklisted[user] = status;
        emit BlacklistStatusChanged(user, status, msg.sender);
    }

    function batchUpdateBlacklist(address[] calldata users, bool[] calldata statuses) external override {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        if (users.length != statuses.length) revert BatchOperationFailed(0);
        
        for (uint256 i = 0; i < users.length; i++) {
            isBlacklisted[users[i]] = statuses[i];
            emit BlacklistStatusChanged(users[i], statuses[i], msg.sender);
        }
    }

    // ============================
    // Admin Change Management (Timelocked)
    // ============================

    function scheduleAdminChange(address newAdmin, bool isSuperAdmin) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        if (newAdmin == address(0)) revert InvalidAddress();
        
        bytes32 operationId = keccak256(abi.encode(newAdmin, isSuperAdmin, block.timestamp));
        uint256 scheduleTime = block.timestamp + MIN_DELAY;
        
        pendingAdminChanges[operationId] = PendingAdminChange({
            newAdmin: newAdmin,
            isSuperAdmin: isSuperAdmin,
            scheduleTime: scheduleTime,
            exists: true
        });
        
        emit AdminChangeScheduled(newAdmin, isSuperAdmin, scheduleTime, operationId);
    }

    function executeAdminChange(bytes32 operationId) external override {
        PendingAdminChange memory change = pendingAdminChanges[operationId];
        if (!change.exists) revert AdminChangeNotReady(operationId);
        if (block.timestamp < change.scheduleTime) revert AdminChangeNotReady(operationId);
        
        if (change.isSuperAdmin) {
            superAdmin = change.newAdmin;
        } else {
            pasarAdmin = change.newAdmin;
        }
        
        delete pendingAdminChanges[operationId];
    }

    function cancelAdminChange(bytes32 operationId) external override {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        if (!pendingAdminChanges[operationId].exists) revert AdminChangeNotReady(operationId);
        
        delete pendingAdminChanges[operationId];
    }

    function isAdminChangeReady(bytes32 operationId) external view override returns (bool) {
        PendingAdminChange memory change = pendingAdminChanges[operationId];
        return change.exists && block.timestamp >= change.scheduleTime;
    }

    // ============================
    // Emergency Controls
    // ============================

    function emergencyShutdown() external override {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        systemLocked = true;
        emit EmergencyShutdown(msg.sender);
    }

    function restoreSystem() external override {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        systemLocked = false;
        emit SystemRestored(msg.sender);
    }

    function pause() external override {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        systemLocked = true;
    }

    function unpause() external override {
        if (!hasRole(ADMIN_ROLE, msg.sender)) revert UnauthorizedOperation();
        systemLocked = false;
    }

    // ============================
    // Reentrancy Protection
    // ============================

    function executeNonReentrant(address caller, bytes32 role) external override returns (bool success) {
        if (reentrancyLock) return false;
        if (role != bytes32(0) && !hasRole(role, caller)) return false;
        
        reentrancyLock = true;
        // Simulate some work - in real implementation this would be the actual function call
        reentrancyLock = false;
        return true;
    }

    function executeProviderNonReentrant(address caller) external override returns (bool success) {
        if (reentrancyLock) return false;
        if (isBlacklisted[caller]) return false;
        if (!hasRole(PROVIDER_ROLE, caller)) return false;
        
        reentrancyLock = true;
        // Simulate some work
        reentrancyLock = false;
        return true;
    }

    function executeAggregatorNonReentrant(address caller) external override returns (bool success) {
        if (reentrancyLock) return false;
        if (!hasRole(AGGREGATOR_ROLE, caller)) return false;
        
        reentrancyLock = true;
        // Simulate some work
        reentrancyLock = false;
        return true;
    }

    // ============================
    // Dispute and Service Management
    // ============================

    function resolveDispute(uint256 /* disputeId */, address /*winner*/) external view override {
        if (!hasRole(DISPUTE_MANAGER_ROLE, msg.sender)) revert UnauthorizedOperation();
        // Mock implementation - just emit event or do nothing for tests
    }

    function managePlatformService(bytes32 /*serviceId*/, bool /*enable*/) external view override {
        if (!hasRole(PLATFORM_SERVICE_ROLE, msg.sender)) revert UnauthorizedOperation();
        // Mock implementation
    }
}
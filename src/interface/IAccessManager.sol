
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IPayNodeAccessManager
 * @notice Interface for PayNode AccessManager - manages access control and system state
 * @dev Defines roles, blacklisting, system flags, emergency controls, and timelocked admin changes
 */
interface IPayNodeAccessManager {
    // ============================
    // Role Constants
    // ============================

    function ADMIN_ROLE() external view returns (bytes32);
    function OPERATOR_ROLE() external view returns (bytes32);
    function DISPUTE_MANAGER_ROLE() external view returns (bytes32);
    function PLATFORM_SERVICE_ROLE() external view returns (bytes32);
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    // ============================
    // System Flag Constants
    // ============================

    function TRADING_ENABLED() external view returns (bytes32);
    function WITHDRAWALS_ENABLED() external view returns (bytes32);

    // ============================
    // Custom Errors
    // ============================

    error InvalidAddress();
    error UserBlacklisted(address user);
    error InvalidRoleConfiguration();
    error SystemFlagNotFound(bytes32 flag);
    error UnauthorizedOperation();
    error BatchOperationFailed(uint256 index);

    // ============================
    // Events
    // ============================

    event SystemFlagUpdated(bytes32 indexed flag, bool status, address indexed operator);
    event BlacklistStatusChanged(address indexed user, bool status, address indexed operator);
    event RoleAssigned(address indexed account, bytes32 indexed role, address indexed assigner);
    event RoleRevoked(address indexed account, bytes32 indexed role, address indexed revoker);
    event EmergencyShutdown(address indexed operator);
    event SystemRestored(address indexed operator);
    event AdminChangeScheduled(
        address indexed newAdmin, bool isSuperAdmin, uint256 scheduleTime, bytes32 indexed operationId
    );

    // ============================
    // State Variables
    // ============================

    /// @notice Tracks whether the system is in emergency locked state
    function systemLocked() external view returns (bool);

    /// @notice Address of the PasarAdmin contract
    function pasarAdmin() external view returns (address);

    /// @notice Address of the super admin (DEFAULT_ADMIN_ROLE holder)
    function superAdmin() external view returns (address);

    /// @notice Minimum delay for timelocked operations
    function MIN_DELAY() external view returns (uint256);

    /// @notice Maps system flags to their boolean status
    function systemFlags(bytes32 flag) external view returns (bool);

    /// @notice Maps addresses to their blacklist status
    function isBlacklisted(address user) external view returns (bool);

    // ============================
    // System Flag Management
    // ============================

    /// @notice Updates the status of a predefined system flag
    /// @param flag The identifier of the system flag
    /// @param status The new status (true to enable, false to disable)
    function setSystemFlag(bytes32 flag, bool status) external;

    // ============================
    // Blacklist Management
    // ============================

    /// @notice Updates the blacklist status for a single user
    /// @param user The address to update
    /// @param status The new blacklist status (true to blacklist, false to unblacklist)
    function setBlacklistStatus(address user, bool status) external;

    /// @notice Updates the blacklist status for multiple users in a batch
    /// @param users An array of addresses to update
    /// @param statuses An array of boolean statuses corresponding to each user
    function batchUpdateBlacklist(address[] calldata users, bool[] calldata statuses) external;

    // ============================
    // Admin Change Management (Timelocked)
    // ============================

    /// @notice Schedules a change for the superAdmin or pasarAdmin address
    /// @param newAdmin The new address proposed for the admin role
    /// @param isSuperAdmin True if changing superAdmin, false if changing pasarAdmin
    function scheduleAdminChange(address newAdmin, bool isSuperAdmin) external;

    /// @notice Executes a previously scheduled admin change after its timelock has passed
    /// @param operationId The unique identifier of the pending admin change
    function executeAdminChange(bytes32 operationId) external;

    /// @notice Cancels a pending admin change operation
    /// @param operationId The unique identifier of the pending admin change to cancel
    function cancelAdminChange(bytes32 operationId) external;

    // ============================
    // Emergency Controls
    // ============================

    /// @notice Initiates an emergency shutdown of core system functions
    function emergencyShutdown() external;

    /// @notice Restores core system functions after an emergency shutdown
    function restoreSystem() external;

    /// @notice Pauses the contract
    function pause() external;

    /// @notice Unpauses the contract
    function unpause() external;

    // ============================
    // Dispute and Service Management
    // ============================

    /// @notice Resolves a dispute (virtual function for override by derived contracts)
    /// @param disputeId The unique ID of the dispute to resolve
    /// @param winner The address of the party who won the dispute
    function resolveDispute(uint256 disputeId, address winner) external;

    /// @notice Manages platform services (virtual function for override by derived contracts)
    /// @param serviceId The unique identifier of the service to manage
    /// @param enable True to enable the service, false to disable
    function managePlatformService(bytes32 serviceId, bool enable) external;

    // ============================
    // View Functions
    // ============================

    /// @notice Checks if a given address has operator privileges
    /// @param account The address to check
    /// @return True if the address holds the OPERATOR_ROLE
    function isOperator(address account) external view returns (bool);

    /// @notice Retrieves all roles assigned to a given address
    /// @param account The address to check
    /// @return An array of bytes32 role identifiers held by the account
    function getAccountRoles(address account) external view returns (bytes32[] memory);

    /// @notice Checks if a scheduled admin change is ready for execution
    /// @param operationId The unique identifier of the pending admin change
    /// @return True if the operation is ready to execute
    function isAdminChangeReady(bytes32 operationId) external view returns (bool);

    /// @notice Checks if an account has a specific role
    /// @param role The role identifier to check
    /// @param account The address to check
    /// @return True if the account has the role
    function hasRole(bytes32 role, address account) external view returns (bool);
}
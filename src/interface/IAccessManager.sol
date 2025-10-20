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

    /**
     * @notice Returns the constant identifier for the admin role.
     * @dev Holders of this role can perform privileged system-level operations,
     *      including role assignments, configuration updates, and contract governance.
     */
    function ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the constant identifier for the operator role.
     * @dev Operators handle routine execution tasks such as triggering settlements,
     *      managing provider intents, and maintaining order flow within the gateway.
     */
    function OPERATOR_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the constant identifier for the dispute manager role.
     * @dev Dispute managers are responsible for resolving transaction disputes,
     *      refunds, and arbitration processes between users and providers.
     */
    function DISPUTE_MANAGER_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the constant identifier for the platform service role.
     * @dev This role is typically held by auxiliary service contracts or modules
     *      that interact with the PayNode gateway (e.g., analytics, off-chain agents).
     */
    function PLATFORM_SERVICE_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the constant identifier for the default admin role.
     * @dev This is the root access role that controls all other roles.
     *      By convention, it is assigned to the deployer or governance multisig.
     */
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the constant identifier for the aggregator role.
     * @dev Aggregators are external protocols or dApps that integrate PayNode,
     *      initiate orders, and facilitate routing on behalf of their users.
     */
    function AGGREGATOR_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the constant identifier for the fee manager role.
     * @dev Fee managers configure fee rates, integrator shares, and fee distribution
     *      logic across providers, users, and protocol stakeholders.
     */
    function FEE_MANAGER_ROLE() external view returns (bytes32);

    // ============================
    // System Flag Constants
    // ============================

    function TRADING_ENABLED() external view returns (bytes32);
    function WITHDRAWALS_ENABLED() external view returns (bytes32);

    // ============================
    // Custom Errors
    // ============================

    /**
     * @notice Thrown when a provided address parameter is invalid.
     * @dev Typically used to reject zero addresses or uninitialized account references.
     */
    error InvalidAddress();

    /**
     * @notice Thrown when a blacklisted user attempts to perform a restricted operation.
     * @param user The address of the user who is blacklisted.
     */
    error UserBlacklisted(address user);

    /**
     * @notice Thrown when a role or permission setup is improperly configured.
     * @dev May occur during initialization or role assignment logic.
     */
    error InvalidRoleConfiguration();

    /**
     * @notice Thrown when a referenced system flag does not exist in registry.
     * @param flag The identifier of the missing or invalid flag.
     */
    error SystemFlagNotFound(bytes32 flag);

    /**
     * @notice Thrown when a caller attempts an action without sufficient privileges.
     * @dev Used as a generic catch-all for access control violations.
     */
    error UnauthorizedOperation();

    /**
     * @notice Thrown when a batch operation fails at a specific index.
     * @dev Enables granular debugging of multi-operation execution flows.
     * @param index The index in the batch where execution failed.
     */
    error BatchOperationFailed(uint256 index);

    /**
     * @notice Thrown when an invalid or unrecognized role identifier is referenced.
     * @dev Common in access control checks or during misconfigured role management.
     */
    error InvalidRole();

    /**
     * @notice Thrown when attempting to execute an admin change before its timelock expires.
     * @dev Ensures that delayed admin actions follow governance timelock rules.
     * @param operationId The unique identifier of the pending admin change operation.
     */
    error AdminChangeNotReady(bytes32 operationId);

    // ============================
    // System & Access Control Events
    // ============================

    /**
     * @notice Emitted when a specific system flag is toggled on or off.
     * @dev Flags may represent runtime states such as maintenance mode or feature activation.
     * @param flag The identifier of the flag being updated.
     * @param status The new status of the flag (true = enabled, false = disabled).
     * @param operator The address of the operator who performed the update.
     */
    event SystemFlagUpdated(bytes32 indexed flag, bool status, address indexed operator);

    /**
     * @notice Emitted when a user's blacklist status is changed.
     * @dev Used for compliance or security enforcement (e.g., fraud prevention).
     * @param user The address of the affected user.
     * @param status The new blacklist status (true = blacklisted, false = cleared).
     * @param operator The address of the operator that modified the status.
     */
    event BlacklistStatusChanged(address indexed user, bool status, address indexed operator);

    /**
     * @notice Emitted when a role is assigned to an account.
     * @dev Tracks on-chain role management for transparency and auditing.
     * @param account The address that received the role.
     * @param role The role identifier (hash of the role string).
     * @param assigner The address of the admin that granted the role.
     */
    event RoleAssigned(address indexed account, bytes32 indexed role, address indexed assigner);

    /**
     * @notice Emitted when a role is revoked from an account.
     * @dev Tracks revocations for security audits and access lifecycle management.
     * @param account The address that lost the role.
     * @param role The role identifier (hash of the role string).
     * @param revoker The address of the admin that revoked the role.
     */
    event RoleRevoked(address indexed account, bytes32 indexed role, address indexed revoker);

    /**
     * @notice Emitted when the system enters emergency shutdown mode.
     * @dev Used to halt all critical operations in response to a detected vulnerability
     *      or protocol-level anomaly until manual intervention occurs.
     * @param operator The address of the admin/operator who triggered the shutdown.
     */
    event EmergencyShutdown(address indexed operator);

    /**
     * @notice Emitted when the system is restored from a shutdown state.
     * @dev Re-enables previously disabled operations and resumes protocol activity.
     * @param operator The address of the admin/operator who restored the system.
     */
    event SystemRestored(address indexed operator);

    /**
     * @notice Emitted when a new admin change operation is scheduled via timelock.
     * @dev Ensures transparent governance by delaying high-privilege actions.
     * @param newAdmin The address proposed to become the new admin.
     * @param isSuperAdmin Whether the proposed admin is for the super admin role.
     * @param scheduleTime The timestamp after which the change can be executed.
     * @param operationId The unique identifier (hash) of this admin change operation.
     */
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
    // Reentrancy Protection
    // ============================

    /**
     * @notice Executes a protected function call for a given caller and role.
     * @dev This function should be implemented to prevent reentrancy attacks
     *      while allowing role-based execution. Typically, it wraps critical
     *      logic with a nonReentrant modifier or equivalent lock mechanism.
     * @param caller The address invoking the protected function.
     * @param role The role identifier of the caller (e.g., PROVIDER_ROLE, ADMIN_ROLE).
     * @return success True if the execution passed reentrancy checks and was allowed.
     */
    function executeNonReentrant(address caller, bytes32 role) external returns (bool success);

    /**
     * @notice Executes a non-reentrant operation for a registered provider.
     * @dev This specialized variant focuses on provider-only flows (e.g., settlement,
     *      proposal submission, or fund release) and ensures each provider can only
     *      trigger one protected call at a time.
     * @param caller The provider’s address attempting execution.
     * @return success True if the call is allowed under reentrancy guard.
     */
    function executeProviderNonReentrant(address caller) external returns (bool success);

    /**
     * @notice Executes a non-reentrant operation for an aggregator or integrator contract.
     * @dev Designed for aggregator-level interactions that could trigger multiple
     *      downstream calls. Protects against nested aggregator calls or indirect
     *      reentrancy into settlement logic.
     * @param caller The aggregator contract address.
     * @return success True if the operation is safe to proceed under reentrancy guard.
     */
    function executeAggregatorNonReentrant(address caller) external returns (bool success);

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

# PayNode Smart Contract Protocol

## Overview
PayNode is a non-custodial payment aggregation protocol that connects users with multiple liquidity providers for fast, efficient settlements. Instead of routing orders to a single provider (bottleneck), PayNode sends simultaneous settlement proposals to multiple providers in parallel—the first to accept executes the order.


Core Innovation: Providers pre-register their available capacity (intent), eliminating stale pricing and enabling intelligent provider selection. The system automatically ranks providers by success rate, speed, uptime, and fees, then races them for each order.


System Architecture

┌─────────────────────────────────────────────────────────┐
│                    AccessManager                         │
│  • Admin role control                                    │
│  • Pause/Unpause permissions                            │
│  • Blacklist management                                 │
│  • Role-based access control (RBAC)                     │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│                  TimelockAdmin                          │
│  • Upgrade scheduling (48h delay)                       │
│  • Proposal queuing                                     │
│  • Execution after timelock                            │
│  • Cancel malicious upgrades                           │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│            PayNodeGatewaySettings                       │
│  • Configuration parameters                             │
│  • Token whitelist                                      │
│  • Fee settings                                         │
│  • Tier limits (SMALL/MEDIUM/LARGE)                    │
└─────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────┐
│             PayNodeGateway (Proxy)                       │
│  • Order creation & management                          │
│  • Provider intent registry                             │
│  • Settlement proposals (parallel)                      │
│  • Settlement execution                                │
│  • Refund handling                                      │
│  • Reputation tracking                                 │
└─────────────────────────────────────────────────────────┘

## Features
-   **Role-Based Access Control (RBAC)**: Centralized permission management via `PayNodeAccessManager` with distinct roles for administrators, operators, and platform services.
-   **Secure Upgradeability**: Utilizes UUPS proxy patterns and a `PayNodeAdmin` contract with timelock mechanisms (2-day delay) for controlled and transparent contract upgrades.
-   **Decentralized Payment Gateway**: `PGateway` facilitates non-custodial order creation, parallel settlement proposals from multiple providers, and fee distribution.
-   **Provider Intent Registry**: Providers can register and update their intent, specifying available liquidity, fee ranges, and commitment windows for order fulfillment.
-   **Tier-Based Order Processing**: Orders are categorized into tiers (SMALL, MEDIUM, LARGE) based on amount, enabling optimized routing strategies for aggregators.
-   **Reputation System**: Tracks provider performance metrics such as successful orders, failed orders, and no-show counts to inform selection.
-   **Emergency Controls**: Includes `Pausable` functionality and a system-wide lock mechanism for immediate response to critical security events.
-   **Chainlink Automation Integration**: `PayNodeAdmin` supports automated execution of scheduled upgrades via Chainlink Keepers, ensuring reliability and reducing manual intervention.
-   **ERC20 Token Support**: The `PGateway` handles ERC20 token transfers for order amounts and fees.
-   **Blacklisting**: Mechanism to flag and restrict malicious or non-compliant providers.

## Getting Started

### Installation
This project uses [Foundry](https://getfoundry.sh/) for smart contract development, testing, and deployment.

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/olujimiAdebakin/paynode-contract.git
    cd paynode-contract
    ```

2.  **Install Foundry**:
    If you do not have Foundry installed, follow the instructions on the [Foundry Book](https://book.getfoundry.sh/getting-started/installation).
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3.  **Install Dependencies**:
    Fetch the necessary OpenZeppelin and Chainlink libraries.
    ```bash
    forge install
    ```

4.  **Compile Contracts**:
    Compile the smart contracts to ensure everything is set up correctly.
    ```bash
    forge build
    ```

5.  **Run Tests (Optional but Recommended)**:
    Execute the test suite to verify contract functionality.
    ```bash
    forge test
    ```

### Environment Variables
The following parameters are required during contract deployment and initialization. These are not traditional environment variables but rather critical configuration values passed during the initial setup of the smart contracts.

#### PayNodeAccessManager Initialization
*   `_pasarAdmin`: Address designated as the initial `ADMIN_ROLE` holder, typically the deployed `PayNodeAdmin` contract.
    *   Example: `0xAdminContractAddress`
*   `_superAdmin`: Address designated as the initial `DEFAULT_ADMIN_ROLE` holder, possessing the highest authority.
    *   Example: `0xSuperAdminWalletAddress`
*   `operators`: An array of addresses to be granted the `OPERATOR_ROLE` for day-to-day operations like blacklist management.
    *   Example: `["0xOperator1Address", "0xOperator2Address"]`

#### PayNodeAdmin Constructor
*   `proposers`: An array of addresses authorized to propose timelocked operations (e.g., scheduled upgrades).
    *   Example: `["0xProposer1Address"]`
*   `executors`: An array of addresses authorized to execute timelocked operations once the delay has passed.
    *   Example: `["0xExecutor1Address", "0xChainlinkKeeperAddress"]`
*   `superAdmin`: Address to receive the `DEFAULT_ADMIN_ROLE` for this specific `PayNodeAdmin` instance, enabling its governance over roles.
    *   Example: `0xSuperAdminWalletAddress`
*   `upgradeAdmin`: Address to receive the `ADMIN_ROLE` for this `PayNodeAdmin` instance, specifically for upgrade-related tasks.
    *   Example: `0xUpgradeManagerWalletAddress`
*   `_chainlinkKeeper`: The address of the authorized Chainlink Keeper service for automated upkeep.
    *   Example: `0xChainlinkKeeperAddress`

#### PGateway Initialization
*   `_treasuryAddress`: The address where protocol fees will be collected.
    *   Example: `0xProtocolTreasuryAddress`
*   `_aggregatorAddress`: The address of the off-chain aggregator service responsible for creating proposals and executing settlements.
    *   Example: `0xAggregatorServiceAddress`

## API Documentation

The PayNode protocol consists of several interconnected smart contracts. Interaction occurs by sending transactions to these deployed contract addresses on a supported EVM-compatible blockchain.

### Base URL
The "base URL" for interacting with these contracts is the specific contract address on the chosen blockchain network (e.g., Ethereum Mainnet, Polygon, etc.).

### Contracts and Endpoints

#### PayNodeAccessManager API

The `PayNodeAccessManager` contract manages access control, system-wide flags, and emergency states.

##### `public constant ADMIN_ROLE`
Role identifier for authorized upgrade admins.

##### `public constant OPERATOR_ROLE`
Role identifier for operational team members.

##### `public constant DISPUTE_MANAGER_ROLE`
Role identifier for entities authorized to manage disputes.

##### `public constant PLATFORM_SERVICE_ROLE`
Role identifier for trusted backend services and AI agents.

##### `public constant MIN_DELAY`
Minimum delay of 2 days for critical operations like admin changes.

##### `public constant TRADING_ENABLED`
System flag identifier to control overall trading functionality.

##### `public constant WITHDRAWALS_ENABLED`
System flag identifier to control overall withdrawal functionality.

##### `external initialize(address _pasarAdmin, address _superAdmin, address[] calldata operators)`
**Description**: Initializes the contract, sets up initial roles, and assigns core admin addresses.
**Request**:
```json
{
  "_pasarAdmin": "0xPasarAdminContractAddress",
  "_superAdmin": "0xSuperAdminWalletAddress",
  "operators": ["0xOperator1Address", "0xOperator2Address"]
}
```
**Response**:
*   No explicit return value.
*   State changes: `superAdmin`, `pasarAdmin` are set; roles are granted.
**Events Emitted**: `RoleAssigned`
**Errors**:
- `InvalidAddress`: Provided zero address for critical roles or empty operators array.
- `InvalidRoleConfiguration`: Attempted to assign operator role to an existing admin.

##### `external setSystemFlag(bytes32 flag, bool status)`
**Description**: Updates the status of a predefined system flag (e.g., `TRADING_ENABLED`, `WITHDRAWALS_ENABLED`). Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**:
```json
{
  "flag": "0x" + keccak256("TRADING_ENABLED").toString("hex"), // or keccak256("WITHDRAWALS_ENABLED")
  "status": true // or false
}
```
**Response**:
*   No explicit return value.
*   State changes: `systemFlags[flag]` is updated.
**Events Emitted**: `SystemFlagUpdated`
**Errors**:
- `SystemFlagNotFound`: Provided an unrecognized flag.
- `UnauthorizedOperation`: Caller does not have `DEFAULT_ADMIN_ROLE` or system is locked.
- `Pausable: paused`: Contract is paused.

##### `external setBlacklistStatus(address user, bool status)`
**Description**: Updates the blacklist status for a single user. Restricted to `OPERATOR_ROLE`.
**Request**:
```json
{
  "user": "0xUserAddress",
  "status": true // true to blacklist, false to unblacklist
}
```
**Response**:
*   No explicit return value.
*   State changes: `isBlacklisted[user]` is updated.
**Events Emitted**: `BlacklistStatusChanged`
**Errors**:
- `InvalidAddress`: Provided zero address.
- `UnauthorizedOperation`: Caller does not have `OPERATOR_ROLE`, system is locked, or attempted to blacklist an admin role.
- `Pausable: paused`: Contract is paused.

##### `external batchUpdateBlacklist(address[] calldata users, bool[] calldata statuses)`
**Description**: Updates the blacklist status for multiple users in a single transaction. Restricted to `OPERATOR_ROLE`.
**Request**:
```json
{
  "users": ["0xUser1Address", "0xUser2Address"],
  "statuses": [true, false]
}
```
**Response**:
*   No explicit return value.
*   State changes: `isBlacklisted` for each user is updated.
**Events Emitted**: `BlacklistStatusChanged` for each user.
**Errors**:
- `InvalidRoleConfiguration`: Array lengths of `users` and `statuses` do not match.
- `InvalidAddress`: Provided zero address in `users` array.
- `UnauthorizedOperation`: Caller does not have `OPERATOR_ROLE`, system is locked, or attempted to blacklist an admin role.
- `Pausable: paused`: Contract is paused.

##### `external scheduleAdminChange(address newAdmin, bool isSuperAdmin)`
**Description**: Schedules a timelocked change for either the `superAdmin` (`DEFAULT_ADMIN_ROLE`) or `pasarAdmin` (`ADMIN_ROLE`) address. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**:
```json
{
  "newAdmin": "0xNewAdminAddress",
  "isSuperAdmin": true // true for superAdmin, false for pasarAdmin
}
```
**Response**:
*   No explicit return value.
*   State changes: A `PendingAdminChange` struct is stored, associated with a unique `operationId`.
**Events Emitted**: `AdminChangeScheduled`
**Errors**:
- `InvalidAddress`: Provided zero address for `newAdmin`.
- `UnauthorizedOperation`: Caller does not have `DEFAULT_ADMIN_ROLE` or system is locked.
- `Pausable: paused`: Contract is paused.

##### `external executeAdminChange(bytes32 operationId)`
**Description**: Executes a previously scheduled admin change after its timelock has passed. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**:
```json
{
  "operationId": "0xUniqueOperationId" // bytes32 identifier from AdminChangeScheduled event
}
```
**Response**:
*   No explicit return value.
*   State changes: Old admin role revoked, new admin role granted, `superAdmin` or `pasarAdmin` state variable updated.
**Events Emitted**: `RoleAssigned`
**Errors**:
- `UnauthorizedOperation`: Operation does not exist or timelock has not passed.
- `Pausable: paused`: Contract is paused.

##### `external emergencyShutdown()`
**Description**: Initiates an emergency shutdown, locking core system functions and pausing the contract. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**: No parameters.
**Response**:
*   No explicit return value.
*   State changes: `systemLocked` set to `true`, contract paused.
**Events Emitted**: `EmergencyShutdown`
**Errors**:
- `AccessControl: sender is not DEFAULT_ADMIN_ROLE`: Caller does not have `DEFAULT_ADMIN_ROLE`.

##### `external restoreSystem()`
**Description**: Restores core system functions and unpauses the contract after an emergency shutdown. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**: No parameters.
**Response**:
*   No explicit return value.
*   State changes: `systemLocked` set to `false`, contract unpaused.
**Events Emitted**: `SystemRestored`
**Errors**:
- `AccessControl: sender is not DEFAULT_ADMIN_ROLE`: Caller does not have `DEFAULT_ADMIN_ROLE`.

##### `external pause()`
**Description**: Pauses the contract, preventing calls to functions protected by `whenNotPaused`. Restricted to `DEFAULT_ADMIN_ROLE` and callable only when the system is active.
**Request**: No parameters.
**Response**:
*   No explicit return value.
*   State changes: Contract paused.
**Events Emitted**: `Paused` (from PausableUpgradeable)
**Errors**:
- `AccessControl: sender is not DEFAULT_ADMIN_ROLE`: Caller does not have `DEFAULT_ADMIN_ROLE`.
- `UnauthorizedOperation`: System is in an emergency locked state.

##### `external unpause()`
**Description**: Unpauses the contract, allowing calls to functions protected by `whenNotPaused`. Restricted to `DEFAULT_ADMIN_ROLE` and callable only when the system is active.
**Request**: No parameters.
**Response**:
*   No explicit return value.
*   State changes: Contract unpaused.
**Events Emitted**: `Unpaused` (from PausableUpgradeable)
**Errors**:
- `AccessControl: sender is not DEFAULT_ADMIN_ROLE`: Caller does not have `DEFAULT_ADMIN_ROLE`.
- `UnauthorizedOperation`: System is in an emergency locked state.

##### `external view isOperator(address account) returns (bool)`
**Description**: Checks if an address has the `OPERATOR_ROLE`.
**Request**:
```json
{
  "account": "0xAccountAddress"
}
```
**Response**:
```json
{
  "isOperator": true // or false
}
```

##### `external view getAccountRoles(address account) returns (bytes32[] memory)`
**Description**: Retrieves all roles (excluding `DEFAULT_ADMIN_ROLE` if not explicitly granted) assigned to an address.
**Request**:
```json
{
  "account": "0xAccountAddress"
}
```
**Response**:
```json
{
  "roles": ["0x..." /* ADMIN_ROLE hash */, "0x..." /* OPERATOR_ROLE hash */]
}
```

##### `public view isAdminChangeReady(bytes32 operationId) returns (bool ready)`
**Description**: Checks if a scheduled admin change operation is ready for execution (timelock passed).
**Request**:
```json
{
  "operationId": "0xUniqueOperationId"
}
```
**Response**:
```json
{
  "ready": true // or false
}
```

##### `external cancelAdminChange(bytes32 operationId)`
**Description**: Cancels a pending admin change operation. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**:
```json
{
  "operationId": "0xUniqueOperationId"
}
```
**Response**:
*   No explicit return value.
*   State changes: `PendingAdminChange` struct for `operationId` is deleted.
**Events Emitted**: `AdminChangeScheduled` (with scheduleTime 0 to signify cancellation).
**Errors**:
- `UnauthorizedOperation`: Caller does not have `DEFAULT_ADMIN_ROLE`, system is locked, contract is paused, or operation ID is invalid.

##### `external virtual resolveDispute(uint256 disputeId, address winner)`
**Description**: Placeholder virtual function for dispute resolution. Intended to be overridden by a derived contract. Restricted to `DISPUTE_MANAGER_ROLE`.
**Request**:
```json
{
  "disputeId": 123,
  "winner": "0xWinnerAddress"
}
```
**Response**:
*   No explicit return value (implementation in derived contract).
**Errors**:
- `InvalidAddress`: Provided zero address for `winner`.
- `AccessControl: sender is not DISPUTE_MANAGER_ROLE`: Caller does not have `DISPUTE_MANAGER_ROLE`.
- `Pausable: paused`: Contract is paused.

##### `external virtual managePlatformService(bytes32 serviceId, bool enable)`
**Description**: Placeholder virtual function for managing platform services. Intended to be overridden by a derived contract. Restricted to `PLATFORM_SERVICE_ROLE`.
**Request**:
```json
{
  "serviceId": "0x" + keccak256("SOME_SERVICE_ID").toString("hex"),
  "enable": true // or false
}
```
**Response**:
*   No explicit return value (implementation in derived contract).
**Errors**:
- `AccessControl: sender is not PLATFORM_SERVICE_ROLE`: Caller does not have `PLATFORM_SERVICE_ROLE`.
- `Pausable: paused`: Contract is paused.

##### Errors:
- `InvalidAddress`: A zero address was provided where a valid address is required.
- `UserBlacklisted`: An action was attempted by a blacklisted user.
- `InvalidRoleConfiguration`: Inconsistency in role configuration, e.g., mismatched array lengths.
- `SystemFlagNotFound`: An attempt was made to set an unrecognized system flag.
- `UnauthorizedOperation`: An unauthorized address attempted a restricted operation.
- `BatchOperationFailed`: A batch operation failed at a specific index. (Note: this custom error is defined but not explicitly thrown in the provided `batchUpdateBlacklist` implementation if an item fails validation, it reverts the whole transaction with `InvalidAddress` or `UnauthorizedOperation`).

#### PayNodeAdmin API

The `PayNodeAdmin` contract is a timelock controller for managing contract upgrades and critical role changes, integrated with Chainlink Automation.

##### `public constant ADMIN_ROLE`
Role identifier for authorized upgrade admins.

##### `public constant MIN_DELAY`
Minimum delay of 2 days before an upgrade or role change can be executed.

##### `public constant UPKEEP_COOLDOWN`
Cooldown period of 1 hour between Chainlink Automation upkeep calls.

##### `constructor(address[] memory proposers, address[] memory executors, address superAdmin, address upgradeAdmin, address _chainlinkKeeper)`
**Description**: Initializes the contract with timelock parameters, initial roles, and Chainlink Keeper address.
**Request**:
```json
{
  "proposers": ["0xProposerAddress"],
  "executors": ["0xExecutorAddress"],
  "superAdmin": "0xSuperAdminAddress",
  "upgradeAdmin": "0xUpgradeAdminAddress",
  "_chainlinkKeeper": "0xChainlinkKeeperAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: `chainlinkKeeper`, `ADMIN_ROLE`, `DEFAULT_ADMIN_ROLE` are set.
**Errors**:
- `InvalidAddress`: Provided zero address for `_chainlinkKeeper`.

##### `external scheduleUpgrade(address target, address newImplementation)`
**Description**: Schedules an upgrade for a proxy contract with a timelock delay. Restricted to `ADMIN_ROLE`.
**Request**:
```json
{
  "target": "0xProxyContractAddress",
  "newImplementation": "0xNewImplementationAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: `pendingUpgrades` is updated, `upgradeQueue` is updated.
**Events Emitted**: `UpgradeScheduled`
**Errors**:
- `InvalidAddress`: Provided zero address for `target` or `newImplementation`.
- `UpgradeAlreadyPending`: An upgrade is already scheduled for the `target` proxy.
- `AccessControl: sender is not ADMIN_ROLE`: Caller does not have `ADMIN_ROLE`.
- `Pausable: paused`: Contract is paused.

##### `external cancelUpgrade(address target)`
**Description**: Cancels a scheduled upgrade for a proxy contract. Restricted to `ADMIN_ROLE`.
**Request**:
```json
{
  "target": "0xProxyContractAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: `pendingUpgrades` is updated, `upgradeQueue` is updated.
**Events Emitted**: `UpgradeCancelled`
**Errors**:
- `NoUpgradePending`: No upgrade is pending for the `target` proxy.
- `AccessControl: sender is not ADMIN_ROLE`: Caller does not have `ADMIN_ROLE`.
- `Pausable: paused`: Contract is paused.

##### `external performUpgrade(address target)`
**Description**: Manually executes a scheduled upgrade for a proxy contract after its timelock has passed. Restricted to `ADMIN_ROLE`.
**Request**:
```json
{
  "target": "0xProxyContractAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: Proxy's implementation is updated.
**Events Emitted**: `UpgradeExecuted`
**Errors**:
- `NoUpgradePending`: No upgrade is pending for the `target` proxy.
- `UpgradeTooEarly`: The timelock period has not yet passed.
- `UpgradeFailed`: Low-level call to `upgradeTo` failed.
- `AccessControl: sender is not ADMIN_ROLE`: Caller does not have `ADMIN_ROLE`.
- `Pausable: paused`: Contract is paused.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.

##### `external view checkUpkeep(bytes calldata /* checkData */) returns (bool upkeepNeeded, bytes memory performData)`
**Description**: Chainlink Automation compatible function to check if any pending upgrade is ready for execution.
**Request**:
```json
{
  "checkData": "0x" // Not used, can be empty
}
```
**Response**:
```json
{
  "upkeepNeeded": true, // or false
  "performData": "0xEncodedTargetAddress" // or "" if no upkeep needed
}
```

##### `external performUpkeep(bytes calldata performData)`
**Description**: Executes an upgrade via Chainlink Automation. Restricted to the configured `chainlinkKeeper` address.
**Request**:
```json
{
  "performData": "0xEncodedTargetAddress" // Encoded target address from checkUpkeep
}
```
**Response**:
*   No explicit return value.
*   State changes: Proxy's implementation is updated, `lastUpkeepTime` updated.
**Events Emitted**: `UpkeepPerformed`, `UpgradeExecuted`
**Errors**:
- `OnlyChainlinkKeeper`: Caller is not the authorized Chainlink Keeper.
- `UpkeepCooldownActive`: Cooldown period since last upkeep has not elapsed.
- `NoUpgradePending`: No upgrade is pending for the decoded `target` address.
- `UpgradeTooEarly`: The timelock period has not yet passed.
- `UpgradeFailed`: Low-level call to `upgradeTo` failed.
- `Pausable: paused`: Contract is paused.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.

##### `external scheduleRoleChange(address account, bytes32 role, bool grant)`
**Description**: Schedules a role assignment or revocation with a timelock delay. Restricted to `ADMIN_ROLE`.
**Request**:
```json
{
  "account": "0xAccountAddress",
  "role": "0x" + keccak256("ADMIN_ROLE").toString("hex"), // or other role hashes
  "grant": true // true to grant, false to revoke
}
```
**Response**:
*   No explicit return value.
*   State changes: A `PendingRoleChange` struct is stored, associated with a unique `operationId`.
**Events Emitted**: `RoleChangeScheduled`
**Errors**:
- `InvalidAddress`: Provided zero address for `account`.
- `AccessControl: sender is not ADMIN_ROLE`: Caller does not have `ADMIN_ROLE`.
- `Pausable: paused`: Contract is paused.

##### `external executeRoleChange(bytes32 operationId)`
**Description**: Executes a pending role change after the timelock period. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**:
```json
{
  "operationId": "0xUniqueOperationId" // bytes32 identifier from RoleChangeScheduled event
}
```
**Response**:
*   No explicit return value.
*   State changes: Role is granted or revoked.
**Events Emitted**: `RoleChangeExecuted`
**Errors**:
- `RoleChangeNotReady`: Operation does not exist or timelock has not passed.
- `AccessControl: sender is not DEFAULT_ADMIN_ROLE`: Caller does not have `DEFAULT_ADMIN_ROLE`.
- `Pausable: paused`: Contract is paused.

##### `public view isRoleChangeReady(bytes32 operationId) returns (bool ready)`
**Description**: Checks if a scheduled role change operation is ready for execution.
**Request**:
```json
{
  "operationId": "0xUniqueOperationId"
}
```
**Response**:
```json
{
  "ready": true // or false
}
```

##### `external cancelRoleChange(bytes32 operationId)`
**Description**: Cancels a pending role change operation. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**:
```json
{
  "operationId": "0xUniqueOperationId"
}
```
**Response**:
*   No explicit return value.
*   State changes: `PendingRoleChange` struct for `operationId` is deleted.
**Events Emitted**: `RoleChangeScheduled` (with scheduleTime 0 to signify cancellation).
**Errors**:
- `RoleChangeNotReady`: Operation does not exist.
- `AccessControl: sender is not DEFAULT_ADMIN_ROLE`: Caller does not have `DEFAULT_ADMIN_ROLE`.
- `Pausable: paused`: Contract is paused.

##### `external pause()`
**Description**: Pauses the contract, halting critical operations. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**: No parameters.
**Response**:
*   No explicit return value.
*   State changes: Contract paused.
**Events Emitted**: `Paused` (from Pausable)
**Errors**:
- `AccessControl: sender is not DEFAULT_ADMIN_ROLE`: Caller does not have `DEFAULT_ADMIN_ROLE`.

##### `external unpause()`
**Description**: Unpauses the contract, resuming operations. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**: No parameters.
**Response**:
*   No explicit return value.
*   State changes: Contract unpaused.
**Events Emitted**: `Unpaused` (from Pausable)
**Errors**:
- `AccessControl: sender is not DEFAULT_ADMIN_ROLE`: Caller does not have `DEFAULT_ADMIN_ROLE`.

##### `external view getUpgradeQueue() returns (address[] memory)`
**Description**: Returns the list of proxy contracts with currently pending upgrades in the queue.
**Request**: No parameters.
**Response**:
```json
{
  "upgradeQueue": ["0xProxy1Address", "0xProxy2Address"]
}
```

##### Errors:
- `InvalidAddress`: A zero address was provided.
- `UpgradeAlreadyPending`: An upgrade is already pending for the target contract.
- `NoUpgradePending`: No upgrade is pending for the target contract.
- `UpgradeTooEarly`: The timelock for the upgrade has not expired.
- `UpgradeFailed`: The low-level call to upgrade the proxy failed.
- `OnlyChainlinkKeeper`: The caller is not the authorized Chainlink Keeper.
- `UpkeepCooldownActive`: The cooldown period for `performUpkeep` has not elapsed.
- `RoleChangeNotReady`: The specified role change operation does not exist or its timelock has not expired.
- `UnauthorizedOperation`: An operation was attempted without proper authorization (e.g., trying to modify a role without `DEFAULT_ADMIN_ROLE`).

#### PGateway API

The `PGateway` contract is the core logic for managing payment orders, provider intents, and settlement execution.

##### `enum OrderTier { SMALL, MEDIUM, LARGE }`
Defines order size categories.

##### `enum OrderStatus { PENDING, PROPOSED, ACCEPTED, FULFILLED, REFUNDED, CANCELLED }`
Defines the lifecycle status of an order.

##### `enum ProposalStatus { PENDING, ACCEPTED, REJECTED, TIMEOUT, CANCELLED }`
Defines the lifecycle status of a settlement proposal.

##### `public MAX_BPS`
Constant representing 100% in basis points (100,000).

##### `public SMALL_TIER_LIMIT`
Amount threshold for `SMALL` orders (5,000 * 10^18 units).

##### `public MEDIUM_TIER_LIMIT`
Amount threshold for `MEDIUM` orders (20,000 * 10^18 units).

##### `public protocolFeePercent`
Current protocol fee percentage in basis points (e.g., 500 for 0.5%).

##### `public orderExpiryWindow`
Duration after which an order expires if not fulfilled (default 1 hour).

##### `public proposalTimeout`
Duration within which a provider must accept a proposal (default 30 seconds).

##### `public treasuryAddress`
Address designated to receive protocol fees.

##### `public aggregatorAddress`
Address authorized to act as the off-chain aggregator.

##### `external initialize(address _treasuryAddress, address _aggregatorAddress)`
**Description**: Initializes the contract with the treasury and aggregator addresses.
**Request**:
```json
{
  "_treasuryAddress": "0xProtocolTreasuryAddress",
  "_aggregatorAddress": "0xAggregatorServiceAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: `treasuryAddress`, `aggregatorAddress` are set.
**Errors**:
- `InvalidTreasuryAddress`: Provided zero address for `_treasuryAddress`.
- `InvalidAggregatorAddress`: Provided zero address for `_aggregatorAddress`.

##### `external pause()`
**Description**: Pauses the contract, halting critical operations. Restricted to `onlyOwner`.
**Request**: No parameters.
**Response**:
*   No explicit return value.
*   State changes: Contract paused.
**Events Emitted**: `Paused` (from PausableUpgradeable)
**Errors**:
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external unpause()`
**Description**: Unpauses the contract, resuming operations. Restricted to `onlyOwner`.
**Request**: No parameters.
**Response**:
*   No explicit return value.
*   State changes: Contract unpaused.
**Events Emitted**: `Unpaused` (from PausableUpgradeable)
**Errors**:
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external setSupportedToken(address _token, bool _supported)`
**Description**: Whitelists or unwhitelists an ERC20 token for use in the protocol. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_token": "0xERC20TokenAddress",
  "_supported": true // true to support, false to remove support
}
```
**Response**:
*   No explicit return value.
*   State changes: `supportedTokens[_token]` is updated.
**Errors**:
- `InvalidToken`: Provided zero address for `_token`.
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external setTreasuryAddress(address _newTreasury)`
**Description**: Updates the address designated to receive protocol fees. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_newTreasury": "0xNewTreasuryAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: `treasuryAddress` is updated.
**Errors**:
- `InvalidAddress`: Provided zero address for `_newTreasury`.
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external setAggregatorAddress(address _newAggregator)`
**Description**: Updates the address authorized to act as the off-chain aggregator. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_newAggregator": "0xNewAggregatorAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: `aggregatorAddress` is updated.
**Errors**:
- `InvalidAddress`: Provided zero address for `_newAggregator`.
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external setProtocolFee(uint64 _newFee)`
**Description**: Sets the protocol fee percentage in basis points. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_newFee": 500 // 0.5% (Max 5000 for 5%)
}
```
**Response**:
*   No explicit return value.
*   State changes: `protocolFeePercent` is updated.
**Events Emitted**: No specific event for this function is defined, though a general `ProtocolFeeUpdated` event is listed in `architecture.md`.
**Errors**:
- `FeeTooHigh`: Provided fee exceeds the maximum allowed (5%).
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external setTierLimits(uint256 _smallLimit, uint256 _mediumLimit)`
**Description**: Sets the amount thresholds for `SMALL` and `MEDIUM` order tiers. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_smallLimit": "5000000000000000000000", // e.g., 5000 units in wei
  "_mediumLimit": "20000000000000000000000" // e.g., 20000 units in wei
}
```
**Response**:
*   No explicit return value.
*   State changes: `SMALL_TIER_LIMIT`, `MEDIUM_TIER_LIMIT` are updated.
**Events Emitted**: No specific event for this function is defined, though a general `TierLimitsUpdated` event is listed in `architecture.md`.
**Errors**:
- `InvalidLimits`: Provided invalid limits (e.g., `_smallLimit` is zero or `_mediumLimit` is not greater than `_smallLimit`).
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external setOrderExpiryWindow(uint256 _newWindow)`
**Description**: Sets the duration after which an order expires if not fulfilled. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_newWindow": 3600 // 1 hour in seconds
}
```
**Response**:
*   No explicit return value.
*   State changes: `orderExpiryWindow` is updated.
**Errors**:
- `InvalidWindow`: Provided zero for `_newWindow`.
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external setProposalTimeout(uint256 _newTimeout)`
**Description**: Sets the duration within which a provider must accept a proposal. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_newTimeout": 30 // 30 seconds
}
```
**Response**:
*   No explicit return value.
*   State changes: `proposalTimeout` is updated.
**Errors**:
- `InvalidTimeout`: Provided zero for `_newTimeout`.
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external registerIntent(string calldata _currency, uint256 _availableAmount, uint64 _minFeeBps, uint64 _maxFeeBps, uint256 _commitmentWindow)`
**Description**: Registers or updates a provider's intent to fulfill orders, specifying available capacity and fee preferences.
**Request**:
```json
{
  "_currency": "USD",
  "_availableAmount": "100000000000000000000", // e.g., 100 units in wei
  "_minFeeBps": 100, // 0.1%
  "_maxFeeBps": 500, // 0.5%
  "_commitmentWindow": 600 // 10 minutes in seconds
}
```
**Response**:
*   No explicit return value.
*   State changes: `providerIntents` for `msg.sender` is created/updated, `registeredProviders` array potentially updated.
**Events Emitted**: `IntentRegistered`
**Errors**:
- `InvalidAmount`: Provided zero for `_availableAmount`.
- `InvalidFees`: `_minFeeBps` is greater than `_maxFeeBps` or `_maxFeeBps` exceeds 10,000 (10%).
- `InvalidCommitmentWindow`: Provided zero for `_commitmentWindow`.
- `ProviderBlacklisted`: The provider is blacklisted.
- `Pausable: paused`: Contract is paused.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.

##### `external updateIntent(string calldata _currency, uint256 _newAmount)`
**Description**: Updates the available amount and extends the expiry for an existing provider intent. Restricted to `onlyProvider`.
**Request**:
```json
{
  "_currency": "USD",
  "_newAmount": "150000000000000000000" // e.g., 150 units in wei
}
```
**Response**:
*   No explicit return value.
*   State changes: `providerIntents[msg.sender].availableAmount`, `registeredAt`, `expiresAt` are updated.
**Events Emitted**: `IntentUpdated`
**Errors**:
- `NotRegisteredProvider`: Caller is not a registered provider.
- `NoActiveIntent`: Provider does not have an active intent.
- `InvalidAmount`: Provided zero for `_newAmount`.
- `Pausable: paused`: Contract is paused.

##### `external expireIntent(address _provider)`
**Description**: Marks a provider's intent as inactive if its expiry time has passed. Restricted to `onlyAggregator`.
**Request**:
```json
{
  "_provider": "0xProviderAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: `providerIntents[_provider].isActive` is set to `false`.
**Events Emitted**: `IntentExpired`
**Errors**:
- `OnlyAggregator`: Caller is not the aggregator.
- `IntentNotActive`: Provider intent is not active.
- `IntentNotExpired`: The intent's expiry time has not yet passed.

##### `external reserveIntent(address _provider, uint256 _amount)`
**Description**: Reserves a specified amount from a provider's available capacity when a proposal is sent. Restricted to `onlyAggregator`.
**Request**:
```json
{
  "_provider": "0xProviderAddress",
  "_amount": "50000000000000000000" // e.g., 50 units in wei
}
```
**Response**:
*   No explicit return value.
*   State changes: `providerIntents[_provider].availableAmount` is decreased.
**Errors**:
- `OnlyAggregator`: Caller is not the aggregator.
- `IntentNotActive`: Provider intent is not active.
- `InsufficientCapacity`: Provider's available amount is less than the requested `_amount`.

##### `external releaseIntent(address _provider, uint256 _amount, string calldata _reason)`
**Description**: Releases a previously reserved amount back to a provider's available capacity (e.g., if a proposal is rejected or times out). Restricted to `onlyAggregator`.
**Request**:
```json
{
  "_provider": "0xProviderAddress",
  "_amount": "50000000000000000000", // e.g., 50 units in wei
  "_reason": "Proposal Rejected"
}
```
**Response**:
*   No explicit return value.
*   State changes: `providerIntents[_provider].availableAmount` is increased.
**Events Emitted**: `IntentReleased`
**Errors**:
- `OnlyAggregator`: Caller is not the aggregator.

##### `external view getProviderIntent(address _provider) returns (ProviderIntent memory)`
**Description**: Retrieves the active intent details for a given provider.
**Request**:
```json
{
  "_provider": "0xProviderAddress"
}
```
**Response**:
```json
{
  "provider": "0xProviderAddress",
  "currency": "USD",
  "availableAmount": "100000000000000000000",
  "minFeeBps": 100,
  "maxFeeBps": 500,
  "registeredAt": 1678886400,
  "expiresAt": 1678886700,
  "commitmentWindow": 600,
  "isActive": true
}
```

##### `external createOrder(address _token, uint256 _amount, address _refundAddress) returns (bytes32 orderId)`
**Description**: Creates a new order, transfers tokens from the user to the contract, and generates a unique `orderId`.
**Request**:
```json
{
  "_token": "0xERC20TokenAddress",
  "_amount": "1000000000000000000", // e.g., 1 ETH/ERC20 unit in wei
  "_refundAddress": "0xUserRefundAddress"
}
```
**Response**:
```json
{
  "orderId": "0xUniqueOrderId"
}
```
**Events Emitted**: `OrderCreated`
**Errors**:
- `InvalidAmount`: Provided zero for `_amount`.
- `InvalidRefundAddress`: Provided zero address for `_refundAddress`.
- `TokenNotSupported`: The specified token is not whitelisted.
- `Pausable: paused`: Contract is paused.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.
- `ERC20: transferFrom failed`: Token transfer failed (e.g., insufficient allowance or balance).

##### `external view getOrder(bytes32 _orderId) returns (Order memory)`
**Description**: Retrieves details for a specific order.
**Request**:
```json
{
  "_orderId": "0xUniqueOrderId"
}
```
**Response**:
```json
{
  "orderId": "0xUniqueOrderId",
  "user": "0xUserAddress",
  "token": "0xERC20TokenAddress",
  "amount": "1000000000000000000",
  "tier": 0, // SMALL (0), MEDIUM (1), LARGE (2)
  "status": 0, // PENDING (0), PROPOSED (1), ACCEPTED (2), FULFILLED (3), REFUNDED (4), CANCELLED (5)
  "refundAddress": "0xUserRefundAddress",
  "createdAt": 1678886400,
  "expiresAt": 1678890000,
  "acceptedProposalId": "0xAcceptedProposalId", // 0x0 if not accepted
  "fulfilledByProvider": "0xProviderAddress" // 0x0 if not fulfilled
}
```
**Errors**:
- `OrderNotFound`: Provided `_orderId` does not correspond to an existing order.

##### `external createProposal(bytes32 _orderId, address _provider, uint64 _proposedFeeBps) returns (bytes32 proposalId)`
**Description**: Creates a settlement proposal for a given order from a specific provider. Restricted to `onlyAggregator`.
**Request**:
```json
{
  "_orderId": "0xUniqueOrderId",
  "_provider": "0xProviderAddress",
  "_proposedFeeBps": 200 // 0.2%
}
```
**Response**:
```json
{
  "proposalId": "0xUniqueProposalId"
}
```
**Events Emitted**: `SettlementProposalCreated`
**Errors**:
- `OnlyAggregator`: Caller is not the aggregator.
- `OrderNotFound`: Provided `_orderId` does not correspond to an existing order.
- `OrderNotPending`: Order is not in `PENDING` status.
- `OrderExpired`: Order's expiry time has passed.
- `ProviderIntentNotActive`: Provider does not have an active intent.
- `InsufficientCapacity`: Provider's available capacity is less than the order amount.
- `InvalidFee`: Proposed fee is outside the provider's registered `minFeeBps` and `maxFeeBps`.

##### `external acceptProposal(bytes32 _proposalId)`
**Description**: A provider accepts a settlement proposal, marking the order as `ACCEPTED`. Restricted to `onlyProvider`.
**Request**:
```json
{
  "_proposalId": "0xUniqueProposalId"
}
```
**Response**:
*   No explicit return value.
*   State changes: `proposals[_proposalId].status` set to `ACCEPTED`, `orders[proposal.orderId].status` set to `ACCEPTED`, `orders[proposal.orderId].acceptedProposalId`, `orders[proposal.orderId].fulfilledByProvider` are set.
**Events Emitted**: `SettlementProposalAccepted`
**Errors**:
- `NotProposalProvider`: Caller is not the provider associated with the proposal.
- `ProposalNotPending`: Proposal is not in `PENDING` status.
- `ProposalExpired`: Proposal's deadline has passed.
- `Pausable: paused`: Contract is paused.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.

##### `external rejectProposal(bytes32 _proposalId, string calldata _reason)`
**Description**: A provider rejects a settlement proposal. Restricted to `onlyProvider`.
**Request**:
```json
{
  "_proposalId": "0xUniqueProposalId",
  "_reason": "Capacity unavailable"
}
```
**Response**:
*   No explicit return value.
*   State changes: `proposals[_proposalId].status` set to `REJECTED`, `providerReputation[msg.sender].noShowCount` incremented.
**Events Emitted**: `SettlementProposalRejected`
**Errors**:
- `NotProposalProvider`: Caller is not the provider associated with the proposal.
- `ProposalNotPending`: Proposal is not in `PENDING` status.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.

##### `external timeoutProposal(bytes32 _proposalId)`
**Description**: Marks a proposal as `TIMEOUT` if its deadline has passed without acceptance. Restricted to `onlyAggregator`.
**Request**:
```json
{
  "_proposalId": "0xUniqueProposalId"
}
```
**Response**:
*   No explicit return value.
*   State changes: `proposals[_proposalId].status` set to `TIMEOUT`.
**Events Emitted**: `SettlementProposalTimeout`
**Errors**:
- `OnlyAggregator`: Caller is not the aggregator.
- `ProposalNotPending`: Proposal is not in `PENDING` status.
- `ProposalNotExpired`: Proposal's deadline has not yet passed.

##### `external view getProposal(bytes32 _proposalId) returns (SettlementProposal memory)`
**Description**: Retrieves details for a specific settlement proposal.
**Request**:
```json
{
  "_proposalId": "0xUniqueProposalId"
}
```
**Response**:
```json
{
  "proposalId": "0xUniqueProposalId",
  "orderId": "0xUniqueOrderId",
  "provider": "0xProviderAddress",
  "proposedAmount": "1000000000000000000",
  "proposedFeeBps": 200,
  "proposedAt": 1678886400,
  "proposalDeadline": 1678886430,
  "status": 1 // PENDING (0), ACCEPTED (1), REJECTED (2), TIMEOUT (3), CANCELLED (4)
}
```

##### `external executeSettlement(bytes32 _proposalId)`
**Description**: Executes the settlement of an `ACCEPTED` proposal, distributing funds to the provider and treasury. Restricted to `onlyAggregator`.
**Request**:
```json
{
  "_proposalId": "0xUniqueProposalId"
}
```
**Response**:
*   No explicit return value.
*   State changes: `proposalExecuted[_proposalId]` set to `true`, `orders[proposal.orderId].status` set to `FULFILLED`, `providerReputation` updated. ERC20 tokens are transferred to `treasuryAddress` and `proposal.provider`.
**Events Emitted**: `SettlementExecuted`, `ProviderReputationUpdated`
**Errors**:
- `OnlyAggregator`: Caller is not the aggregator.
- `ProposalNotAccepted`: Proposal is not in `ACCEPTED` status.
- `AlreadyExecuted`: Proposal has already been executed.
- `OrderNotAccepted`: Order is not in `ACCEPTED` status.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.
- `ERC20: transfer failed`: Token transfer to treasury or provider failed.

##### `external refundOrder(bytes32 _orderId)`
**Description**: Refunds an order if it has not been fulfilled and has expired. Restricted to `onlyAggregator`.
**Request**:
```json
{
  "_orderId": "0xUniqueOrderId"
}
```
**Response**:
*   No explicit return value.
*   State changes: `orders[_orderId].status` set to `REFUNDED`. ERC20 tokens are transferred to `order.refundAddress`.
**Events Emitted**: `OrderRefunded`
**Errors**:
- `OnlyAggregator`: Caller is not the aggregator.
- `OrderNotFound`: Provided `_orderId` does not correspond to an existing order.
- `OrderFulfilled`: Order has already been fulfilled.
- `AlreadyRefunded`: Order has already been refunded.
- `OrderNotExpired`: Order's expiry time has not passed.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.

##### `external requestRefund(bytes32 _orderId)`
**Description**: Allows the order creator to request a refund if the order has not been fulfilled and has expired.
**Request**:
```json
{
  "_orderId": "0xUniqueOrderId"
}
```
**Response**:
*   No explicit return value.
*   State changes: `orders[_orderId].status` set to `CANCELLED`. ERC20 tokens are transferred to `order.refundAddress`.
**Events Emitted**: `OrderRefunded`
**Errors**:
- `OrderNotFound`: Provided `_orderId` does not correspond to an existing order.
- `NotOrderCreator`: Caller is not the creator of the order.
- `CannotRefund`: Order is in a status that cannot be refunded (e.g., `ACCEPTED` or `FULFILLED`).
- `OrderNotExpired`: Order's expiry time has not passed.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.

##### `external flagFraudulent(address _provider)`
**Description**: Flags a provider as fraudulent, disabling their intent. Restricted to `onlyAggregator`.
**Request**:
```json
{
  "_provider": "0xProviderAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: `providerReputation[_provider].isFraudulent` set to `true`, `providerIntents[_provider].isActive` set to `false`.
**Events Emitted**: `ProviderFraudFlagged`
**Errors**:
- `OnlyAggregator`: Caller is not the aggregator.
- `ProviderNotFound`: Provided `_provider` address is not a registered provider.

##### `external blacklistProvider(address _provider, string calldata _reason)`
**Description**: Blacklists a provider, disabling their intent. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_provider": "0xProviderAddress",
  "_reason": "Repeated malicious behavior"
}
}
```
**Response**:
*   No explicit return value.
*   State changes: `providerReputation[_provider].isBlacklisted` set to `true`, `providerIntents[_provider].isActive` set to `false`.
**Events Emitted**: `ProviderBlacklisted`
**Errors**:
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.

##### `external view getProviderReputation(address _provider) returns (ProviderReputation memory)`
**Description**: Retrieves the reputation metrics for a specific provider.
**Request**:
```json
{
  "_provider": "0xProviderAddress"
}
```
**Response**:
```json
{
  "provider": "0xProviderAddress",
  "totalOrders": 10,
  "successfulOrders": 8,
  "failedOrders": 2,
  "noShowCount": 1,
  "totalSettlementTime": 3600,
  "lastUpdated": 1678886400,
  "isFraudulent": false,
  "isBlacklisted": false
}
```

##### `external view getRegisteredProviders() returns (address[] memory)`
**Description**: Returns a list of all currently registered provider addresses.
**Request**: No parameters.
**Response**:
```json
{
  "providers": ["0xProvider1Address", "0xProvider2Address"]
}
```

##### `external view getActiveOrders() returns (bytes32[] memory)`
**Description**: Returns a list of all currently active order IDs.
**Request**: No parameters.
**Response**:
```json
{
  "orderIds": ["0xOrderId1", "0xOrderId2"]
}
```

##### `external view getUserNonce(address _user) returns (uint256)`
**Description**: Retrieves the nonce for a given user, used for generating unique order IDs.
**Request**:
```json
{
  "_user": "0xUserAddress"
}
```
**Response**:
```json
{
  "nonce": 5
}
```

##### `external emergencyWithdraw(address _token)`
**Description**: Allows the contract owner to withdraw any balance of a specified ERC20 token held by the contract to the treasury. Restricted to `onlyOwner`.
**Request**:
```json
{
  "_token": "0xERC20TokenAddress"
}
```
**Response**:
*   No explicit return value.
*   State changes: ERC20 token balance of the contract is transferred to `treasuryAddress`.
**Errors**:
- `Ownable2Step: caller is not the owner`: Caller is not the contract owner.
- `NoBalance`: No balance of the specified token is held by the contract.
- `ReentrancyGuard: reentrant call`: Reentrancy detected.

##### Errors:
- `InvalidTreasuryAddress`: Provided zero address for treasury during initialization.
- `InvalidAggregatorAddress`: Provided zero address for aggregator during initialization.
- `InvalidToken`: Provided zero address for a token.
- `InvalidAddress`: A zero address was provided.
- `FeeTooHigh`: Protocol fee exceeds 5% or provider's `maxFeeBps` exceeds 10%.
- `InvalidLimits`: Invalid tier limits provided (`_smallLimit` is zero or `_mediumLimit` not greater than `_smallLimit`).
- `InvalidWindow`: Order expiry window is zero.
- `InvalidTimeout`: Proposal timeout is zero.
- `InvalidAmount`: Amount is zero where a positive amount is required.
- `InvalidFees`: Provider's `minFeeBps` is greater than `maxFeeBps`.
- `InvalidCommitmentWindow`: Provider's commitment window is zero.
- `ProviderBlacklisted`: The provider is blacklisted.
- `NotRegisteredProvider`: Caller is not a registered provider.
- `NoActiveIntent`: Provider has no active intent.
- `IntentNotActive`: Provider intent is not active.
- `IntentNotExpired`: Provider intent or order has not expired.
- `InsufficientCapacity`: Provider's available capacity is insufficient.
- `OrderNotFound`: The specified order ID does not exist.
- `InvalidRefundAddress`: Provided zero address for refund address.
- `TokenNotSupported`: The specified ERC20 token is not supported.
- `OrderNotPending`: Order status is not `PENDING`.
- `OrderExpired`: Order's expiry time has passed.
- `ProviderIntentNotActive`: Provider's intent is not active.
- `InvalidFee`: Proposed fee is outside the provider's valid range.
- `NotProposalProvider`: Caller is not the provider associated with the proposal.
- `ProposalNotPending`: Proposal status is not `PENDING`.
- `ProposalExpired`: Proposal's deadline has passed.
- `OrderFulfilled`: Order has already been fulfilled.
- `AlreadyExecuted`: Proposal has already been executed.
- `OrderNotAccepted`: Order status is not `ACCEPTED`.
- `AlreadyRefunded`: Order has already been refunded.
- `NotOrderCreator`: Caller is not the creator of the order.
- `CannotRefund`: Order cannot be refunded in its current state.
- `ProviderNotFound`: The specified provider is not registered.
- `NoBalance`: Contract has no balance of the specified token for emergency withdrawal.

## Usage
The PayNode protocol is designed to be integrated into off-chain applications (e.g., web platforms, mobile apps) that interact with the smart contracts.

1.  **Deployment**:
    Deploy the contracts in the following order to your chosen EVM network:
    *   `PayNodeAccessManager` (Proxy-based UUPS upgradeable)
    *   `PayNodeAdmin` (Timelock Controller)
    *   `PGateway` (Implementation)
    *   `ERC1967Proxy` (Points to `PGateway` implementation)
    *   Call `initialize()` on the `PayNodeAccessManager` and `PGateway` proxy addresses with the required parameters.
    *   Transfer `DEFAULT_ADMIN_ROLE` from `PayNodeAccessManager` to `PayNodeAdmin`.
    *   Transfer ownership of the `PGateway` proxy to `PayNodeAdmin` (if applicable for upgrade control).

2.  **Configuration**:
    *   The contract owner (initially the deployer, then typically `PayNodeAdmin` or a designated governance address) must use `setSupportedToken` on `PGateway` to whitelist ERC20 tokens for use in orders.
    *   Configure `setProtocolFee`, `setTierLimits`, `setOrderExpiryWindow`, `setProposalTimeout` on `PGateway` as needed.

3.  **Provider Workflow**:
    *   Providers call `PGateway.registerIntent` to declare their capacity, supported currency, fee ranges, and commitment window.
    *   Providers can update their intent using `PGateway.updateIntent`.

4.  **User Workflow**:
    *   Users approve the `PGateway` contract to spend their ERC20 tokens for the order amount.
    *   Users call `PGateway.createOrder` with the token, amount, and a refund address. This transfers the tokens to the `PGateway` contract (escrow).

5.  **Aggregator Workflow (Off-chain Service)**:
    *   The off-chain aggregator monitors new orders (via `OrderCreated` events) and active provider intents.
    *   It calls `PGateway.createProposal` to send settlement proposals to suitable providers.
    *   It monitors `SettlementProposalAccepted`, `SettlementProposalRejected`, `SettlementProposalTimeout` events.
    *   Upon `SettlementProposalAccepted`, the aggregator calls `PGateway.executeSettlement` to finalize the transaction, transferring funds from escrow to the provider and protocol treasury.
    *   If orders or proposals expire without settlement, the aggregator can call `PGateway.refundOrder` to return funds to the user.

6.  **Admin/Operator Workflow**:
    *   Admins manage system flags (e.g., `TRADING_ENABLED`) and global pause/unpause state via `PayNodeAccessManager`.
    *   Operators manage the blacklist via `PayNodeAccessManager.setBlacklistStatus` or `batchUpdateBlacklist`.
    *   Admins schedule and execute contract upgrades and critical role changes via `PayNodeAdmin`, respecting timelocks.

## Technologies Used

| Technology         | Description                                                          | Link                                                       |
| :----------------- | :------------------------------------------------------------------- | :--------------------------------------------------------- |
| **Solidity**       | Smart contract programming language                                  | [Solidity](https://soliditylang.org/)                      |
| **Foundry**        | Ethereum development framework (Forge, Anvil, Chisel)                | [Foundry](https://getfoundry.sh/)                          |
| **OpenZeppelin**   | Library for secure smart contract development (upgradeable contracts, access control, pausable) | [OpenZeppelin](https://openzeppelin.com/contracts/)        |
| **Chainlink**      | Decentralized oracle network (Automation for automated upkeep)       | [Chainlink Automation](https://chain.link/automation)      |

## Contributing
Contributions to the PayNode protocol are welcome. Please follow these guidelines:

*   **Fork the repository** and clone it to your local machine.
*   **Create a new branch** for your feature or bug fix: `git checkout -b feature/your-feature-name`.
*   **Implement your changes**, ensuring that your code adheres to existing style guides.
*   **Write comprehensive tests** for your changes and ensure all existing tests pass: `forge test`.
*   **Open a Pull Request** (PR) to the `main` branch. Provide a clear and detailed description of your changes in the PR.
*   **Ensure CI/CD checks pass** before requesting a review.

## Author Info
*   **Olujimi**
    *   LinkedIn: [placeholder]
    *   Twitter: [placeholder]

---

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
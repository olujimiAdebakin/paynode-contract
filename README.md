# PayNode Protocol Smart Contracts 💳

## Overview
PayNode is a sophisticated non-custodial payment aggregation protocol built on the Ethereum Virtual Machine (EVM). It facilitates intelligent, parallel settlement routing for off-chain liquidity providers, ensuring efficient and secure transactions. This project leverages robust Solidity smart contracts, OpenZeppelin standards for security and upgradeability, and integrates Chainlink Automation for decentralized governance and autonomous operations.

## Features
- **Modular Architecture**: Designed with distinct layers for Access Control, Settings, and Core Gateway logic, enhancing maintainability and security.
- **Non-Custodial Escrow**: Funds are securely held in smart contract escrow until settlement, never directly by the protocol or providers.
- **Tier-Based Intelligent Routing**: Classifies orders into dynamic tiers (ALPHA, BETA, DELTA, OMEGA, TITAN) to optimize provider matching and settlement speed.
- **Parallel Settlement Proposals**: Enables multiple liquidity providers to simultaneously bid on settlement orders, promoting competition and faster execution.
- **UUPS Upgradeability**: Implements a secure Universal Upgradeable Proxy Standard (UUPS) pattern, allowing for future contract enhancements without migrating state.
- **Role-Based Access Control (RBAC)**: Granular permissions managed by `PayNodeAccessManager` ensures operations are restricted to authorized roles (Admin, Aggregator, Provider, Operator, Dispute Manager, Platform Service, Fee Manager).
- **Timelocked Governance**: Critical administrative changes and contract upgrades are subject to a 48-hour timelock via `PayNodeAdmin`, preventing hasty or malicious modifications.
- **Provider Reputation System**: Tracks provider performance (successful orders, settlement time, no-shows) to inform routing decisions and maintain service quality.
- **Integrator Self-Service**: Allows dApps and partners to register, set their own fees, and manage their integration directly.
- **Emergency Pause/Shutdown**: Provides a failsafe mechanism to halt critical contract operations during emergencies.
- **Replay Protection**: Utilizes user nonces and message hashes to secure off-chain signed actions and prevent double-spending.
- **Chainlink Automation Integration**: Automates the execution of timelocked upgrades and other routine maintenance tasks, ensuring reliability and decentralization.

## Getting Started

To get a local copy up and running, follow these steps.

### Installation
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/olujimiAdebakin/paynode-contract.git
    cd paynode-contract
    ```
2.  **Initialize Submodules**:
    This project uses Git submodules for external dependencies (OpenZeppelin, Foundry, Chainlink).
    ```bash
    git submodule update --init --recursive
    ```
3.  **Install Foundry**:
    If you don't have Foundry installed, follow the instructions [here](https://book.getfoundry.sh/getting-started/installation).
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```
4.  **Build Contracts**:
    Compile the Solidity smart contracts using Foundry.
    ```bash
    forge build
    ```

### Environment Variables
Before deployment or interaction, you will need to set up the following environment variables. Create a `.env` file in the project root and populate it with your specific values.

*   `RPC_URL`: Your Ethereum Virtual Machine (EVM) compatible blockchain node URL (e.g., Alchemy, Infura, local Anvil instance).
    *   Example: `RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY`
*   `PRIVATE_KEY`: The private key of the account used for deployment and transactions. **Handle with extreme care.**
    *   Example: `PRIVATE_KEY=0x...`
*   `ETHERSCAN_API_KEY`: (Optional) API key for block explorers (e.g., Etherscan, Polygonscan) for contract verification.
    *   Example: `ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY`
*   `DEPLOYER_ADDRESS`: The public address corresponding to your `PRIVATE_KEY`.
    *   Example: `DEPLOYER_ADDRESS=0xYourDeployerAddress`
*   `SUPER_ADMIN_ADDRESS`: The address designated as the initial `DEFAULT_ADMIN_ROLE` holder.
    *   Example: `SUPER_ADMIN_ADDRESS=0xYourSuperAdminAddress`
*   `AGGREGATOR_ADDRESS`: The address of the off-chain aggregator service (or a designated wallet).
    *   Example: `AGGREGATOR_ADDRESS=0xYourAggregatorServiceAddress`
*   `TREASURY_ADDRESS`: The address where protocol fees will be collected.
    *   Example: `TREASURY_ADDRESS=0xYourTreasuryWalletAddress`
*   `CHAINLINK_KEEPER_ADDRESS`: The address of the authorized Chainlink Keeper for automated tasks.
    *   Example: `CHAINLINK_KEEPER_ADDRESS=0xYourChainlinkKeeperAddress`
*   `PROTOCOL_FEE_BPS`: Initial protocol fee in basis points (e.g., `100` for 1%).
    *   Example: `PROTOCOL_FEE_BPS=100`
*   `ORDER_EXPIRY_WINDOW`: Default duration for order expiration in seconds.
    *   Example: `ORDER_EXPIRY_WINDOW=3600` (1 hour)
*   `PROPOSAL_TIMEOUT`: Default timeout for settlement proposals in seconds.
    *   Example: `PROPOSAL_TIMEOUT=300` (5 minutes)
*   `INTENT_EXPIRY`: Default expiration time for provider intents in seconds.
    *   Example: `INTENT_EXPIRY=600` (10 minutes)
*   `ALPHA_TIER_LIMIT`, `BETA_TIER_LIMIT`, `DELTA_TIER_LIMIT`, `OMEGA_TIER_LIMIT`, `TITAN_TIER_LIMIT`: Tier limits for order classification (in smallest unit of the token, e.g., wei for ETH).
    *   Example: `ALPHA_TIER_LIMIT=3000000000000000000000` (3000 tokens)
*   `INTEGRATOR_ADDRESS`: The default integrator address for initial setup.
    *   Example: `INTEGRATOR_ADDRESS=0xYourIntegratorAddress`
*   `INTEGRATOR_FEE_BPS`: The default integrator fee in basis points.
    *   Example: `INTEGRATOR_FEE_BPS=50` (0.5%)

## API Documentation

This section details the public interfaces and functions of the core PayNode smart contracts. All interactions are via blockchain transactions or view calls.

### PayNodeAccessManager Contract

**Overview**: The central contract for managing roles, blacklisting, and system-wide state flags. It implements UUPS upgradeability and integrates Pausable and ReentrancyGuard functionalities.

**Contract Address**: `[Deployed PayNodeAccessManager Address]`

#### Function Type: View Call `ADMIN_ROLE()`
**Description**: Returns the `bytes32` identifier for the `ADMIN_ROLE`.
**Request**: None
**Response**: `bytes32` - The role identifier.
**Errors**: None

#### Function Type: View Call `OPERATOR_ROLE()`
**Description**: Returns the `bytes32` identifier for the `OPERATOR_ROLE`.
**Request**: None
**Response**: `bytes32` - The role identifier.
**Errors**: None

#### Function Type: View Call `DISPUTE_MANAGER_ROLE()`
**Description**: Returns the `bytes32` identifier for the `DISPUTE_MANAGER_ROLE`.
**Request**: None
**Response**: `bytes32` - The role identifier.
**Errors**: None

#### Function Type: View Call `PLATFORM_SERVICE_ROLE()`
**Description**: Returns the `bytes32` identifier for the `PLATFORM_SERVICE_ROLE`.
**Request**: None
**Response**: `bytes32` - The role identifier.
**Errors**: None

#### Function Type: View Call `DEFAULT_ADMIN_ROLE()`
**Description**: Returns the `bytes32` identifier for the `DEFAULT_ADMIN_ROLE`.
**Request**: None
**Response**: `bytes32` - The role identifier.
**Errors**: None

#### Function Type: View Call `AGGREGATOR_ROLE()`
**Description**: Returns the `bytes32` identifier for the `AGGREGATOR_ROLE`.
**Request**: None
**Response**: `bytes32` - The role identifier.
**Errors**: None

#### Function Type: View Call `FEE_MANAGER_ROLE()`
**Description**: Returns the `bytes32` identifier for the `FEE_MANAGER_ROLE`.
**Request**: None
**Response**: `bytes32` - The role identifier.
**Errors**: None

#### Function Type: View Call `TRADING_ENABLED()`
**Description**: Returns the `bytes32` identifier for the `TRADING_ENABLED` system flag.
**Request**: None
**Response**: `bytes32` - The flag identifier.
**Errors**: None

#### Function Type: View Call `WITHDRAWALS_ENABLED()`
**Description**: Returns the `bytes32` identifier for the `WITHDRAWALS_ENABLED` system flag.
**Request**: None
**Response**: `bytes32` - The flag identifier.
**Errors**: None

#### Function Type: View Call `systemLocked()`
**Description**: Checks if the system is in an emergency locked state.
**Request**: None
**Response**: `bool` - True if locked, false otherwise.
**Errors**: None

#### Function Type: View Call `pasarAdmin()`
**Description**: Returns the address of the `PasarAdmin` contract (holder of `ADMIN_ROLE`).
**Request**: None
**Response**: `address` - The `PasarAdmin` contract address.
**Errors**: None

#### Function Type: View Call `superAdmin()`
**Description**: Returns the address of the `superAdmin` (holder of `DEFAULT_ADMIN_ROLE`).
**Request**: None
**Response**: `address` - The `superAdmin` address.
**Errors**: None

#### Function Type: View Call `MIN_DELAY()`
**Description**: Returns the minimum delay (in seconds) for timelocked operations.
**Request**: None
**Response**: `uint256` - Minimum delay in seconds.
**Errors**: None

#### Function Type: View Call `systemFlags(bytes32 flag)`
**Description**: Retrieves the status of a specific system flag.
**Request**:
```
bytes32 flag // E.g., keccak256("TRADING_ENABLED")
```
**Response**: `bool` - True if the flag is enabled, false otherwise.
**Errors**: None

#### Function Type: View Call `isBlacklisted(address user)`
**Description**: Checks if a given address is blacklisted.
**Request**:
```
address user // Address to check
```
**Response**: `bool` - True if blacklisted, false otherwise.
**Errors**: None

#### Function Type: Transaction `initialize(address _pasarAdmin, address _superAdmin, address[] calldata operators)`
**Description**: Initializes the `PayNodeAccessManager` contract, setting up initial roles and administrators. This function should only be called once, immediately after proxy deployment.
**Request**:
```
address _pasarAdmin     // Address of the PasarAdmin contract (for ADMIN_ROLE)
address _superAdmin     // Address for the DEFAULT_ADMIN_ROLE
address[] operators     // Array of addresses to receive OPERATOR_ROLE
```
**Response**: No direct return, emits `RoleAssigned` events.
**Errors**:
- `InvalidAddress`: If `_superAdmin`, `_pasarAdmin`, or any `operator` is `address(0)`.
- `InvalidRoleConfiguration`: If any `operator` is already a super admin or Pasar admin.

#### Function Type: Transaction `setSystemFlag(bytes32 flag, bool status)`
**Description**: Updates the status of a predefined system flag (e.g., `TRADING_ENABLED`, `WITHDRAWALS_ENABLED`).
**Request**:
```
bytes32 flag   // Identifier of the system flag
bool status    // New status (true for enabled, false for disabled)
```
**Response**: No direct return, emits `SystemFlagUpdated`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).
- `SystemFlagNotFound`: If `flag` is not `TRADING_ENABLED` or `WITHDRAWALS_ENABLED`.

#### Function Type: Transaction `setBlacklistStatus(address user, bool status)`
**Description**: Updates the blacklist status for a single user address.
**Request**:
```
address user   // Address to update
bool status    // New blacklist status (true to blacklist, false to unblacklist)
```
**Response**: No direct return, emits `BlacklistStatusChanged`.
**Errors**:
- `AccessControl: sender missing role` (OPERATOR_ROLE)
- `Pausable: paused`: If the contract is paused.
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).
- `InvalidAddress`: If `user` is `address(0)`.
- `UnauthorizedOperation`: If attempting to blacklist an `ADMIN_ROLE` or `DEFAULT_ADMIN_ROLE` holder.

#### Function Type: Transaction `batchUpdateBlacklist(address[] calldata users, bool[] calldata statuses)`
**Description**: Updates the blacklist status for multiple user addresses in a single transaction.
**Request**:
```
address[] users       // Array of addresses to update
bool[] statuses       // Array of boolean statuses (true/false)
```
**Response**: No direct return, emits `BlacklistStatusChanged` for each user.
**Errors**:
- `AccessControl: sender missing role` (OPERATOR_ROLE)
- `Pausable: paused`: If the contract is paused.
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).
- `InvalidRoleConfiguration`: If `users.length != statuses.length`.
- `InvalidAddress`: If any `user` is `address(0)`.
- `UnauthorizedOperation`: If attempting to blacklist an `ADMIN_ROLE` or `DEFAULT_ADMIN_ROLE` holder.

#### Function Type: Transaction `scheduleAdminChange(address newAdmin, bool isSuperAdmin)`
**Description**: Schedules a timelocked change for either the `superAdmin` or `pasarAdmin` address.
**Request**:
```
address newAdmin      // Proposed new admin address
bool isSuperAdmin     // True for DEFAULT_ADMIN_ROLE, false for ADMIN_ROLE
```
**Response**: No direct return, emits `AdminChangeScheduled`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).
- `InvalidAddress`: If `newAdmin` is `address(0)`.

#### Function Type: Transaction `executeAdminChange(bytes32 operationId)`
**Description**: Executes a previously scheduled admin change after its timelock has passed.
**Request**:
```
bytes32 operationId   // Unique identifier of the pending admin change
```
**Response**: No direct return, emits `RoleAssigned`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).
- `UnauthorizedOperation`: If `operationId` is invalid or timelock has not passed.

#### Function Type: Transaction `cancelAdminChange(bytes32 operationId)`
**Description**: Cancels a pending admin change operation.
**Request**:
```
bytes32 operationId   // Unique identifier of the pending admin change to cancel
```
**Response**: No direct return, emits `AdminChangeScheduled` with `scheduleTime = 0`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).
- `UnauthorizedOperation`: If `operationId` is invalid or not found.

#### Function Type: Transaction `emergencyShutdown()`
**Description**: Initiates an emergency shutdown, locking the system and pausing the contract.
**Request**: None
**Response**: No direct return, emits `EmergencyShutdown`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)

#### Function Type: Transaction `restoreSystem()`
**Description**: Restores core system functions after an emergency shutdown, unlocking the system and unpausing the contract.
**Request**: None
**Response**: No direct return, emits `SystemRestored`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)

#### Function Type: Transaction `pause()`
**Description**: Pauses the contract, preventing calls to functions protected by `whenNotPaused`.
**Request**: None
**Response**: No direct return, emits `Paused`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).

#### Function Type: Transaction `unpause()`
**Description**: Unpauses the contract, allowing calls to functions protected by `whenNotPaused` again.
**Request**: None
**Response**: No direct return, emits `Unpaused`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).

#### Function Type: Transaction `resolveDispute(uint256 disputeId, address winner)`
**Description**: (Virtual) Resolves a dispute. Intended to be overridden by a derived contract.
**Request**:
```
uint256 disputeId // Unique ID of the dispute
address winner    // Address of the party who won the dispute
```
**Response**: No direct return.
**Errors**:
- `AccessControl: sender missing role` (DISPUTE_MANAGER_ROLE)
- `Pausable: paused`: If the contract is paused.
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).
- `InvalidAddress`: If `winner` is `address(0)`.

#### Function Type: Transaction `managePlatformService(bytes32 serviceId, bool enable)`
**Description**: (Virtual) Manages platform services. Intended to be overridden by a derived contract.
**Request**:
```
bytes32 serviceId // Unique identifier of the service
bool enable       // True to enable, false to disable
```
**Response**: No direct return.
**Errors**:
- `AccessControl: sender missing role` (PLATFORM_SERVICE_ROLE)
- `Pausable: paused`: If the contract is paused.
- `UnauthorizedOperation`: If the system is locked (`systemLocked == true`).

#### Function Type: View Call `isOperator(address account)`
**Description**: Checks if an address holds the `OPERATOR_ROLE`.
**Request**:
```
address account // Address to check
```
**Response**: `bool` - True if `account` is an operator, false otherwise.
**Errors**: None

#### Function Type: View Call `getAccountRoles(address account)`
**Description**: Retrieves all specific roles assigned to a given address.
**Request**:
```
address account // Address to check
```
**Response**: `bytes32[]` - An array of role identifiers held by the account.
**Errors**: None

#### Function Type: View Call `isAdminChangeReady(bytes32 operationId)`
**Description**: Checks if a scheduled admin change operation is ready for execution.
**Request**:
```
bytes32 operationId // Unique identifier of the pending admin change
```
**Response**: `bool` - True if the operation exists and its timelock has passed.
**Errors**: None

### PGatewaySettings Contract

**Overview**: The configuration hub for the PayNode protocol, storing and managing all configurable parameters like fees, tier limits, and crucial addresses. It implements `OwnableUpgradeable` for administrative control.

**Contract Address**: `[Deployed PGatewaySettings Address]`

#### Function Type: View Call `MAX_BPS()`
**Description**: Returns the constant representing 100% in basis points (100,000).
**Request**: None
**Response**: `uint256` - The value `100_000`.
**Errors**: None

#### Function Type: View Call `protocolFeePercent()`
**Description**: Returns the current protocol fee percentage in basis points.
**Request**: None
**Response**: `uint64` - Protocol fee.
**Errors**: None

#### Function Type: View Call `orderExpiryWindow()`
**Description**: Returns the configured order expiry window duration in seconds.
**Request**: None
**Response**: `uint256` - Order expiry window.
**Errors**: None

#### Function Type: View Call `proposalTimeout()`
**Description**: Returns the proposal timeout duration in seconds.
**Request**: None
**Response**: `uint256` - Proposal timeout.
**Errors**: None

#### Function Type: View Call `treasuryAddress()`
**Description**: Returns the current treasury address.
**Request**: None
**Response**: `address` - Treasury address.
**Errors**: None

#### Function Type: View Call `intentExpiry()`
**Description**: Returns the configured intent expiry duration in seconds.
**Request**: None
**Response**: `uint256` - Intent expiry.
**Errors**: None

#### Function Type: View Call `aggregatorAddress()`
**Description**: Returns the current aggregator contract address.
**Request**: None
**Response**: `address` - Aggregator address.
**Errors**: None

#### Function Type: View Call `integratorAddress()`
**Description**: Returns the default integrator address.
**Request**: None
**Response**: `address` - Integrator address.
**Errors**: None

#### Function Type: View Call `integratorFeePercent()`
**Description**: Returns the default integrator fee percentage in basis points.
**Request**: None
**Response**: `uint64` - Integrator fee.
**Errors**: None

#### Function Type: View Call `ALPHA_TIER_LIMIT()`
**Description**: Returns the configured Alpha tier limit.
**Request**: None
**Response**: `uint256` - Alpha tier limit.
**Errors**: None

#### Function Type: View Call `BETA_TIER_LIMIT()`
**Description**: Returns the configured Beta tier limit.
**Request**: None
**Response**: `uint256` - Beta tier limit.
**Errors**: None

#### Function Type: View Call `DELTA_TIER_LIMIT()`
**Description**: Returns the configured Delta tier limit.
**Request**: None
**Response**: `uint256` - Delta tier limit.
**Errors**: None

#### Function Type: View Call `OMEGA_TIER_LIMIT()`
**Description**: Returns the configured Omega tier limit.
**Request**: None
**Response**: `uint256` - Omega tier limit.
**Errors**: None

#### Function Type: View Call `TITAN_TIER_LIMIT()`
**Description**: Returns the configured Titan tier limit.
**Request**: None
**Response**: `uint256` - Titan tier limit.
**Errors**: None

#### Function Type: View Call `supportedTokens(address)`
**Description**: Checks if a specific token is currently supported.
**Request**:
```
address token // Address of the ERC20 token
```
**Response**: `bool` - True if supported, false otherwise.
**Errors**: None

#### Function Type: View Call `isTokenSupported(address _token)`
**Description**: Checks if a token is supported by the protocol.
**Request**:
```
address _token // The ERC20 token address to check
```
**Response**: `bool` - True if the token is supported, false otherwise.
**Errors**: None

#### Function Type: Transaction `initialize(PGatewayStructs.InitiateGatewaySettingsParams memory params)`
**Description**: Initializes the `PGatewaySettings` contract with all initial protocol parameters. This function should only be called once.
**Request**:
```
PGatewayStructs.InitiateGatewaySettingsParams params // Struct containing all initial settings
// struct InitiateGatewaySettingsParams {
//     address initialOwner;
//     address treasury;
//     address aggregator;
//     uint64 protocolFee;
//     uint256 alphaLimit;
//     uint256 betaLimit;
//     uint256 deltaLimit;
//     address integrator;
//     uint64 integratorFee;
//     uint256 omegaLimit;
//     uint256 titanLimit;
//     uint256 orderExpiryWindow;
//     uint256 proposalTimeout;
//     uint256 intentExpiry;
// }
```
**Response**: No direct return, emits `Initialized`.
**Errors**:
- `InvalidAddress`: If any critical address (treasury, aggregator, integrator) is `address(0)`.
- `InvalidFee`: If `protocolFee` or `integratorFee` exceeds limits (e.g., `protocolFee > 5000`).
- `InvalidLimits`: If tier limits are not strictly increasing or `alphaLimit` is zero.
- `InvalidDuration`: If `orderExpiryWindow`, `proposalTimeout`, or `intentExpiry` are zero, or `proposalTimeout > orderExpiryWindow`.

#### Function Type: Transaction `setProtocolFee(uint64 _newFee)`
**Description**: Updates the protocol fee percentage.
**Request**:
```
uint64 _newFee // New protocol fee in basis points (max 500 for 5%)
```
**Response**: No direct return, emits `ProtocolFeeUpdated`.
**Errors**:
- `Ownable: caller is not the owner`: If called by a non-owner.
- `InvalidFee`: If `_newFee` exceeds `500` (5%).

#### Function Type: Transaction `setTierLimits(uint256 _alphaLimit, uint256 _betaLimit, uint256 _deltaLimit, uint256 _omegaLimit, uint256 _titanLimit)`
**Description**: Updates all tier limits for order classification.
**Request**:
```
uint256 _alphaLimit // Max value for Alpha tier
uint256 _betaLimit  // Max value for Beta tier
uint256 _deltaLimit // Max value for Delta tier
uint256 _omegaLimit // Max value for Omega tier
uint256 _titanLimit // Max value for Titan tier
```
**Response**: No direct return, emits `TierLimitsUpdated`.
**Errors**:
- `Ownable: caller is not the owner`: If called by a non-owner.
- `InvalidLimits`: If limits are not strictly increasing or `_alphaLimit` is zero.

#### Function Type: Transaction `setOrderExpiryWindow(uint256 _newWindow)`
**Description**: Sets the order expiry window duration.
**Request**:
```
uint256 _newWindow // New expiry window in seconds
```
**Response**: No direct return, emits `OrderExpiryWindowUpdated`.
**Errors**:
- `Ownable: caller is not the owner`: If called by a non-owner.
- `InvalidDuration`: If `_newWindow` is zero.

#### Function Type: Transaction `setProposalTimeout(uint256 _newTimeout)`
**Description**: Sets the proposal timeout duration.
**Request**:
```
uint256 _newTimeout // New proposal timeout in seconds
```
**Response**: No direct return, emits `ProposalTimeoutUpdated`.
**Errors**:
- `Ownable: caller is not the owner`: If called by a non-owner.
- `InvalidDuration`: If `_newTimeout` is zero.

#### Function Type: Transaction `setTreasuryAddress(address _newTreasury)`
**Description**: Updates the treasury address for protocol fee collection.
**Request**:
```
address _newTreasury // New treasury address
```
**Response**: No direct return, emits `TreasuryAddressUpdated`.
**Errors**:
- `Ownable: caller is not the owner`: If called by a non-owner.
- `InvalidAddress`: If `_newTreasury` is `address(0)`.

#### Function Type: Transaction `setAggregatorAddress(address _newAggregator)`
**Description**: Updates the aggregator address.
**Request**:
```
address _newAggregator // New aggregator address
```
**Response**: No direct return, emits `AggregatorAddressUpdated`.
**Errors**:
- `Ownable: caller is not the owner`: If called by a non-owner.
- `InvalidAddress`: If `_newAggregator` is `address(0)`.

#### Function Type: Transaction `setSupportedToken(address _token, bool _supported)`
**Description**: Adds or removes a token from the supported tokens list.
**Request**:
```
address _token   // ERC20 token address
bool _supported  // True to support, false to remove support
```
**Response**: No direct return, emits `SupportedTokenUpdated`.
**Errors**:
- `Ownable: caller is not the owner`: If called by a non-owner.
- `InvalidAddress`: If `_token` is `address(0)`.

### PGateway Contract

**Overview**: The core settlement engine of the PayNode protocol. It manages the order lifecycle, provider intent registration, settlement proposals, execution, and refunds. This contract is UUPS upgradeable, Pausable, and relies heavily on `PayNodeAccessManager` for access control and `PGatewaySettings` for configuration.

**Contract Address**: `[Deployed PGateway Proxy Address]`

#### Function Type: View Call `accessManager()`
**Description**: Returns the address of the `IPayNodeAccessManager` contract.
**Request**: None
**Response**: `address` - The AccessManager contract address.
**Errors**: None

#### Function Type: View Call `settings()`
**Description**: Returns the address of the `IPGatewaySettings` contract.
**Request**: None
**Response**: `address` - The PGatewaySettings contract address.
**Errors**: None

#### Function Type: View Call `orders(bytes32)`
**Description**: Retrieves details for a specific order by its ID.
**Request**:
```
bytes32 orderId // Unique identifier of the order
```
**Response**: `PGatewayStructs.Order` - Order details struct.
**Errors**: None

#### Function Type: View Call `proposals(bytes32)`
**Description**: Retrieves details for a specific settlement proposal by its ID.
**Request**:
```
bytes32 proposalId // Unique identifier for the proposal
```
**Response**: `PGatewayStructs.SettlementProposal` - Proposal details struct.
**Errors**: None

#### Function Type: View Call `providerIntents(address)`
**Description**: Retrieves the most recent provider intent for a specific provider.
**Request**:
```
address provider // Address of the liquidity provider
```
**Response**: `PGatewayStructs.ProviderIntent` - Provider intent details struct.
**Errors**: None

#### Function Type: View Call `providerReputation(address)`
**Description**: Retrieves reputation data for a specific provider.
**Request**:
```
address provider // Address of the liquidity provider
```
**Response**: `PGatewayStructs.ProviderReputation` - Provider reputation details struct.
**Errors**: None

#### Function Type: View Call `userNonce(address)`
**Description**: Returns the current nonce for a specific user.
**Request**:
```
address user // Address of the user
```
**Response**: `uint256` - Current user nonce.
**Errors**: None

#### Function Type: View Call `proposalExecuted(bytes32)`
**Description**: Checks if a settlement proposal has already been executed.
**Request**:
```
bytes32 proposalId // Unique identifier for the proposal
```
**Response**: `bool` - True if executed, false otherwise.
**Errors**: None

#### Function Type: View Call `integratorRegistry(address)`
**Description**: Retrieves information for a registered integrator.
**Request**:
```
address integrator // Address of the integrator
```
**Response**: `PGatewayStructs.IntegratorInfo` - Integrator info struct.
**Errors**: None

#### Function Type: View Call `usedMessageHashes(bytes32)`
**Description**: Checks if a message hash has been used to prevent replay attacks.
**Request**:
```
bytes32 messageHash // The message hash to check
```
**Response**: `bool` - True if used, false otherwise.
**Errors**: None

#### Function Type: View Call `MAX_INTEGRATOR_FEE()`
**Description**: Returns the maximum allowed integrator fee in basis points.
**Request**: None
**Response**: `uint64` - Maximum integrator fee.
**Errors**: None

#### Function Type: View Call `MIN_INTEGRATOR_FEE()`
**Description**: Returns the minimum allowed integrator fee in basis points.
**Request**: None
**Response**: `uint64` - Minimum integrator fee.
**Errors**: None

#### Function Type: Transaction `initialize(address _accessManager, address _settings)`
**Description**: Initializes the `PGateway` contract, setting up references to the `PayNodeAccessManager` and `PGatewaySettings` contracts. This function should only be called once.
**Request**:
```
address _accessManager // Address of the PayNodeAccessManager contract
address _settings      // Address of the PGatewaySettings contract
```
**Response**: No direct return.
**Errors**:
- `InvalidAddress`: If `_accessManager` or `_settings` is `address(0)`.

#### Function Type: Transaction `pause()`
**Description**: Pauses the contract, halting most operations. Requires `DEFAULT_ADMIN_ROLE` and executes through AccessManager's non-reentrant mechanism.
**Request**: None
**Response**: No direct return, emits `Paused`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `DEFAULT_ADMIN_ROLE` or `executeNonReentrant` fails.

#### Function Type: Transaction `unpause()`
**Description**: Unpauses the contract, resuming normal operations. Requires `DEFAULT_ADMIN_ROLE` and executes through AccessManager's non-reentrant mechanism.
**Request**: None
**Response**: No direct return, emits `Unpaused`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `DEFAULT_ADMIN_ROLE` or `executeNonReentrant` fails.

#### Function Type: Transaction `registerIntent(string calldata _currency, uint256 _availableAmount, uint64 _minFeeBps, uint64 _maxFeeBps, uint256 _commitmentWindow)`
**Description**: Registers a provider's intent to offer liquidity, specifying currency, amount, fee range, and commitment window.
**Request**:
```
string _currency          // Currency code (e.g., "USDT", "NGN")
uint256 _availableAmount  // Amount provider can handle
uint64 _minFeeBps         // Minimum acceptable fee in basis points
uint64 _maxFeeBps         // Maximum acceptable fee in basis points
uint256 _commitmentWindow // Time window for provider to accept proposal
```
**Response**: No direct return, emits `IntentRegistered`.
**Errors**:
- `Pausable: paused`: If the contract is paused.
- `UserBlacklisted`: If `msg.sender` is blacklisted by AccessManager.
- `InvalidProvider`: If `executeProviderNonReentrant` fails.
- `InvalidAmount`: If `_availableAmount` is zero.
- `InvalidFee`: If `_minFeeBps > _maxFeeBps` or `_maxFeeBps > settings.maxProtocolFee()`.
- `InvalidDuration`: If `_commitmentWindow` is zero.
- `ErrorProviderBlacklisted`: If the provider is blacklisted in `providerReputation`.

#### Function Type: Transaction `updateIntent(string calldata _currency, uint256 _newAmount)`
**Description**: Updates an existing provider's available liquidity amount.
**Request**:
```
string _currency      // Currency code
uint256 _newAmount    // New available amount
```
**Response**: No direct return, emits `IntentUpdated`.
**Errors**:
- `NotRegisteredProvider`: If `msg.sender` is not a registered provider.
- `Pausable: paused`: If the contract is paused.
- `ErrorProviderBlacklisted`: If `executeProviderNonReentrant` fails.
- `InvalidAmount`: If `_newAmount` is zero.
- `InvalidIntent`: If the provider's intent is not active.

#### Function Type: Transaction `expireIntent(address _provider)`
**Description**: Expires a provider's intent, setting it to inactive. Can be called manually by aggregator if intent expiry is past.
**Request**:
```
address _provider // Address of the provider whose intent to expire
```
**Response**: No direct return, emits `IntentExpired`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `AGGREGATOR_ROLE` or `executeAggregatorNonReentrant` fails.
- `InvalidIntent`: If the provider's intent is not active.
- `IntentNotExpired`: If `block.timestamp` is not yet past `intent.expiresAt`.

#### Function Type: Transaction `reserveIntent(address _provider, uint256 _amount)`
**Description**: Reserves a portion of a provider's available capacity when a proposal is sent.
**Request**:
```
address _provider // Provider address
uint256 _amount   // Amount to reserve
```
**Response**: No direct return.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `AGGREGATOR_ROLE` or `executeAggregatorNonReentrant` fails.
- `InvalidIntent`: If the provider's intent is not active.
- `InvalidAmount`: If `intent.availableAmount < _amount`.

#### Function Type: Transaction `releaseIntent(address _provider, uint256 _amount, string calldata _reason)`
**Description**: Releases previously reserved capacity back to a provider, typically if a proposal is rejected or times out.
**Request**:
```
address _provider          // Provider address
uint256 _amount            // Amount to release
string _reason             // Reason for releasing capacity
```
**Response**: No direct return, emits `IntentReleased`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `AGGREGATOR_ROLE` or `executeAggregatorNonReentrant` fails.

#### Function Type: View Call `getProviderIntent(address _provider)`
**Description**: Retrieves the active provider intent details for a given provider.
**Request**:
```
address _provider // Provider address
```
**Response**: `PGatewayStructs.ProviderIntent` - Struct containing intent details.
**Errors**: None

#### Function Type: Transaction `registerAsIntegrator(uint64 _feeBps, string calldata _name)`
**Description**: Allows any address to register as an integrator with a custom fee and name.
**Request**:
```
uint64 _feeBps     // Desired fee in basis points (e.g., 100 = 1%)
string _name       // Integrator's display name (max 50 chars)
```
**Response**: No direct return, emits `IntegratorRegistered`.
**Errors**:
- `AlreadyRegistered`: If `msg.sender` is already a registered integrator.
- `FeeOutOfRange`: If `_feeBps` is outside `MIN_INTEGRATOR_FEE` and `MAX_INTEGRATOR_FEE`.
- `InvalidName`: If `_name` is empty or too long.

#### Function Type: Transaction `updateIntegratorFee(uint64 _newFeeBps)`
**Description**: Allows a registered integrator to update their fee configuration.
**Request**:
```
uint64 _newFeeBps // New fee in basis points
```
**Response**: No direct return, emits `IntegratorFeeUpdated`.
**Errors**:
- `NotRegistered`: If `msg.sender` is not a registered integrator.
- `FeeOutOfRange`: If `_newFeeBps` is outside `MIN_INTEGRATOR_FEE` and `MAX_INTEGRATOR_FEE`.

#### Function Type: Transaction `updateIntegratorName(string calldata _newName)`
**Description**: Allows a registered integrator to update their display name.
**Request**:
```
string _newName // New name for the integrator (max 50 chars)
```
**Response**: No direct return, emits `IntegratorNameUpdated`.
**Errors**:
- `NotRegistered`: If `msg.sender` is not a registered integrator.
- `InvalidName`: If `_newName` is empty or too long.

#### Function Type: Transaction `createOrder(address _token, uint256 _amount, address _refundAddress, address _integrator, uint64 _integratorFee, bytes32 _messageHash)`
**Description**: Initiates a new payment order. Transfers tokens from the user to the contract's escrow.
**Request**:
```
address _token          // ERC20 token address
uint256 _amount         // Order amount in tokens
address _refundAddress  // Address for refunds
address _integrator     // Address of the dApp/integrator
uint64 _integratorFee   // Integrator's fee in basis points for this order
bytes32 _messageHash    // Unique hash of off-chain order details
```
**Response**: `bytes32` - The unique `orderId`. Emits `OrderCreated`.
**Errors**:
- `Pausable: paused`: If the contract is paused.
- `UserBlacklisted`: If `msg.sender` is blacklisted by AccessManager.
- `TokenNotSupported`: If `_token` is not supported by `PGatewaySettings`.
- `InvalidAmount`: If `_amount` is zero.
- `InvalidAddress`: If `_refundAddress` or `_integrator` is `address(0)`.
- `InvalidMessageHash`: If `_messageHash` is empty.
- `Unauthorized`: If `executeNonReentrant` fails.
- `MessageHashAlreadyUsed`: If `_messageHash` has been used before.
- `SafeERC20: ERC20: transfer amount exceeds balance`: If user has insufficient balance.
- `SafeERC20: ERC20: transferFrom failed`: If transfer from user fails (e.g., allowance not set).

#### Function Type: View Call `getOrder(bytes32 _orderId)`
**Description**: Retrieves the full details of a specific order.
**Request**:
```
bytes32 _orderId // Unique identifier of the order
```
**Response**: `PGatewayStructs.Order` - Order details struct.
**Errors**:
- `OrderNotFound`: If `_orderId` does not correspond to an existing order.

#### Function Type: Transaction `createProposal(bytes32 _orderId, address _provider, uint64 _proposedFeeBps)`
**Description**: An aggregator creates a settlement proposal for a pending order, selecting a provider and specifying a fee.
**Request**:
```
bytes32 _orderId         // Associated order ID
address _provider        // Address of the chosen provider
uint64 _proposedFeeBps   // Proposed fee in basis points
```
**Response**: `bytes32` - The unique `proposalId`. Emits `SettlementProposalCreated`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `AGGREGATOR_ROLE` or `executeAggregatorNonReentrant` fails.
- `OrderNotFound`: If `_orderId` does not correspond to an existing order.
- `InvalidOrder`: If the order is not in `PENDING` status.
- `OrderExpired`: If the order's `expiresAt` timestamp has passed.
- `InvalidIntent`: If the provider's intent is not active.
- `InvalidAmount`: If `providerIntents[_provider].availableAmount < order.amount`.
- `InvalidFee`: If `_proposedFeeBps` is outside the provider's `minFeeBps` and `maxFeeBps`.

#### Function Type: Transaction `acceptProposal(bytes32 _proposalId)`
**Description**: A provider accepts a settlement proposal, committing to fulfill the order.
**Request**:
```
bytes32 _proposalId // Proposal ID to accept
```
**Response**: No direct return, emits `SettlementProposalAccepted`.
**Errors**:
- `NotRegisteredProvider`: If `msg.sender` is not a registered provider.
- `Pausable: paused`: If the contract is paused.
- `InvalidProvider`: If `executeProviderNonReentrant` fails.
- `Unauthorized`: If `msg.sender` is not the `provider` associated with `_proposalId`.
- `InvalidProposal`: If the proposal is not in `PENDING` status or has expired.

#### Function Type: Transaction `rejectProposal(bytes32 _proposalId, string calldata _reason)`
**Description**: A provider rejects a settlement proposal, releasing their reserved capacity.
**Request**:
```
bytes32 _proposalId // Proposal ID to reject
string _reason      // Reason for rejection
```
**Response**: No direct return, emits `SettlementProposalRejected`.
**Errors**:
- `NotRegisteredProvider`: If `msg.sender` is not a registered provider.
- `InvalidProvider`: If `executeProviderNonReentrant` fails.
- `Unauthorized`: If `msg.sender` is not the `provider` associated with `_proposalId`.
- `InvalidProposal`: If the proposal is not in `PENDING` status.

#### Function Type: Transaction `timeoutProposal(bytes32 _proposalId)`
**Description**: Marks a settlement proposal as timed out if the deadline has passed without acceptance.
**Request**:
```
bytes32 _proposalId // Proposal ID to mark as timed out
```
**Response**: No direct return, emits `SettlementProposalTimeout`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `AGGREGATOR_ROLE` or `executeAggregatorNonReentrant` fails.
- `InvalidProposal`: If the proposal is not in `PENDING` status or has not yet reached its deadline.

#### Function Type: View Call `getProposal(bytes32 _proposalId)`
**Description**: Retrieves the full details of a specific settlement proposal.
**Request**:
```
bytes32 _proposalId // Proposal identifier
```
**Response**: `PGatewayStructs.SettlementProposal` - Struct with proposal details.
**Errors**: None

#### Function Type: Transaction `executeSettlement(bytes32 _proposalId)`
**Description**: Executes an accepted settlement, distributing funds from escrow to treasury, integrator, and provider.
**Request**:
```
bytes32 _proposalId // The ID of the accepted proposal to execute settlement for
```
**Response**: No direct return, emits `SettlementExecuted`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `AGGREGATOR_ROLE` or `executeAggregatorNonReentrant` fails.
- `InvalidProposal`: If the proposal is not in `ACCEPTED` status or has already been executed.
- `InvalidOrder`: If the associated order is not in `ACCEPTED` status.
- `SafeERC20: ERC20: transfer amount exceeds balance`: If contract has insufficient balance.
- `SafeERC20: ERC20: transfer failed`: If transfer to treasury, integrator, or provider fails.

#### Function Type: Transaction `refundOrder(bytes32 _orderId)`
**Description**: Refunds an order if no provider accepts within the order expiry window.
**Request**:
```
bytes32 _orderId // Order ID to refund
```
**Response**: No direct return, emits `OrderRefunded`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `AGGREGATOR_ROLE` or `executeAggregatorNonReentrant` fails.
- `OrderNotFound`: If `_orderId` does not correspond to an existing order.
- `InvalidOrder`: If the order is already `FULFILLED` or `REFUNDED`.
- `OrderNotExpired`: If `block.timestamp` is not yet past `order.expiresAt`.
- `SafeERC20: ERC20: transfer amount exceeds balance`: If contract has insufficient balance.
- `SafeERC20: ERC20: transfer failed`: If transfer to refund address fails.

#### Function Type: Transaction `requestRefund(bytes32 _orderId)`
**Description**: Allows a user to manually request a refund if their order has not been fulfilled and has expired.
**Request**:
```
bytes32 _orderId // Order ID to refund
```
**Response**: No direct return, emits `OrderRefunded`.
**Errors**:
- `OrderNotFound`: If `_orderId` does not correspond to an existing order.
- `Unauthorized`: If `msg.sender` is not the `user` of the order, or if `executeNonReentrant` fails.
- `InvalidOrder`: If the order is in `FULFILLED` or `REFUNDED` status.
- `OrderNotExpired`: If `block.timestamp` is not yet past `order.expiresAt`.
- `SafeERC20: ERC20: transfer amount exceeds balance`: If contract has insufficient balance.
- `SafeERC20: ERC20: transfer failed`: If transfer to refund address fails.

#### Function Type: Transaction `flagFraudulent(address _provider)`
**Description**: Flags a provider as fraudulent, disabling their intent and reputation.
**Request**:
```
address _provider // Provider address to flag
```
**Response**: No direct return, emits `ProviderFraudFlagged`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `AGGREGATOR_ROLE` or `executeAggregatorNonReentrant` fails.
- `InvalidAddress`: If `_provider` is `address(0)`.

#### Function Type: Transaction `blacklistProvider(address _provider, string calldata _reason)`
**Description**: Blacklists a provider, preventing them from participating in settlements. Requires `DEFAULT_ADMIN_ROLE`.
**Request**:
```
address _provider     // Provider address to blacklist
string _reason        // Reason for blacklisting
```
**Response**: No direct return, emits `ProviderBlacklisted`.
**Errors**:
- `Unauthorized`: If `msg.sender` does not have `DEFAULT_ADMIN_ROLE` or `executeNonReentrant` fails.

#### Function Type: View Call `getProviderReputation(address _provider)`
**Description**: Retrieves a provider's reputation data.
**Request**:
```
address _provider // Provider address
```
**Response**: `PGatewayStructs.ProviderReputation` - Struct with reputation metrics.
**Errors**: None

#### Function Type: View Call `getUserNonce(address _user)`
**Description**: Returns a user's current nonce for replay protection.
**Request**:
```
address _user // User address
```
**Response**: `uint256` - Current nonce.
**Errors**: None

#### Function Type: View Call `getIntegratorInfo(address _integrator)`
**Description**: Retrieves complete information for a registered integrator.
**Request**:
```
address _integrator // Address of the integrator
```
**Response**: `PGatewayStructs.IntegratorInfo` - Complete integrator information.
**Errors**: None

### PayNodeAdmin Contract

**Overview**: The governance contract responsible for managing timelocked upgrades of proxy contracts and scheduled role changes within the PayNode ecosystem. It extends OpenZeppelin's `TimelockController` and integrates Chainlink Automation for automated upkeep.

**Contract Address**: `[Deployed PayNodeAdmin Address]`

#### Function Type: View Call `ADMIN_ROLE()`
**Description**: Returns the `bytes32` identifier for the `ADMIN_ROLE` specific to this contract, which can schedule and execute upgrades.
**Request**: None
**Response**: `bytes32` - The role identifier.
**Errors**: None

#### Function Type: View Call `MIN_DELAY()`
**Description**: Returns the minimum delay (in seconds) that must pass between scheduling and executing critical operations.
**Request**: None
**Response**: `uint256` - The value `2 days` (172800 seconds).
**Errors**: None

#### Function Type: View Call `UPKEEP_COOLDOWN()`
**Description**: Returns the cooldown period (in seconds) between `performUpkeep` calls by Chainlink Automation.
**Request**: None
**Response**: `uint256` - The value `1 hour` (3600 seconds).
**Errors**: None

#### Function Type: View Call `chainlinkKeeper()`
**Description**: Returns the immutable address of the Chainlink Keeper authorized to call `performUpkeep`.
**Request**: None
**Response**: `address` - The Chainlink Keeper address.
**Errors**: None

#### Function Type: View Call `lastUpkeepTime()`
**Description**: Returns the timestamp of the last successful `performUpkeep` execution.
**Request**: None
**Response**: `uint256` - Last upkeep timestamp.
**Errors**: None

#### Function Type: View Call `pendingUpgrades(address)`
**Description**: Retrieves details of a pending upgrade for a specific proxy target.
**Request**:
```
address target // The proxy contract address
```
**Response**: `PGatewayStructs.PendingUpgrade` - Struct containing upgrade details.
**Errors**: None

#### Function Type: View Call `upgradeQueue(uint256)`
**Description**: Retrieves a proxy address from the upgrade queue by its index.
**Request**:
```
uint256 index // Index in the upgradeQueue array
```
**Response**: `address` - Proxy contract address.
**Errors**: None (will revert if index out of bounds)

#### Function Type: View Call `pendingRoleChanges(bytes32)`
**Description**: Retrieves details of a pending role change operation.
**Request**:
```
bytes32 operationId // Unique identifier of the role change
```
**Response**: `PGatewayStructs.PendingRoleChange` - Struct containing role change details.
**Errors**: None

#### Function Type: View Call `getUpgradeQueue()`
**Description**: Returns the array of all proxy addresses currently in the upgrade queue.
**Request**: None
**Response**: `address[] memory` - Array of addresses with pending upgrades.
**Errors**: None

#### Function Type: View Call `isRoleChangeReady(bytes32 operationId)`
**Description**: Checks if a scheduled role change operation is ready for execution (i.e., timelock has passed).
**Request**:
```
bytes32 operationId // The operation ID to check
```
**Response**: `bool` - True if ready, false otherwise.
**Errors**: None

#### Function Type: Constructor `constructor(address[] memory proposers, address[] memory executors, address superAdmin, address upgradeAdmin, address _chainlinkKeeper)`
**Description**: Initializes the `PayNodeAdmin` contract with roles for proposers, executors, super admin, upgrade admin, and the Chainlink Keeper.
**Request**:
```
address[] proposers       // Addresses allowed to propose timelocked operations
address[] executors       // Addresses allowed to execute timelocked operations
address superAdmin        // Address to receive DEFAULT_ADMIN_ROLE and act as admin
address upgradeAdmin      // Address to receive ADMIN_ROLE (for upgrades)
address _chainlinkKeeper  // Address of the Chainlink Keeper for automation
```
**Response**: No direct return.
**Errors**:
- `InvalidAddress`: If `_chainlinkKeeper` is `address(0)`.

#### Function Type: Transaction `scheduleUpgrade(address target, address newImplementation)`
**Description**: Schedules an upgrade for a proxy contract. This operation is timelocked.
**Request**:
```
address target          // The proxy contract to upgrade
address newImplementation // The new implementation contract address
```
**Response**: No direct return, emits `UpgradeScheduled`.
**Errors**:
- `AccessControl: sender missing role` (ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `InvalidAddress`: If `target` or `newImplementation` is `address(0)`.
- `UpgradeAlreadyPending`: If an upgrade is already pending for this `target`.
- `ValueTooLargeForuint96`: If `block.timestamp + MIN_DELAY` exceeds `type(uint96).max`.

#### Function Type: Transaction `cancelUpgrade(address target)`
**Description**: Cancels a previously scheduled upgrade for a proxy contract.
**Request**:
```
address target // The proxy contract whose upgrade to cancel
```
**Response**: No direct return, emits `UpgradeCancelled`.
**Errors**:
- `AccessControl: sender missing role` (ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `NoUpgradePending`: If no upgrade is pending for this `target`.

#### Function Type: Transaction `performUpgrade(address target)`
**Description**: Manually executes a scheduled upgrade for a proxy contract after its timelock has passed.
**Request**:
```
address target // The proxy contract to upgrade
```
**Response**: No direct return, emits `UpgradeExecuted`.
**Errors**:
- `AccessControl: sender missing role` (ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `NoUpgradePending`: If no upgrade is pending for this `target`.
- `UpgradeTooEarly`: If the timelock period has not yet passed.
- `UpgradeFailed`: If the low-level `upgradeTo` call on the proxy fails.

#### Function Type: View Call `checkUpkeep(bytes calldata /* checkData */ )`
**Description**: Chainlink Automation callback: Checks if any pending upgrade is ready for execution.
**Request**:
```
bytes checkData // (ignored)
```
**Response**: `(bool upkeepNeeded, bytes memory performData)`
- `upkeepNeeded`: True if an upgrade is ready.
- `performData`: Encoded `target` address if `upkeepNeeded` is true.
**Errors**: None

#### Function Type: Transaction `performUpkeep(bytes calldata performData)`
**Description**: Chainlink Automation callback: Executes a ready upgrade. Restricted to the Chainlink Keeper.
**Request**:
```
bytes performData // Encoded target address from checkUpkeep
```
**Response**: No direct return, emits `UpkeepPerformed` and `UpgradeExecuted`.
**Errors**:
- `OnlyChainlinkKeeper`: If called by an address other than `chainlinkKeeper`.
- `Pausable: paused`: If the contract is paused.
- `UpkeepCooldownActive`: If called within the `UPKEEP_COOLDOWN` period.
- `NoUpgradePending`: If no upgrade is pending for the decoded `target`.
- `UpgradeTooEarly`: If the timelock period for the upgrade has not yet passed.
- `UpgradeFailed`: If the low-level `upgradeTo` call on the proxy fails.

#### Function Type: Transaction `scheduleRoleChange(address account, bytes32 role, bool grant)`
**Description**: Schedules a role assignment or revocation with a timelock delay.
**Request**:
```
address account // The account to modify
bytes32 role    // The role to grant or revoke
bool grant      // True to grant, false to revoke
```
**Response**: No direct return, emits `RoleChangeScheduled`.
**Errors**:
- `AccessControl: sender missing role` (ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `InvalidAddress`: If `account` is `address(0)`.
- `ValueTooLargeForuint96`: If `block.timestamp + MIN_DELAY` exceeds `type(uint96).max`.

#### Function Type: Transaction `executeRoleChange(bytes32 operationId)`
**Description**: Executes a pending role change after its timelock period has passed.
**Request**:
```
bytes32 operationId // Unique identifier of the pending role change
```
**Response**: No direct return, emits `RoleChangeExecuted`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `RoleChangeNotReady`: If `operationId` is invalid, not found, or timelock has not passed.

#### Function Type: Transaction `cancelRoleChange(bytes32 operationId)`
**Description**: Cancels a pending role change operation.
**Request**:
```
bytes32 operationId // The operation ID to cancel
```
**Response**: No direct return, emits `RoleChangeScheduled` with `scheduleTime = 0`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)
- `Pausable: paused`: If the contract is paused.
- `RoleChangeNotReady`: If `operationId` is invalid or not found.

#### Function Type: Transaction `pause()`
**Description**: Pauses the contract, halting all critical operations. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**: None
**Response**: No direct return, emits `Paused`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)

#### Function Type: Transaction `unpause()`
**Description**: Unpauses the contract, resuming all operations. Restricted to `DEFAULT_ADMIN_ROLE`.
**Request**: None
**Response**: No direct return, emits `Unpaused`.
**Errors**:
- `AccessControl: sender missing role` (DEFAULT_ADMIN_ROLE)

## Usage

The PayNode protocol contracts are designed to be integrated by off-chain aggregators and dApps (integrators) to facilitate non-custodial off-ramp payment settlements.

### User Flow (via Integrator dApp)
1.  **User Approves Token**: User approves the `PGateway` contract to spend their ERC20 token for the order amount.
    ```solidity
    IERC20(tokenAddress).approve(gatewayAddress, amount);
    ```
2.  **User Creates Order**: The user (or the dApp on their behalf) calls `PGateway.createOrder()`, specifying the token, amount, refund address, integrator details, and a unique `_messageHash` (linking to off-chain order details like bank account information).
    ```solidity
    // Example: Create an order for 100 USDC to be off-ramped
    // Assuming USDC is 6 decimal places for example, so amount is 100 * 10^6
    gateway.createOrder(
        USDC_ADDRESS,
        100_000_000, // 100 USDC
        userRefundAddress,
        integratorAddress,
        integratorFeeBps, // e.g., 50 for 0.5%
        keccak256(abi.encodePacked("unique_off_chain_order_id_user_data_123"))
    );
    ```
    This transfers the tokens to the `PGateway` contract's escrow.

### Provider Flow
1.  **Provider Registers/Updates Intent**: Providers register their intent to offer liquidity using `PGateway.registerIntent()` or `PGateway.updateIntent()`. They specify the currency, available amount, fee range, and commitment window.
    ```solidity
    // Example: Provider registers intent for 50,000 NGN equivalent liquidity
    gateway.registerIntent(
        "NGN",
        50_000_000_000_000_000_000, // Example for 18-decimal NGN equivalent
        200, // 2% min fee
        500, // 5% max fee
        30 // 30-second commitment window
    );
    ```
2.  **Provider Accepts Proposal**: Once an off-chain aggregator sends a proposal for a matching order, the provider can accept it using `PGateway.acceptProposal()`.
    ```solidity
    gateway.acceptProposal(proposalId);
    ```
3.  **Provider Rejects Proposal**: If a provider cannot fulfill a proposal, they can reject it using `PGateway.rejectProposal()`.
    ```solidity
    gateway.rejectProposal(proposalId, "Insufficient fiat liquidity");
    ```

### Aggregator Flow (Off-chain Orchestration)
1.  **Monitor Orders**: The off-chain aggregator monitors `OrderCreated` events from `PGateway` and tracks available provider intents via `PGateway.getProviderIntent()`.
2.  **Route and Create Proposals**: Based on order tiers, provider reputation, and capacity, the aggregator identifies eligible providers and sends settlement proposals using `PGateway.createProposal()`. This is done in parallel for multiple providers.
    ```solidity
    // Example: Aggregator proposes settlement to Provider A for an order
    gateway.createProposal(
        orderId,
        providerA_Address,
        300 // 3% proposed fee
    );
    ```
3.  **Execute Settlement**: Once a provider accepts a proposal, the aggregator calls `PGateway.executeSettlement()` to finalize the transaction, distributing fees and sending funds to the provider (who then executes the off-chain fiat payment to the user).
    ```solidity
    gateway.executeSettlement(acceptedProposalId);
    ```
4.  **Manage Timeouts/Refunds**: The aggregator is responsible for calling `PGateway.timeoutProposal()` for expired proposals and `PGateway.refundOrder()` for orders that expire without a successful settlement.

### Admin & Governance Flow
1.  **System Configuration**: The contract owner (or `DEFAULT_ADMIN_ROLE` via `PayNodeAccessManager`) configures protocol parameters through `PGatewaySettings` (e.g., `setProtocolFee()`, `setTierLimits()`, `setSupportedToken()`). These changes are often timelocked via `PayNodeAdmin`.
2.  **Upgrade Management**: New `PGateway` or `PayNodeAccessManager` implementations are scheduled for upgrade by the `ADMIN_ROLE` holder via `PayNodeAdmin.scheduleUpgrade()`. After the `MIN_DELAY` (2 days), the upgrade can be executed manually or automatically by Chainlink Automation via `PayNodeAdmin.performUpgrade()` or `PayNodeAdmin.performUpkeep()`.
3.  **Emergency Control**: The `DEFAULT_ADMIN_ROLE` can invoke `PayNodeAccessManager.emergencyShutdown()` to pause all critical operations if a vulnerability is detected.

## Technologies Used

| Technology                                                                                                    | Description                                                                                                                                                                                            |
| :------------------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Solidity](https://docs.soliditylang.org/en/latest/)                                                          | The primary programming language for writing smart contracts on the Ethereum Virtual Machine.                                                                                                          |
| [Foundry](https://book.getfoundry.sh/)                                                                        | A blazing-fast, portable, and modular toolkit for Ethereum application development, used for compiling, testing, and deploying contracts.                                                                |
| [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/5.x/)                                        | Industry-standard library for secure smart contract development, providing battle-tested implementations of ERC standards, access control, and upgradeability patterns.                                |
| [OpenZeppelin Upgradeable Contracts](https://docs.openzeppelin.com/contracts-upgradeable/5.x/)                | Specialized versions of OpenZeppelin contracts designed for upgradeability using patterns like UUPS proxies.                                                                                           |
| [Chainlink Automation](https://docs.chain.link/chainlink-automation/introduction/)                            | Decentralized oracle network service used here for reliably triggering smart contract functions (e.g., executing timelocked upgrades) based on predefined conditions.                                  |
| [ERC1967Proxy (UUPS)](https://docs.openzeppelin.com/contracts/4.x/api/proxy#ERC1967Proxy)                     | An upgradeability pattern that allows contracts to be upgraded by simply changing their implementation address, preserving the contract's address and state.                                          |
| [TimelockController](https://docs.openzeppelin.com/contracts/5.x/api/governance#TimelockController)           | A contract that enforces a time delay for critical operations, enhancing security by providing a window for review before potentially malicious or erroneous actions are executed.                   |
| [AccessControl](https://docs.openzeppelin.com/contracts/5.x/api/access#AccessControl)                         | A role-based access control mechanism, allowing precise management of permissions for different functions and users within the system.                                                                 |
| [Pausable](https://docs.openzeppelin.com/contracts/5.x/api/utils#Pausable)                                    | A utility contract that provides an emergency stop mechanism, allowing authorized roles to pause and unpause contract functionality.                                                               |
| [ReentrancyGuard](https://docs.openzeppelin.com/contracts/5.x/api/utils#ReentrancyGuard)                      | A security mechanism that prevents reentrancy attacks, a common vulnerability where external calls can "re-enter" a contract before the initial call is finished, leading to unexpected behavior. |

## Contributing
We welcome contributions to the PayNode Protocol! To contribute, please follow these guidelines:

*   ✨ **Fork the Repository**: Start by forking the `paynode-contract` repository to your GitHub account.
*   🌿 **Create a New Branch**: Create a new branch for your feature or bug fix: `git checkout -b feature/your-feature-name` or `bugfix/issue-description`.
*   🚀 **Implement Your Changes**: Write clean, maintainable, and well-tested code. Ensure your changes adhere to the existing code style.
*   🧪 **Run Tests**: Before submitting, ensure all existing tests pass and add new tests for your changes. Foundry tests can be run with `forge test`.
*   📚 **Update Documentation**: If your changes introduce new functionality or modify existing APIs, please update the relevant documentation.
*   ⬆️ **Commit Your Changes**: Commit your changes with a clear and concise message.
*   📬 **Open a Pull Request**: Submit a pull request to the `main` branch of the original repository. Provide a detailed description of your changes and why they are necessary.

## License
This project is licensed under the MIT License. See the `LICENSE` file for details.

## Author Info

Connect with the author of this project!

*   LinkedIn: [YourLinkedInProfile](https://linkedin.com/in/olujimiadebakin)
*   Twitter: [@YourTwitterHandle](https://twitter.com/YourTwitterHandle)

---

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
# 🚀 PayNode Protocol Smart Contracts

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.18-orange?logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Framework-lightgray?logo=foundry)](https://github.com/foundry-rs/foundry)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-Contracts-blue?logo=openzeppelin)](https://openzeppelin.com/contracts/)
[![Chainlink Automation](https://img.shields.io/badge/Chainlink-Automation-blueviolet?logo=chainlink)](https://chain.link/automation)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview
PayNode is an innovative non-custodial payment aggregation protocol designed for intelligent, parallel settlement routing across multiple off-chain liquidity providers. It revolutionizes traditional settlement by broadcasting proposals simultaneously to eligible providers, with the first to accept executing the order. This system leverages on-chain smart contracts to manage orders, provider intents, and secure settlements, while an off-chain aggregator optimizes routing based on provider tiers, capacity, and performance.

## Features
*   ✨ **Parallel Settlement**: Enables multiple liquidity providers to race for order acceptance, ensuring rapid and efficient settlements.
*   🔒 **Non-Custodial Escrow**: User funds are securely held in escrow within the smart contract until settlement, guaranteeing trustless operations.
*   🧠 **Tier-Based Intelligent Routing**: Facilitates optimized off-chain routing through an aggregator that considers provider tiers, capacities, and reputation scores.
*   ⏱️ **Timelocked Upgrades**: Critical contract upgrades are secured with a 48-hour timelock via `PayNodeAdmin`, preventing instantaneous or malicious changes.
*   🔐 **Role-Based Access Control (RBAC)**: Fine-grained permissions managed by `PayNodeAccessManager` assign specific roles (e.g., Admin, Operator, Aggregator) for secure protocol governance.
*   🚨 **Emergency Pause**: Includes a critical "kill switch" mechanism allowing administrators to pause protocol operations in emergencies.
*   🚫 **Provider Blacklisting**: System for flagging and blacklisting fraudulent or non-performing liquidity providers to maintain network integrity.
*   📈 **Provider Reputation System**: Tracks successful orders, failed orders, and settlement times to build a robust reputation score for providers.
*   🔗 **Chainlink Automation Integration**: Utilizes Chainlink Keepers to automate the execution of scheduled upgrades and other time-sensitive protocol actions.
*   🔄 **Upgradeable Architecture**: Implements the UUPS proxy pattern for seamless and secure contract upgrades without disrupting ongoing operations.

## Getting Started
To get the PayNode Protocol smart contracts running locally, follow these steps. This project uses [Foundry](https://getfoundry.sh/), a blazing fast, portable, and modular toolkit for Ethereum application development.

### Installation
First, ensure you have Foundry installed. If not, follow the instructions [here](https://getfoundry.sh/).
Once Foundry is set up, clone the repository and install dependencies:

```bash
# ⬇️ Clone the repository
git clone https://github.com/olujimiAdebakin/paynode-contract.git

# 📂 Navigate into the project directory
cd paynode-contract

# 📦 Install project dependencies (git submodules for OpenZeppelin, Chainlink, etc.)
forge install
git submodule update --init --recursive

# 🔨 Build the contracts
forge build

# 🧪 (Optional) Run tests
forge test
```

### Environment Variables
For deployment, key addresses and configuration values need to be provided. While not traditional "environment variables" for a runtime application, these are essential deployment parameters that define the initial state and access of the smart contract system.

| Variable Name           | Type        | Description                                                                                                                                                                                              | Example Value                          |
| :---------------------- | :---------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------- |
| `_admin`                | `address`   | Initial address to be granted the `DEFAULT_ADMIN_ROLE` and `ADMIN_ROLE` within `PayNodeAccessManager` and also passed to `PayNodeAdmin` as `superAdmin` and `upgradeAdmin` respectively.               | `0x7f...` (Your Admin Wallet)          |
| `_aggregator`           | `address`   | The address of the off-chain service or entity responsible for creating settlement proposals. Set in `PGatewaySettings`.                                                                                     | `0x8c...` (Your Aggregator Service)    |
| `_treasury`             | `address`   | The address where protocol fees collected from settlements will be sent. Set in `PGatewaySettings`.                                                                                                          | `0x9d...` (Your Protocol Treasury)     |
| `_chainlinkKeeper`      | `address`   | The address of the Chainlink Keeper allowed to call `performUpkeep` on `PayNodeAdmin` for automated upgrades.                                                                                              | `0xA1...` (Chainlink Keeper Address)   |
| `_proposers`            | `address[]` | An array of addresses authorized to propose timelocked operations within `PayNodeAdmin`.                                                                                                                   | `[0xB2..., 0xC3...]`                   |
| `_executors`            | `address[]` | An array of addresses authorized to execute timelocked operations within `PayNodeAdmin`.                                                                                                                   | `[0xD4..., 0xE5...]`                   |
| `_protocolFee`          | `uint64`    | The initial percentage of the order amount taken as a protocol fee, in basis points (e.g., `200` for 2%). Max `5000` (5%). Set in `PGatewaySettings`.                                                           | `200`                                  |
| `_smallLimit`           | `uint256`   | The maximum amount for an order to be categorized into the `SMALL` tier. Set in `PGatewaySettings`.                                                                                                          | `5000 * 10**18` (e.g., 5000 tokens)    |
| `_mediumLimit`          | `uint256`   | The maximum amount for an order to be categorized into the `MEDIUM` tier. Must be greater than `_smallLimit`. Set in `PGatewaySettings`.                                                                       | `20000 * 10**18` (e.g., 20000 tokens)  |
| `_orderExpiryWindow`    | `uint256`   | The default time in seconds before a created order automatically expires if not settled. Set in `PGatewaySettings`.                                                                                        | `3600` (1 hour)                        |
| `_proposalTimeout`      | `uint256`   | The default time in seconds within which a provider must accept a settlement proposal. Set in `PGatewaySettings`.                                                                                            | `300` (5 minutes)                      |

## API Documentation
The PayNode Protocol exposes a robust set of smart contract interfaces as its on-chain API, enabling secure and automated interactions for users, liquidity providers, and administrators.

### Base URL
The PayNode Protocol operates as a decentralized backend. Interactions occur via direct calls to the deployed smart contract addresses on the blockchain, rather than a centralized HTTP base URL. Each contract serves as a distinct module of the protocol's API.

### Endpoints

#### `PGateway.registerIntent`
Registers a liquidity provider's intent to process payments, detailing their available capacity, preferred fees, and commitment window.

**Request**:
```solidity
function registerIntent(
    string calldata _currency,
    uint256 _availableAmount,
    uint64 _minFeeBps,
    uint64 _maxFeeBps,
    uint256 _commitmentWindow
) external
```
*   `_currency` (`string`): The currency code (e.g., "NGN", "USD").
*   `_availableAmount` (`uint256`): The total amount the provider is willing to handle. Must be greater than 0.
*   `_minFeeBps` (`uint64`): Minimum fee in basis points (e.g., 100 for 1%).
*   `_maxFeeBps` (`uint64`): Maximum fee in basis points. Must be `<= 10000` (10%).
*   `_commitmentWindow` (`uint256`): Time (in seconds) the provider commits to accept a proposal. Must be greater than 0.

**Response**:
On successful registration, the contract's state is updated, and an `IntentRegistered` event is emitted.
```solidity
event IntentRegistered(
    address indexed provider,
    string indexed currency,
    uint256 availableAmount,
    uint256 commitmentWindow,
    uint256 expiresAt
);
```

**Errors**:
*   `InvalidAmount`: If `_availableAmount` is zero.
*   `InvalidFees`: If `_minFeeBps` is greater than `_maxFeeBps`.
*   `FeesTooHigh`: If `_maxFeeBps` exceeds 10000 (10%).
*   `InvalidCommitmentWindow`: If `_commitmentWindow` is zero.
*   `ProviderBlacklisted`: If the `msg.sender` is blacklisted by `PayNodeAccessManager`.
*   `Pausable: paused`: If the `PGateway` contract is paused.
*   `ReentrancyGuard: reentrant call`: If a reentrant call is detected during execution.

#### `PGateway.createOrder`
Enables a user to initiate a new payment order by depositing the required ERC20 tokens into the gateway's escrow.

**Request**:
```solidity
function createOrder(
    address _token,
    uint256 _amount,
    address _refundAddress
) external returns (bytes32 orderId)
```
*   `_token` (`address`): The ERC20 token address for the payment.
*   `_amount` (`uint256`): The total amount of tokens for the order. Must be greater than 0.
*   `_refundAddress` (`address`): The address designated to receive funds if the order is eventually refunded. Must be a valid non-zero address.

**Response**:
Returns the unique `orderId` (`bytes32`). On success, an `OrderCreated` event is emitted.
```solidity
event OrderCreated(
    bytes32 indexed orderId,
    address indexed user,
    address token,
    uint256 amount,
    OrderTier tier,
    uint256 expiresAt
);
```

**Errors**:
*   `InvalidAmount`: If `_amount` is zero.
*   `InvalidRefundAddress`: If `_refundAddress` is the zero address.
*   `TokenNotSupported`: If `_token` is not whitelisted by `PGatewaySettings`.
*   `UserBlacklisted`: If `msg.sender` is blacklisted by `PayNodeAccessManager`.
*   `Pausable: paused`: If the `PGateway` contract is paused.
*   `ReentrancyGuard: reentrant call`: If a reentrant call is detected during execution.
*   `ERC20: transferFrom failed`: If the `transferFrom` call to pull tokens from the user fails.

#### `PGateway.createProposal`
(Callable only by the Aggregator) An authorized off-chain aggregator initiates a settlement proposal for a specific order to a selected liquidity provider.

**Request**:
```solidity
function createProposal(
    bytes32 _orderId,
    address _provider,
    uint64 _proposedFeeBps
) external returns (bytes32 proposalId)
```
*   `_orderId` (`bytes32`): The unique identifier of the order to be settled.
*   `_provider` (`address`): The address of the liquidity provider for this proposal.
*   `_proposedFeeBps` (`uint64`): The fee (in basis points) offered by the aggregator to the provider for this settlement.

**Response**:
Returns the unique `proposalId` (`bytes32`). On success, a `SettlementProposalCreated` event is emitted.
```solidity
event SettlementProposalCreated(
    bytes32 indexed proposalId,
    bytes32 indexed orderId,
    address indexed provider,
    uint256 amount,
    uint64 feeBps,
    uint256 deadline
);
```

**Errors**:
*   `OnlyAggregator`: If `msg.sender` is not the authorized aggregator address (as set in `PGatewaySettings`).
*   `OrderNotFound`: If `_orderId` does not correspond to an existing order.
*   `OrderNotPending`: If the order's status is not `PENDING`.
*   `OrderExpired`: If the order has already expired based on its `expiresAt` timestamp.
*   `ProviderIntentNotActive`: If the `_provider` does not have an active `ProviderIntent`.
*   `InsufficientCapacity`: If the provider's `availableAmount` is less than the `order.amount`.
*   `InvalidFee`: If `_proposedFeeBps` is outside the provider's `minFeeBps` and `maxFeeBps` range.

#### `PGateway.acceptProposal`
(Callable only by a Provider) A liquidity provider accepts a pending settlement proposal directed to them.

**Request**:
```solidity
function acceptProposal(
    bytes32 _proposalId
) external
```
*   `_proposalId` (`bytes32`): The unique identifier of the proposal to accept.

**Response**:
On successful acceptance, the proposal and linked order statuses are updated, and a `SettlementProposalAccepted` event is emitted.
```solidity
event SettlementProposalAccepted(
    bytes32 indexed proposalId,
    bytes32 indexed orderId,
    address indexed provider,
    uint256 timestamp
);
```

**Errors**:
*   `NotProposalProvider`: If `msg.sender` is not the `provider` associated with the `_proposalId`.
*   `ProposalNotPending`: If the proposal's status is not `PENDING`.
*   `ProposalExpired`: If the proposal's `proposalDeadline` has passed.
*   `Pausable: paused`: If the `PGateway` contract is paused.
*   `ReentrancyGuard: reentrant call`: If a reentrant call is detected during execution.

#### `PGateway.executeSettlement`
(Callable only by the Aggregator) Finalizes an accepted settlement proposal, transferring the order amount (minus fees) to the provider and the protocol fee to the treasury.

**Request**:
```solidity
function executeSettlement(
    bytes32 _proposalId
) external
```
*   `_proposalId` (`bytes32`): The unique identifier of the accepted proposal to execute.

**Response**:
On successful execution, funds are transferred, order status updated, provider reputation metrics are adjusted, and a `SettlementExecuted` event is emitted.
```solidity
event SettlementExecuted(
    bytes32 indexed orderId,
    bytes32 indexed proposalId,
    address indexed provider,
    uint256 amount,
    uint64 feeBps,
    uint256 protocolFee
);
```

**Errors**:
*   `OnlyAggregator`: If `msg.sender` is not the authorized aggregator address.
*   `ProposalNotAccepted`: If the proposal's status is not `ACCEPTED`.
*   `AlreadyExecuted`: If the proposal has already been executed.
*   `OrderNotAccepted`: If the linked order's status is not `ACCEPTED`.
*   `ReentrancyGuard: reentrant call`: If a reentrant call is detected during execution.
*   `ERC20: transfer failed`: If token transfer to the treasury or provider fails.

#### `PayNodeAccessManager.setBlacklistStatus`
(Callable only by `OPERATOR_ROLE`) Updates the blacklist status for a single user address. This prevents blacklisted users from creating orders or registering intents.

**Request**:
```solidity
function setBlacklistStatus(
    address user,
    bool status
) external
```
*   `user` (`address`): The address whose blacklist status is to be updated.
*   `status` (`bool`): `true` to blacklist the user, `false` to remove them from the blacklist.

**Response**:
On successful update, a `BlacklistStatusChanged` event is emitted.
```solidity
event BlacklistStatusChanged(
    address indexed user,
    bool status,
    address indexed operator
);
```

**Errors**:
*   `AccessControl: account is missing role`: If `msg.sender` does not possess the `OPERATOR_ROLE`.
*   `Pausable: paused`: If the `PayNodeAccessManager` contract is paused.
*   `UnauthorizedOperation`: If the system is in an `emergencyShutdown` state (`systemLocked` is true), or if `msg.sender` attempts to blacklist an address holding `ADMIN_ROLE` or `DEFAULT_ADMIN_ROLE`.
*   `InvalidAddress`: If `user` is the zero address.

#### `PayNodeAdmin.scheduleUpgrade`
(Callable only by `ADMIN_ROLE`) Schedules a contract upgrade for a specified proxy (`target`) to a new implementation address. The upgrade will be subject to a `MIN_DELAY` (2 days) timelock.

**Request**:
```solidity
function scheduleUpgrade(
    address target,
    address newImplementation
) external
```
*   `target` (`address`): The address of the proxy contract (e.g., `PGateway` proxy) that will be upgraded.
*   `newImplementation` (`address`): The address of the new logic contract to which the `target` proxy will point.

**Response**:
On successful scheduling, an `UpgradeScheduled` event is emitted, indicating the `scheduleTime` when the upgrade can be executed.
```solidity
event UpgradeScheduled(
    address indexed target,
    address indexed newImplementation,
    uint256 scheduleTime,
    address indexed caller
);
```

**Errors**:
*   `AccessControl: account is missing role`: If `msg.sender` does not possess the `ADMIN_ROLE`.
*   `Pausable: paused`: If the `PayNodeAdmin` contract is paused.
*   `InvalidAddress`: If `target` or `newImplementation` is the zero address.
*   `UpgradeAlreadyPending`: If an upgrade for the specified `target` proxy is already pending.

#### `PayNodeAdmin.performUpkeep`
(Callable only by `chainlinkKeeper`) Executes a previously scheduled upgrade for a proxy contract once its timelock has expired. This function is primarily intended to be triggered by Chainlink Automation.

**Request**:
```solidity
function performUpkeep(
    bytes calldata performData
) external
```
*   `performData` (`bytes`): Encoded data (typically the `target` proxy address) provided by Chainlink Automation's `checkUpkeep` function.

**Response**:
On successful execution, an `UpkeepPerformed` event is emitted, followed by an `UpgradeExecuted` event after the proxy is updated.
```solidity
event UpkeepPerformed(uint256 lastUpkeepTime);
event UpgradeExecuted(
    address indexed target,
    address indexed newImplementation,
    uint256 executedAt,
    address indexed caller,
    bool isAutomated
);
```

**Errors**:
*   `OnlyChainlinkKeeper`: If `msg.sender` is not the authorized `chainlinkKeeper` address.
*   `Pausable: paused`: If the `PayNodeAdmin` contract is paused.
*   `UpkeepCooldownActive`: If called before the configured `UPKEEP_COOLDOWN` period has elapsed since the last upkeep.
*   `NoUpgradePending`: If no upgrade is found for the decoded `target` address within `performData`.
*   `UpgradeTooEarly`: If the scheduled `scheduleTime` for the upgrade has not yet passed.
*   `UpgradeFailed`: If the low-level `upgradeTo(address)` call on the proxy contract itself fails.
*   `ReentrancyGuard: reentrant call`: If a reentrant call is detected during execution.

---

## Technologies Used

| Technology          | Category           | Description                                                                 | Link                                                              |
| :------------------ | :----------------- | :-------------------------------------------------------------------------- | :---------------------------------------------------------------- |
| **Solidity**        | Smart Contract Lang. | Core language for writing the blockchain logic.                             | [Solidity Website](https://soliditylang.org/)                     |
| **Foundry**         | Development Toolkit| Modern Ethereum development framework for building, testing, and deploying. | [Foundry GitHub](https://github.com/foundry-rs/foundry)           |
| **OpenZeppelin**    | Smart Contract Lib.| Industry-standard battle-tested smart contract libraries for security and common patterns (e.g., ERC, Access Control, Upgradeable). | [OpenZeppelin Contracts](https://openzeppelin.com/contracts/)     |
| **Chainlink**       | Oracle/Automation  | Decentralized oracle network for external data and automated function calls (e.g., `AutomationCompatibleInterface`). | [Chainlink Website](https://chain.link/)                          |
| **UUPS Proxy Pattern** | Upgradeability  | A secure and widely adopted standard for enabling transparent and flexible smart contract upgrades.                | [OpenZeppelin Docs](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) |
| **ERC20 Token Standard** | Token Standard | The foundational interface for fungible tokens on Ethereum, used for payment amounts.                 | [ERC20 Standard (EIP-20)](https://eips.ethereum.org/EIPS/eip-20)  |

---

## Contributing
We welcome contributions to the PayNode Protocol! If you're interested in improving this project, please consider the following guidelines:

*   ✨ **Fork the repository** and clone it to your local machine.
*   🌿 **Create a new branch** for your feature or bug fix: `git checkout -b feature/your-feature-name` or `git checkout -b bugfix/issue-description`.
*   💻 **Make your changes**: Ensure your code adheres to existing coding standards and best practices.
*   ✅ **Write tests** for your changes. All new features and bug fixes should be covered by appropriate tests.
*   🧪 **Run all tests** (`forge test`) to ensure everything is working correctly and no regressions have been introduced.
*   📝 **Update documentation** as necessary to reflect your changes.
*   ⬆️ **Commit your changes** with clear and descriptive commit messages.
*   🚀 **Push your branch** to your forked repository.
*   🤝 **Open a Pull Request** to the `main` branch of this repository. Provide a detailed description of your changes and why they are necessary.

We appreciate your effort in making PayNode better!

## License
This project is licensed under the MIT License. You can find the SPDX License Identifier in each source file, confirming its open-source nature.

## Author Info
Developed with precision by:

### Olujimi
*   LinkedIn: [Your LinkedIn Profile](https://www.linkedin.com/in/YOUR_LINKEDIN_USERNAME)
*   Twitter: [@YourTwitterHandle](https://twitter.com/YOUR_TWITTER_USERNAME)
*   Website: [Your Personal Website](https://www.yourwebsite.com)

---

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
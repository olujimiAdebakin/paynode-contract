# PayNode Protocol: Decentralized Payment Aggregation ⚡

## Overview

PayNode is an innovative, non-custodial payment aggregation protocol built on the Ethereum Virtual Machine using Solidity. It revolutionizes settlement routing by connecting users to multiple off-chain liquidity providers, enabling intelligent, parallel execution of payment proposals. Instead of traditional sequential processing, PayNode broadcasts settlement proposals simultaneously, ensuring the fastest available provider executes the order. This architecture guarantees efficiency, resilience, and a superior user experience, positioning PayNode at the forefront of decentralized finance infrastructure.

## Features

-   **Modular Architecture**: 🏗️ Designed with distinct contract layers (AccessManager, TimelockAdmin, GatewaySettings, PGateway) for clear separation of concerns, maintainability, and enhanced security.
-   **Non-Custodial Escrow**: 🔐 User funds are locked securely within the smart contract during the order lifecycle and only released upon successful settlement or refund, ensuring user control and minimizing counterparty risk.
-   **Role-Based Access Control (RBAC)**: 🛡️ Granular permissions are managed through a robust AccessManager, assigning roles like `ADMIN`, `OPERATOR`, `AGGREGATOR`, and `UPGRADER` to enforce secure operations.
-   **Upgradeable & Secure Infrastructure**: 🚀 Utilizes OpenZeppelin's UUPS proxy pattern and a TimelockAdmin with a 48-hour delay for critical upgrades, preventing instant malicious changes and ensuring governance oversight.
-   **Parallel Settlement & Intelligent Routing**: ⚡ Core innovation allowing multiple liquidity providers to race to accept an order, with off-chain aggregation logic determining routing based on provider tiers, capacity, and performance.
-   **Provider Intent System**: 🤝 Liquidity providers pre-register their capacity, supported currencies, and fee preferences, creating a dynamic marketplace for settlements.
-   **Reputation Scoring & Blacklisting**: ⭐ A built-in system tracks provider performance, flags fraudulent activity, and allows for blacklisting, maintaining a trustworthy ecosystem.
-   **Emergency Controls**: 🛑 Includes `pause`, `unpause`, and `emergencyShutdown` mechanisms for rapid response to critical vulnerabilities or market events, safeguarding user funds and protocol integrity.
-   **Chainlink Automation Integration**: 🤖 The `PayNodeAdmin` leverages Chainlink Automation (Keepers) for reliable, automated execution of timelocked upgrades and other routine protocol maintenance.

## Getting Started

To get PayNode up and running locally for development and testing, follow these steps.

### Prerequisites

You'll need `Foundry`, a blazing fast, portable and modular toolkit for Ethereum application development.

1.  **Install Foundry**:
    If you don't have Foundry installed, open your terminal and run:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    ```
    Then, update your shell environment:
    ```bash
    foundryup
    ```

### Installation

1.  **Clone the Repository**:
    Begin by cloning the PayNode contracts repository to your local machine:
    ```bash
    git clone https://github.com/olujimiAdebakin/paynode-contract.git
    cd paynode-contract
    ```

2.  **Install Dependencies**:
    Install the project's dependencies, including OpenZeppelin contracts and Forge Standard Library:
    ```bash
    forge install
    ```

3.  **Build Contracts**:
    Compile the smart contracts:
    ```bash
    forge build
    ```

4.  **Run Tests (Optional but Recommended)**:
    Execute the test suite to ensure everything is working as expected:
    ```bash
    forge test
    ```

### Environment Variables

While most configurations are managed on-chain through `PGatewaySettings`, during local development or deployment, you might need environment variables for private keys, RPC URLs, etc.

*   `PRIVATE_KEY`: Private key for the deployer address (e.g., `0x...`)
*   `GOERLI_RPC_URL` (or other network): RPC endpoint for the blockchain network (e.g., `https://eth-goerli.g.alchemy.com/v2/...`)
*   `ETHERSCAN_API_KEY`: API key for block explorer verification (e.g., Etherscan)

Example `.env` file structure:
```
PRIVATE_KEY="YOUR_PRIVATE_KEY_HERE"
GOERLI_RPC_URL="YOUR_GOERLI_RPC_URL"
ETHERSCAN_API_KEY="YOUR_ETHERSCAN_API_KEY"
```

## Usage

The PayNode protocol is designed for modular interaction, with `PayNodeAccessManager`, `PayNodeGatewaySettings`, and `PGateway` being the core contracts. The `PayNodeAdmin` handles upgrades and governance.

### Deployment Sequence

The `PayNode.sol` contract provides a `deploySystem` function that orchestrates the deployment of the entire PayNode ecosystem. This is the recommended deployment flow:

1.  **Deploy `PayNodeAccessManager`**: Sets up core roles and emergency controls.
2.  **Deploy `PayNodeAdmin`**: The timelock controller that will manage protocol upgrades and critical admin changes. Its owner is typically the `PayNodeAccessManager`.
3.  **Deploy `PGatewaySettings`**: Stores all configurable protocol parameters (fees, tier limits, supported tokens).
4.  **Deploy `PGateway` (Implementation)**: The logic contract for the main gateway.
5.  **Deploy `ERC1967Proxy` for `PGateway`**: The upgradeable proxy contract pointing to the `PGateway` implementation. `initialize()` is called on this proxy.
6.  **Transfer Ownerships**: Critical ownerships (e.g., `PayNodeAccessManager` and `PGatewaySettings`) are transferred to `PayNodeAdmin` to enable timelocked governance.

You can simulate or execute this deployment using Foundry scripts (e.g., a `script/Deploy.s.sol` file, if present, or by calling the `deploySystem` function from `PayNode.sol` directly).

### Interacting with the Contracts

Here are examples of key interactions with the deployed contracts:

#### **Registering Provider Intent**
Providers define their liquidity and fee preferences.
- **Contract**: `PGateway`
- **Method**: `registerIntent`
- **Caller**: A liquidity provider
- **Parameters**:
    - `_currency` (string): e.g., "NGN", "USD"
    - `_availableAmount` (uint256): Amount of liquidity available (in smallest unit, e.g., wei for ERC20)
    - `_minFeeBps` (uint64): Minimum acceptable fee in basis points (e.g., 100 for 1%)
    - `_maxFeeBps` (uint64): Maximum fee in basis points (e.g., 500 for 5%)
    - `_commitmentWindow` (uint256): Time in seconds the provider commits to being available

**Example Call (conceptual)**:
```solidity
// Assuming 'gateway' is an instance of the PGateway contract
gateway.registerIntent("USDT", 1000000000000000000000, 100, 300, 3600); // 1000 USDT, 1-3% fee, 1 hour commitment
```

#### **Creating an Order**
Users initiate a payment by locking funds into the gateway.
- **Contract**: `PGateway`
- **Method**: `createOrder`
- **Caller**: A user
- **Parameters**:
    - `_token` (address): ERC20 token address (e.g., USDC, USDT)
    - `_amount` (uint256): Amount of tokens for the order
    - `_refundAddress` (address): Address to send funds if the order fails
    - `_messageHash` (string): A hash of an off-chain message for extra context or signing
- **Returns**: `bytes32` (orderId)

**Example Call (conceptual)**:
```solidity
// Assuming 'gateway' is an instance of the PGateway contract, and 'userToken' is an IERC20 instance
userToken.approve(address(gateway), 500000000000000000000); // Approve gateway to spend 500 USDC
bytes32 myOrderId = gateway.createOrder(address(userToken), 500000000000000000000, msg.sender, "0x123...");
```

#### **Creating a Settlement Proposal**
The aggregator (off-chain component) proposes an order to an eligible provider.
- **Contract**: `PGateway`
- **Method**: `createProposal`
- **Caller**: The designated `aggregatorAddress`
- **Parameters**:
    - `_orderId` (bytes32): The ID of the order to settle
    - `_provider` (address): The provider being proposed to
    - `_proposedFeeBps` (uint64): The fee (in basis points) the aggregator proposes for the provider
- **Returns**: `bytes32` (proposalId)

**Example Call (conceptual)**:
```solidity
// Assuming 'gateway' is an instance of the PGateway contract, called by the aggregator
bytes32 myProposalId = gateway.createProposal(myOrderId, providerAddress, 200); // Propose 2% fee
```

#### **Accepting a Proposal**
A provider accepts a settlement proposal.
- **Contract**: `PGateway`
- **Method**: `acceptProposal`
- **Caller**: A liquidity provider (must match `proposal.provider`)
- **Parameters**:
    - `_proposalId` (bytes32): The ID of the proposal to accept

**Example Call (conceptual)**:
```solidity
// Assuming 'gateway' is an instance of the PGateway contract, called by the provider
gateway.acceptProposal(myProposalId);
```

#### **Executing Settlement**
The aggregator finalizes the payment after a proposal is accepted.
- **Contract**: `PGateway`
- **Method**: `executeSettlement`
- **Caller**: The designated `aggregatorAddress`
- **Parameters**:
    - `_proposalId` (bytes32): The ID of the accepted proposal

**Example Call (conceptual)**:
```solidity
// Assuming 'gateway' is an instance of the PGateway contract, called by the aggregator
gateway.executeSettlement(myProposalId);
```

#### **Error Handling**
The contracts use custom errors for gas efficiency and clarity:
-   `InvalidAddress()`: A zero address or invalid address was provided.
-   `UserBlacklisted(address user)`: An action was attempted by a blacklisted user.
-   `UpgradeAlreadyPending(address target)`: An upgrade is already scheduled for the target contract.
-   `NoUpgradePending(address target)`: No upgrade is pending for the specified target.
-   `InsufficientCapacity`: Provider does not have enough liquidity for the order.
-   `OrderNotPending`: Order is not in the expected `PENDING` state.

## Technologies Used

| Technology         | Description                                                                 | Link                                                       |
| :----------------- | :-------------------------------------------------------------------------- | :--------------------------------------------------------- |
| **Solidity**       | Smart contract programming language for Ethereum.                           | [Solidity Lang](https://docs.soliditylang.org/en/latest/)  |
| **Foundry**        | Fast, portable, and modular toolkit for Ethereum development.               | [Foundry GitHub](https://github.com/foundry-rs/foundry)   |
| **OpenZeppelin**   | Libraries of battle-tested smart contracts for secure development.          | [OpenZeppelin Docs](https://docs.openzeppelin.com/)        |
| **Chainlink**      | Decentralized oracle network for external data and automation.              | [Chainlink Docs](https://docs.chain.link/)                 |
| **Hardhat (Implied)** | Ethereum development environment for testing and deployment. | [Hardhat Docs](https://hardhat.org/docs)                   |

## Contributing

We welcome contributions to the PayNode Protocol! If you're interested in improving the project, please follow these guidelines:

1.  ✨ **Fork the Repository**: Start by forking the `paynode-contract` repository to your GitHub account.
2.  🌿 **Create a Branch**: Create a new branch for your feature or bug fix: `git checkout -b feature/your-feature-name` or `git checkout -b bugfix/issue-description`.
3.  💻 **Make Changes**: Implement your changes, adhering to the existing code style.
4.  🧪 **Write Tests**: Ensure your changes are well-tested. New features should have new tests, and bug fixes should include a test that reproduces the bug.
5.  ✅ **Run Tests**: Before submitting, run `forge test` to ensure all tests pass.
6.  ocommit **Commit Changes**: Write clear and concise commit messages.
7.  ⬆️ **Push to Your Fork**: Push your branch to your forked repository.
8.  📬 **Open a Pull Request**: Submit a pull request to the `main` branch of the original repository. Provide a detailed description of your changes.

## License

No explicit license file was found in the project directory. Please contact the author for licensing information.

## Author Info

**Olujimi**

Connect with me:

-   [LinkedIn](https://linkedin.com/in/olujimi_placeholder)
-   [Twitter](https://twitter.com/olujimi_placeholder)

---

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.18-blue)](https://docs.soliditylang.org/en/latest/)
[![Foundry](https://img.shields.io/badge/Developed%20with-Foundry-critical)](https://getfoundry.sh/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-Contracts-purple)](https://openzeppelin.com/contracts/)
[![Chainlink](https://img.shields.io/badge/Powered%20by-Chainlink-green)](https://chain.link/)
[![License: Unspecified](https://img.shields.io/badge/License-Unspecified-lightgrey.svg)](https://choosealicense.com/no-permission/)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/olujimiAdebakin/paynode-contract/actions)
[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
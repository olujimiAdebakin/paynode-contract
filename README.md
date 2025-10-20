# PayNode Smart Contracts 🌐

## 🌟 Project Overview

PayNode is a sophisticated, non-custodial payment aggregation protocol built on Solidity. It ingeniously connects users with multiple off-chain liquidity providers, enabling intelligent and parallel settlement routing. Unlike traditional systems that funnel transactions to a single provider, PayNode broadcasts settlement proposals simultaneously to eligible providers, with the first to accept executing the order. This architecture enhances efficiency, reduces bottlenecks, and introduces a dynamic intent-based system for liquidity providers. It leverages a modular design for core components like settings, access control, and gateway logic, ensuring a robust, secure, and upgradeable payment ecosystem.

## 🚀 Key Features

*   **Parallel Settlement:** Facilitates concurrent proposal broadcasting to multiple providers, allowing the fastest responder to execute the order and significantly accelerating transaction finality.
*   **Non-Custodial Escrow:** User funds are held securely in escrow within the smart contract until a settlement is successfully executed or refunded, ensuring maximum security and trust.
*   **Tier-Based Intelligent Routing:** Implements off-chain logic for smart routing based on order size, provider tier, capacity, and performance scores, optimizing for speed and reliability.
*   **Upgradeable Architecture (UUPS):** Utilizes OpenZeppelin's UUPS proxy pattern for seamless and secure contract upgrades, ensuring long-term maintainability and adaptability without service interruption.
*   **Timelocked Governance:** Critical administrative actions, including contract upgrades and role changes, are subject to a 48-hour timelock via `PayNodeAdmin`, enhancing security and community oversight.
*   **Role-Based Access Control (RBAC):** Granular permissions managed by `PayNodeAccessManager` define roles such as ADMIN, AGGREGATOR, PAUSER, and OPERATOR, enforcing strict operational boundaries.
*   **Provider Intent System:** Liquidity providers pre-register their capacity, currency support, and fee ranges, allowing the protocol to dynamically match orders with available liquidity.
*   **Reputation Scoring:** Tracks provider performance metrics (successful/failed orders, response times) to inform routing decisions and maintain a high-quality provider network.
*   **Emergency Pause & Blacklist:** Includes an emergency pause mechanism and a provider blacklisting system for rapid response to security incidents or malicious activity.
*   **Chainlink Automation Integration:** `PayNodeAdmin` integrates with Chainlink Keepers to automate the execution of timelocked upgrades once their delay period has passed.

## 🛠️ Technologies Used

| Technology         | Description                                                                 | Link                                                      |
| :----------------- | :-------------------------------------------------------------------------- | :-------------------------------------------------------- |
| Solidity           | High-level language for implementing smart contracts on the Ethereum platform. | [Solidity](https://soliditylang.org/)                     |
| Foundry            | Fast, portable, and modular toolkit for Ethereum application development.     | [Foundry](https://getfoundry.sh/)                         |
| OpenZeppelin       | Library of secure, community-vetted smart contracts for core functionalities. | [OpenZeppelin Contracts](https://openzeppelin.com/contracts/) |
| Chainlink          | Decentralized oracle network for smart contracts to securely interact with off-chain data and systems. | [Chainlink](https://chain.link/)                          |

## 📦 Getting Started

To set up and interact with the PayNode Smart Contracts locally, follow these steps:


## User
 ***│ **createOrder (amount + token)**
 ▼
## PGateway (escrow)
 ├─ Aggregator creates proposal
 │   └─ reserves provider intent
 ├─ Provider accepts
 │
## ▼ executeSettlement
**├─ protocolFee → Treasury**
 ***├─ providerAmount → Provider***
 │
 └─ order status = FULFILLED
 │
 ## └─ If no proposal or timeout → refundOrder → user gets funds back

### Prerequisites

*   **Git**: For cloning the repository.
*   **Foundry**: The development toolkit (Forge, Cast) for compiling, testing, and deploying Solidity contracts. Install it via `foundryup`:
    ```bash
    curl -L https://foundry.sh | bash
    foundryup
    ```

### Installation

*   ⬇️ **Clone the Repository:**
    Start by cloning the PayNode Contracts repository to your local machine:
    ```bash
    git clone https://github.com/olujimiAdebakin/paynode-contract.git
    cd paynode-contract
    ```
*   📥 **Install Foundry Dependencies:**
    Foundry uses `git submodules` for external libraries. Install them by running:
    ```bash
    forge install
    ```
*   🔗 **Initialize Git Submodules:**
    Ensure all linked submodules (like OpenZeppelin and Chainlink contracts) are correctly pulled:
    ```bash
    git submodule update --init --recursive
    ```
*   🔨 **Compile Contracts:**
    Compile the entire smart contract suite to ensure everything is set up correctly:
    ```bash
    forge build
    ```
    If compilation is successful, you are ready to proceed.

## 💡 Usage

The PayNode protocol is composed of several interdependent smart contracts that work together to enable the payment aggregation functionality. Understanding their roles is key to interaction.

### Core Contract Architecture

1.  **`PayNodeAccessManager`**: The foundation for all access control. It defines roles (`DEFAULT_ADMIN_ROLE`, `ADMIN_ROLE`, `AGGREGATOR_ROLE`, `OPERATOR_ROLE`, `FEE_MANAGER_ROLE`, etc.), manages user blacklists, and controls global system states (e.g., `pause`, `emergencyShutdown`).
2.  **`PayNodeAdmin` (Timelock Controller)**: This contract acts as the governance layer. It introduces a `MIN_DELAY` (2 days) for critical operations like contract upgrades and sensitive role changes. It also integrates with Chainlink Automation for automated execution of timelocked actions.
3.  **`PGatewaySettings`**: A central configuration hub for the entire protocol. It stores dynamic parameters such as `protocolFeePercent`, `orderExpiryWindow`, `proposalTimeout`, `treasuryAddress`, `aggregatorAddress`, and various `ALPHA`, `BETA`, `DELTA`, `OMEGA`, `TITAN` tier limits.
4.  **`PGateway` (Logic Contract via Proxy)**: The main engine of the PayNode protocol. It handles the full lifecycle of payment orders, from `createOrder` by a user to `executeSettlement` by an aggregator. It manages provider intents, settlement proposals, refunds, and maintains provider reputation metrics. This contract is deployed behind an `ERC1967Proxy` for upgradeability (UUPS).

### Local Deployment and Interaction Flow

To deploy and interact with the PayNode contracts on a local development chain (e.g., Anvil, Ganache) or a testnet:

1.  **Deployment Sequence:**
    The contracts must be deployed in a specific order to establish correct ownership and dependencies:
    *   Deploy `PayNodeAccessManager`.
    *   Deploy `PayNodeAdmin` (Timelock Controller), granting it ownership of the `AccessManager`.
    *   Deploy `PGatewaySettings`, granting its ownership to the `PayNodeAdmin`.
    *   Deploy `PGateway` (the implementation contract).
    *   Deploy an `ERC1967Proxy` pointing to the `PGateway` implementation, and then call the `initialize()` function on the proxy.
    *   Transfer ownership of the `PGateway` proxy (via `AccessManager`) to the `PayNodeAdmin` as well.

    *A robust deployment script (e.g., using `forge script`) would automate this sequence, handling initialization, role assignments, and ownership transfers.*

2.  **Provider Intent Registration:**
    Liquidity providers must first register their intent to participate in the network. This declares their available capacity, accepted currency, and fee preferences.
    ```solidity
    // Example: A provider registers an intent for 50,000 NGN equivalent,
    // with a minimum fee of 1% (100 BPS) and max of 3% (300 BPS),
    // and a 30-minute commitment window.
    PGateway(gatewayProxyAddress).registerIntent("NGN", 50_000 * 1e18, 100, 300, 30 * 60);
    ```

3.  **User Order Creation:**
    A user initiates a payment order by specifying the token, amount, and a refund address. The tokens are then transferred to the `PGateway` contract, and the order status becomes `PENDING`.
    ```solidity
    // Example: User wants to pay 1000 USDT. They first approve PGateway, then create the order.
    IERC20(usdtTokenAddress).approve(gatewayProxyAddress, 1000 * 1e6); // Assuming 6 decimals for USDT
    PGateway(gatewayProxyAddress).createOrder(usdtTokenAddress, 1000 * 1e6, userRefundWallet, "0xMessageHashSignedByUser");
    ```

4.  **Aggregator Proposal Generation:**
    Off-chain aggregators monitor pending orders, identify suitable providers based on their intents and reputation, and then create settlement proposals on-chain.
    ```solidity
    // Example: An aggregator proposes a settlement for a specific order to a provider.
    PGateway(gatewayProxyAddress).createProposal(orderId, providerAddress, 150); // Proposes 1.5% fee
    ```

5.  **Provider Proposal Acceptance/Rejection:**
    Providers evaluate proposals and decide whether to `acceptProposal` or `rejectProposal`. The first provider to accept for a given order wins the opportunity to fulfill it.
    ```solidity
    // Example: A provider accepts a proposal.
    PGateway(gatewayProxyAddress).acceptProposal(proposalId);
    ```

6.  **Settlement Execution:**
    Once a proposal is accepted, the aggregator triggers `executeSettlement`. The funds (minus protocol and provider fees) are transferred to the provider, and the order is marked as `FULFILLED`.
    ```solidity
    // Example: Aggregator executes the settlement for the accepted proposal.
    PGateway(gatewayProxyAddress).executeSettlement(acceptedProposalId);
    ```

7.  **Refunds:**
    If an order expires without acceptance or is intentionally cancelled, funds can be `refundOrder` by the aggregator or `requestRefund` by the user (under specific conditions).

## 🤝 Contributing

We warmly welcome contributions to the PayNode Smart Contracts! Whether you're fixing a bug, proposing a new feature, or improving documentation, your efforts are valued.

*   ➡️ **Fork the Repository:** Start by forking the `paynode-contract` repository.
*   🌿 **Create a Branch:** Create a new branch for your feature or bug fix: `git checkout -b feature/your-feature-name` or `bugfix/issue-description`.
*   ✍️ **Code & Test:** Implement your changes and write comprehensive tests to ensure functionality and prevent regressions.
*   ✅ **Lint & Format:** Ensure your code adheres to the project's style guidelines. Foundry's `forge fmt` can help.
*   ⬆️ **Commit & Push:** Commit your changes with clear, descriptive messages and push them to your forked repository.
*   ✉️ **Submit a Pull Request:** Open a pull request to the `main` branch of the original repository. Provide a detailed description of your changes and why they are necessary.

## 👤 Author

**Olujimi Adebakin**
*   LinkedIn: [Your LinkedIn Profile]
*   Twitter: [Your Twitter Handle]

---

## ✨ Badges

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/olujimiAdebakin/paynode-contract/Foundry?logo=github&style=flat-square)](https://github.com/olujimiAdebakin/paynode-contract/actions)
[![Solidity Version](https://img.shields.io/badge/Solidity-0.8.18%20%2B-blueviolet.svg?style=flat-square&logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Made%20with-Foundry-red.svg?style=flat-square&logo=foundry)](https://getfoundry.sh/)
[![OpenZeppelin](https://img.shields.io/badge/Powered%20by-OpenZeppelin-blue.svg?style=flat-square&logo=openzeppelin)](https://openzeppelin.com/contracts/)
[![Chainlink](https://img.shields.io/badge/Integrated%20with-Chainlink-green.svg?style=flat-square&logo=chainlink)](https://chain.link/)

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
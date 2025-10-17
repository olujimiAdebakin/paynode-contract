⚡ PayNode Smart Contract Protocol

Welcome to PayNode, a cutting-edge, non-custodial payment aggregation protocol built on Solidity. This system revolutionizes peer-to-peer and business settlements by intelligently routing transactions through a network of liquidity providers, enabling parallel execution for unparalleled speed and efficiency. Designed with robust security, upgradeability, and granular access control, PayNode ensures transparent and reliable on-chain operations.

---

## 🚀 Overview

PayNode is a sophisticated smart contract suite providing a non-custodial payment aggregation layer. It connects users with multiple off-chain liquidity providers, facilitating intelligent, parallel settlement routing. Orders are broadcast simultaneously to eligible providers, with the first to accept executing the transaction, eliminating bottlenecks and optimizing transaction flow. The architecture leverages modular components for access control, configuration, and core gateway logic, all secured with a timelocked, upgradeable governance structure.

---

## ✨ Features

*   **Non-Custodial Escrow**: User funds are securely held in escrow within the smart contract until a settlement is successfully executed or refunded, ensuring funds are never directly controlled by the protocol.
*   **Parallel Settlement**: Settlement proposals are broadcast to multiple eligible liquidity providers simultaneously, allowing for competitive execution and faster transaction finalization.
*   **Tier-Based Intelligent Routing**: Orders are dynamically categorized into tiers (Alpha, Beta, Delta, Omega, Titan) based on their value, enabling the off-chain aggregator to apply optimized routing strategies and select the most suitable providers.
*   **Modular Architecture**: The protocol is designed with distinct, interconnected contract layers: `AccessManager` (permissions), `TimelockAdmin` (governance), `PGatewaySettings` (configuration), and `PGateway` (core logic).
*   **Upgradeable & Secure Governance**: Utilizes the UUPS proxy pattern and a `TimelockAdmin` with a 48-hour delay for critical upgrades, preventing instant malicious changes and ensuring community oversight.
*   **Role-Based Access Control (RBAC)**: Fine-grained permissions managed by `PayNodeAccessManager` define roles such as `ADMIN_ROLE`, `OPERATOR_ROLE`, `AGGREGATOR_ROLE`, and `FEE_MANAGER_ROLE` for enhanced security.
*   **Provider Intent System**: Liquidity providers pre-register their available capacity, preferred fees, and commitment windows, allowing the aggregator to match orders efficiently.
*   **Dynamic Reputation Scoring**: Tracks provider performance, including successful orders, settlement times, and no-show counts, to inform routing decisions and maintain network quality.
*   **Emergency Pause & Blacklisting**: Critical safeguards include a global pause mechanism and a provider blacklisting system to mitigate risks and protect users during unforeseen events or fraudulent activity.
*   **Chainlink Automation Integration**: Automated upkeep ensures timely execution of scheduled contract upgrades and other critical maintenance tasks via Chainlink Keepers.

---

## 🛠️ Technologies Used

| Technology             | Description                                          |
| :--------------------- | :--------------------------------------------------- |
| **Solidity**           | Smart contract language for Ethereum and EVM chains. |
| **Foundry**            | Fast, customizable, and comprehensive toolkit for Ethereum smart contract development (build, test, deploy, verify). |
| **OpenZeppelin Contracts** | Industry-standard libraries for secure smart contract development (access control, upgradeability, utilities). |
| **Chainlink Automation** | Decentralized, hyper-reliable automation for smart contracts. |

---

## 🚀 Getting Started

Follow these steps to get your local development environment set up and interact with the PayNode smart contracts.

### Installation

1.  **Clone the Repository**:
    Begin by cloning the PayNode contract repository to your local machine:

    ```bash
    git clone https://github.com/olujimiAdebakin/paynode-contract.git
    cd paynode-contract
    ```

2.  **Install Foundry**:
    PayNode uses Foundry for its development workflow. If you don't have Foundry installed, follow the official instructions:

    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3.  **Install Dependencies**:
    Navigate to the project directory and install the required OpenZeppelin and Chainlink submodules using `forge`:

    ```bash
    forge install
    ```

4.  **Build the Contracts**:
    Compile the smart contracts to ensure everything is set up correctly:

    ```bash
    forge build
    ```

### Environment Variables

While local testing often doesn't require extensive `.env` files, for deployment or more complex local networks, you might need variables like `RPC_URL` and `PRIVATE_KEY`.

---

## 💡 Usage

This section guides you through deploying and interacting with the PayNode protocol.

### Local Development and Testing

You can run the automated tests to verify the contract logic and functionality:

```bash
forge test
```

### Deployment Flow

The `PayNode.sol` contract in `src/main` acts as a central deployment script, orchestrating the deployment and initialization of all core PayNode components in a specific order:

1.  **Deploy `PayNodeAccessManager`**: The foundation for role-based access control and system state.
2.  **Deploy `PayNodeAdmin` (Timelock)**: The governance contract responsible for managing upgrades with a timelock.
3.  **Deploy `PGatewaySettings`**: Configures protocol-wide parameters like fees, tier limits, and treasury addresses.
4.  **Deploy `PGateway` (Implementation)**: The actual logic contract for the payment gateway.
5.  **Deploy `ERC1967Proxy` for `PGateway`**: Sets up the upgradeable proxy pointing to the `PGateway` implementation.
6.  **Transfer Ownership**: Key ownership roles (e.g., `PayNodeAccessManager`, `PGatewaySettings`) are transferred to the `TimelockAdmin` for decentralized, timelocked governance.

You can simulate this deployment locally using Foundry's scripting capabilities:

```bash
# Example: Deploy to a local Anvil instance
# Start Anvil: anvil
# Then run the script:
forge script script/DeployPayNode.s.sol --rpc-url http://127.0.0.1:8545 --private-key <YOUR_PRIVATE_KEY> --broadcast
```

### Protocol Interaction

The PayNode protocol involves several key roles:

*   **User**: Initiates payment orders.
*   **Provider**: Offers liquidity, registers intent, and accepts/rejects settlement proposals.
*   **Aggregator**: An off-chain entity responsible for determining order tiers, routing proposals to providers, and executing settlements.
*   **Admin**: Manages system flags, blacklists, and schedules upgrades via the timelock.

Here's a high-level interaction flow:

1.  **Provider Registers Intent**:
    A liquidity provider uses the `registerIntent` function on `PGateway` to declare their available capacity, supported currency, fee range, and commitment window.
2.  **User Creates Order**:
    A user calls `createOrder` on `PGateway`, specifying the token, amount, and a refund address. Their funds are transferred into the gateway's escrow.
3.  **Aggregator Creates Proposal**:
    The off-chain aggregator identifies suitable providers based on the order's tier and available intents. It then calls `createProposal` on `PGateway` for multiple providers simultaneously.
4.  **Provider Accepts Proposal**:
    The first provider to respond accepts a proposal via `acceptProposal` on `PGateway`. This locks the order to that provider and updates the order status.
5.  **Aggregator Executes Settlement**:
    Once a proposal is accepted, the aggregator calls `executeSettlement` on `PGateway`. This triggers the transfer of the protocol fee to the treasury and the remaining amount to the fulfilling provider, marking the order as fulfilled.
6.  **Refunds**:
    If an order expires without acceptance or is manually canceled by the user (within specific conditions), the `refundOrder` or `requestRefund` functions can be called to return funds to the user.

---

## 🤝 Contributing

We welcome contributions to the PayNode Smart Contract Protocol! To contribute:

*   **Fork the repository**.
*   **Create a new branch** for your feature or bug fix.
*   **Write clean, well-documented code** following existing coding standards.
*   **Ensure all tests pass** (`forge test`) and add new tests for your changes.
*   **Submit a pull request** with a clear description of your changes.

---

## 📄 License

This project is released under the MIT License, as indicated by SPDX identifiers within the source code.

---

## 👤 Author

**Olujimi**

*   LinkedIn: [https://www.linkedin.com/in/YOUR_LINKEDIN_USERNAME](https://www.linkedin.com/in/YOUR_LINKEDIN_USERNAME)
*   Twitter: [https://twitter.com/YOUR_TWITTER_USERNAME](https://twitter.com/YOUR_TWITTER_USERNAME)

---

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.18-blue)](https://docs.soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Build%20with-Foundry-red)](https://getfoundry.sh/)
[![OpenZeppelin](https://img.shields.io/badge/Powered%20by-OpenZeppelin-lightgray)](https://docs.openzeppelin.com/contracts/4.x/)

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
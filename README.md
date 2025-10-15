# PayNode Smart Contracts: Decentralized Payment Aggregation 💸

PayNode is an innovative, non-custodial payment aggregation protocol designed to revolutionize off-chain settlement. It intelligently routes payment proposals across multiple liquidity providers in parallel, ensuring efficient and rapid transaction execution. By broadcasting settlement requests simultaneously, PayNode eliminates bottlenecks associated with single-provider transactions, with the first eligible provider to accept executing the order.

This project is built on Solidity smart contracts, focusing on modularity, security, and robust governance, making it a cornerstone for future-proof decentralized finance solutions.

## Overview

The PayNode Smart Contracts implement a non-custodial payment aggregation system on the Ethereum Virtual Machine (EVM). It enables users to create orders, which are then routed to multiple off-chain liquidity providers for parallel settlement. The architecture leverages OpenZeppelin's upgradeable contracts, role-based access control, and a timelocked administration system for secure, transparent, and resilient operations. Key components include an Access Manager, Timelock Admin for governance, a Gateway Settings contract for configuration, and the main Gateway contract for order lifecycle management, provider intent registration, and settlement execution.

## Features

*   **Non-Custodial Escrow**: User funds are held securely in the contract's escrow until settlement or refund, ensuring trustless operations.
*   **Parallel Settlement**: Expedites transactions by enabling multiple liquidity providers to race to accept and fulfill an order simultaneously.
*   **Intelligent Tier-Based Routing**: Orders are categorized into tiers (Small, Medium, Large) based on amount, allowing off-chain aggregators to optimize routing strategies for speed and reliability.
*   **Provider Intent System**: Liquidity providers pre-register their capacity, fee ranges, and commitment windows, allowing the system to efficiently match orders.
*   **Robust Access Control**: Implemented via `PayNodeAccessManager` using OpenZeppelin's `AccessControlUpgradeable`, defining granular roles (Admin, Operator, Platform Service) for secure management.
*   **Timelocked Governance & Upgrades**: Critical administrative changes and contract upgrades are secured with a 48-hour timelock via `PayNodeAdmin` (extending `TimelockController`), preventing instant malicious modifications.
*   **Emergency Pause Mechanism**: A system-wide pause and emergency shutdown capability for immediate response to critical security events.
*   **Provider Reputation System**: Tracks successful and failed orders, no-show counts, and settlement times to inform routing decisions and identify fraudulent actors.
*   **Flexible Configuration**: `PGatewaySettings` allows dynamic adjustment of protocol fees, order expiry windows, proposal timeouts, and tier limits by authorized administrators.
*   **Blacklisting**: Mechanism to blacklist malicious or underperforming providers, enhancing network integrity.
*   **Chainlink Automation Integration**: `PayNodeAdmin` is designed for seamless integration with Chainlink Keepers to automate the execution of scheduled upgrades after their timelock.

## Getting Started

To set up the PayNode Smart Contracts locally, you'll need `Foundry`, a fast, portable, and modular toolkit for Ethereum application development written in Rust.

### Installation

```bash
# Clone the repository
git clone https://github.com/olujimiAdebakin/paynode-contract.git
cd paynode-contract
```

#### Install Foundry

If you don't have Foundry installed, run the following command:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

#### Install Dependencies
Navigate into the cloned repository and install the project dependencies using `forge`:
```bash
forge install
```

#### Compile Contracts
Compile the smart contracts to ensure everything is set up correctly:
```bash
forge build
```

#### Run Tests (Optional)
To verify the contract logic and security, you can run the provided test suite:
```bash
forge test
```

## Usage

The PayNode protocol operates through a series of interactions between users, liquidity providers, and an off-chain aggregator, orchestrated by the smart contracts. Below is an outline of the primary contract interactions and the general workflow.

### Deployment Sequence

The PayNode system follows a specific deployment order to establish its interconnected components:

1.  **`PayNodeAccessManager`**: Deployed first to establish the foundational access control and role management.
2.  **`PayNodeAdmin` (Timelock Controller)**: Deployed with the `AccessManager` as its owner, enabling timelocked governance over critical operations.
3.  **`PGatewaySettings`**: Deployed to hold all configurable parameters (fees, tier limits, etc.).
4.  **`PGateway` (Implementation)**: The core logic contract, deployed as an implementation.
5.  **`ERC1967Proxy`**: A UUPS proxy is deployed, pointing to the `PGateway` implementation. All interactions with the Gateway should go through this proxy.
6.  **`initialize()`**: The `initialize` function on the `PGateway` proxy is called to set up its initial state, linking it to the `AccessManager` and `PGatewaySettings`.
7.  **Ownership Transfer**: The ownership of `PayNodeAccessManager` and `PGatewaySettings` is transferred to `PayNodeAdmin` (the timelock controller) to centralize governance under a timelocked mechanism.

### Core Protocol Flow

PayNode facilitates a non-custodial payment aggregation with a parallel settlement mechanism. Here’s how a typical order is processed:

1.  **User Creates Order**:
    *   A user initiates a payment by calling `createOrder(token, amount, refundAddress)` on the `PGateway` proxy.
    *   Their tokens are transferred to the Gateway contract's escrow.
    *   The order is assigned a unique `orderId` and marked `PENDING`.

2.  **Provider Registers Intent**:
    *   Liquidity providers register their availability and terms by calling `registerIntent(currency, availableAmount, minFeeBps, maxFeeBps, commitmentWindow)` on the `PGateway` proxy.
    *   This intent can be updated via `updateIntent()` or expire if not refreshed.

3.  **Aggregator Creates Proposals**:
    *   An off-chain aggregator (authorized with `AGGREGATOR_ROLE` via `AccessManager`) monitors pending orders and active provider intents.
    *   Based on order tier, provider reputation, and capacity, the aggregator selects suitable providers and broadcasts `createProposal(orderId, provider, proposedFeeBps)` to multiple providers in parallel.
    *   This reserves the provider's capacity for the proposed amount.

4.  **Providers Race to Accept**:
    *   The first provider to accept a proposal for a given order calls `acceptProposal(proposalId)`.
    *   Other proposals for the same order are automatically implicitly rejected by the system.
    *   The order status changes to `ACCEPTED`.

5.  **Aggregator Executes Settlement**:
    *   Once a proposal is accepted, the aggregator calls `executeSettlement(proposalId)`.
    *   Protocol fees are calculated and transferred to the treasury, and the remaining amount (minus provider fees) is transferred to the accepting provider.
    *   The order status changes to `FULFILLED`, and provider reputation is updated.

6.  **Refunds**:
    *   If an order expires without any accepted proposals, the aggregator can call `refundOrder(orderId)` to return funds to the user's `refundAddress`.
    *   Users can also request a refund manually via `requestRefund(orderId)` if the order is still PENDING or PROPOSED and has expired.

### Admin and Governance Operations

*   **Role Management**: `PayNodeAccessManager` provides functions like `setBlacklistStatus()`, `scheduleAdminChange()`, `executeAdminChange()`, and `cancelAdminChange()` to manage roles and critical admin addresses with a timelock.
*   **System State Control**: `emergencyShutdown()`, `restoreSystem()`, `pause()`, and `unpause()` in `PayNodeAccessManager` allow administrators to control the system's operational status.
*   **Contract Upgrades**: `PayNodeAdmin` allows for `scheduleUpgrade()`, `cancelUpgrade()`, and `performUpgrade()` to manage UUPS proxy upgrades with a mandatory timelock.
*   **Gateway Configuration**: The `PGateway` (via `PGatewaySettings`) allows the owner (which will be `PayNodeAdmin` after deployment) to update parameters such as `setProtocolFee()`, `setTierLimits()`, `setOrderExpiryWindow()`, `setProposalTimeout()`, `setTreasuryAddress()`, `setAggregatorAddress()`, and `setSupportedToken()`.

## Technologies Used

| Technology                                                 | Description                                                                                                                                     |
| :--------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------- |
| [**Solidity**](https://soliditylang.org/)                  | Primary language for developing secure and robust smart contracts.                                                                              |
| [**Foundry**](https://book.getfoundry.sh/)                 | Blazing fast toolkit for Ethereum development, used for compiling, testing, and deploying contracts.                                            |
| [**OpenZeppelin Contracts**](https://docs.openzeppelin.com/contracts/4.x/) | Industry-standard libraries for secure smart contract development, including upgradeability, access control, and utility contracts. |
| [**Chainlink Automation (Keepers)**](https://docs.chain.link/chainlink-automation/introduction/) | Decentralized oracle network service used for automating smart contract functions, specifically for timed upgrades in `PayNodeAdmin`. |
| **EVM (Ethereum Virtual Machine)**                         | The runtime environment for executing smart contract code.                                                                                      |

## Contributing

We welcome contributions to the PayNode Smart Contracts! If you're interested in improving the protocol, please follow these guidelines:

*   ✨ **Fork the repository**: Start by forking the `paynode-contract` repository.
*   🌿 **Create a new branch**: For each new feature or bug fix, create a dedicated branch (e.g., `feature/add-reputation-score`, `bugfix/fix-order-refund`).
*   📝 **Write clear commit messages**: Follow conventional commits for consistent and readable history.
*   🧪 **Add comprehensive tests**: Ensure your changes are well-covered by unit and integration tests using Foundry.
*   💡 **Submit a Pull Request**: Once your changes are complete and tested, submit a pull request to the `main` branch. Provide a detailed description of your changes and their impact.
*   🗣️ **Engage in discussions**: Be prepared to discuss your changes and address any feedback during the review process.

## License

This project is open-source and licensed under the MIT License.

## Author Info

**Olujimi**

Connect with me:

*   LinkedIn: [Your_LinkedIn_Profile]
*   Twitter: [Your_Twitter_Handle]

---

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.18-blueviolet.svg)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-Rust-red.svg)](https://book.getfoundry.sh/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-Contracts-purple.svg)](https://docs.openzeppelin.com/contracts/4.x/)
[![Chainlink Automation](https://img.shields.io/badge/Chainlink-Automation-green.svg)](https://chain.link/solutions/automation)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/olujimiAdebakin/paynode-contract/actions)

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
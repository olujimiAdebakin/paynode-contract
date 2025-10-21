# PayNode Smart Contracts ⚡

## Overview
PayNode is an innovative non-custodial payment aggregation protocol built on Solidity, designed to streamline and accelerate settlement routing. It intelligently connects users to multiple off-chain liquidity providers, broadcasting settlement proposals simultaneously to achieve rapid, parallel order execution. This robust system features a modular architecture, tiered access control, non-custodial escrow, and a secure, timelocked upgrade mechanism.

## Features
*   **Non-Custodial Escrow**: Funds are securely held in escrow within the smart contract until settlement, ensuring user safety and trust.
*   **Parallel Settlement Engine**: Enables multiple liquidity providers to race in accepting settlement proposals, drastically reducing transaction times.
*   **Role-Based Access Control (RBAC)**: Implemented via `PayNodeAccessManager` with roles like `ADMIN_ROLE`, `OPERATOR_ROLE`, `AGGREGATOR_ROLE`, and `DISPUTE_MANAGER_ROLE` for granular permission management.
*   **Upgradeable Architecture (UUPS)**: Utilizes OpenZeppelin's UUPS proxy pattern combined with a `TimelockAdmin` for secure, delayed contract upgrades, preventing instantaneous malicious changes.
*   **Tier-Based Intelligent Routing**: Off-chain aggregators can route orders to providers based on order size tiers (Alpha, Beta, Delta, Omega, Titan), optimizing for speed and capacity.
*   **Provider Intent Registry**: Liquidity providers can register and update their available capacity, fee ranges, and commitment windows.
*   **Reputation System**: Tracks provider performance, including successful orders, failed orders, and no-show counts, enabling data-driven provider selection.
*   **Emergency Controls**: Features `Pausable` functionality and a global `systemLocked` state for immediate emergency shutdowns and controlled system restoration.
*   **Integrator Self-Service**: Allows dApps and partners to register as integrators, set their own fees, and manage their profile on-chain.
*   **Replay Attack Protection**: Incorporates `_messageHash` to prevent replay attacks for order creation.
*   **Chainlink Automation Integration**: The `PayNodeAdmin` contract is designed to work with Chainlink Keepers for automated, timelocked execution of scheduled upgrades.

## Getting Started

### Installation

To set up the PayNode Smart Contracts locally, follow these steps:

1.  ### 👯 Clone the Repository
    ```bash
    git clone https://github.com/olujimiAdebakin/paynode-contract.git
    cd paynode-contract
    ```

2.  ### 📦 Install Foundry
    Ensure you have [Foundry](https://github.com/foundry-rs/foundry) installed. If not, you can install it using `foundryup`:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3.  ### 📚 Install Dependencies
    This project uses OpenZeppelin and Chainlink libraries. Install them via `forge`:
    ```bash
    forge install
    ```

4.  ### 🛠️ Build the Project
    Compile the smart contracts:
    ```bash
    forge build
    ```

## Usage

### Running Tests
To ensure all contracts are functioning as expected, run the comprehensive test suite:
```bash
forge test
```

### Deploying Contracts
Deployment typically involves a sequence of steps, often managed by a deployment script. Below is a conceptual order for deploying the core PayNode contracts. *Note: Actual deployment would require a script interacting with a blockchain network (e.g., Anvil, Sepolia, Mainnet) and managing private keys.*

1.  **Deploy `PayNodeAccessManager`**:
    This contract is the foundation for role-based access control.
    ```bash
    forge create src/access/PAccessManager.sol:PayNodeAccessManager \
      --rpc-url <YOUR_RPC_URL> \
      --private-key <YOUR_PRIVATE_KEY> \
      --constructor-args <_pasarAdmin_address> <_superAdmin_address> <operators_array>
    ```
    *   `_pasarAdmin_address`: The address of the `PayNodeAdmin` contract (will be deployed next, can be placeholder then updated).
    *   `_superAdmin_address`: The address that will hold `DEFAULT_ADMIN_ROLE`.
    *   `operators_array`: An array of addresses for `OPERATOR_ROLE`.

2.  **Deploy `PayNodeAdmin` (Timelock Controller)**:
    This contract manages upgrades and role changes with a timelock.
    ```bash
    forge create src/admin/PAdmin.sol:PayNodeAdmin \
      --rpc-url <YOUR_RPC_URL> \
      --private-key <YOUR_PRIVATE_KEY> \
      --constructor-args <proposers_array> <executors_array> <superAdmin_address> <upgradeAdmin_address> <chainlinkKeeper_address>
    ```
    *   `proposers_array`, `executors_array`, `superAdmin_address`: Roles for the timelock itself.
    *   `upgradeAdmin_address`: Address to receive the `ADMIN_ROLE` for scheduling upgrades.
    *   `chainlinkKeeper_address`: Address of the Chainlink Keeper.

3.  **Deploy `PGatewaySettings`**:
    This contract holds all configurable parameters for the gateway.
    ```bash
    forge create src/gateway/PGatewaySettings.sol:PGatewaySettings \
      --rpc-url <YOUR_RPC_URL> \
      --private-key <YOUR_PRIVATE_KEY> \
      --constructor-args \
      --init-args <initialOwner> <treasury> <aggregator> <protocolFee> <alphaLimit> <betaLimit> <deltaLimit> <integrator> <integratorFee> <omegaLimit> <titanLimit> <orderExpiryWindow> <proposalTimeout> <intentExpiry>
    ```

4.  **Deploy `PGateway` Implementation & Proxy**:
    Deploy the core logic, then an `ERC1967Proxy` pointing to it, and `initialize` the proxy.
    ```bash
    # Deploy implementation
    forge create src/gateway/PGateway.sol:PGateway \
      --rpc-url <YOUR_RPC_URL> \
      --private-key <YOUR_PRIVATE_KEY>

    # Deploy proxy (replace <gateway_implementation_address>)
    forge create @openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol:ERC1967Proxy \
      --rpc-url <YOUR_RPC_URL> \
      --private-key <YOUR_PRIVATE_KEY> \
      --constructor-args <gateway_implementation_address> <encoded_initialize_data>
    ```
    *   `<encoded_initialize_data>`: `abi.encodeWithSelector(PGateway.initialize.selector, _accessManager_address, _settings_address)`

5.  **Transfer Ownerships**:
    Finally, transfer ownership of `PayNodeAccessManager` and `PGatewaySettings` to the `PayNodeAdmin` (Timelock) for secure governance.

### Interacting with Contracts
Once deployed, you can interact with the contracts using `cast` (Foundry's CLI tool) or through a dApp frontend.

**Example: Registering a Provider Intent**
```bash
cast send <PGATEWAY_PROXY_ADDRESS> "registerIntent(string,uint256,uint64,uint64,uint256)" \
  "NGN" 100000000000000000000 100 500 3600 \
  --private-key <PROVIDER_PRIVATE_KEY> --rpc-url <YOUR_RPC_URL>
```

**Example: Creating an Order**
```bash
cast send <PGATEWAY_PROXY_ADDRESS> "createOrder(address,uint256,address,address,uint64,bytes32)" \
  <ERC20_TOKEN_ADDRESS> 50000000000000000000 <REFUND_ADDRESS> <INTEGRATOR_ADDRESS> 100 <MESSAGE_HASH_BYTES32> \
  --private-key <USER_PRIVATE_KEY> --rpc-url <YOUR_RPC_URL>
```

## Technologies Used

| Category         | Technology                 | Description                                                  | Link                                                                  |
| :--------------- | :------------------------- | :----------------------------------------------------------- | :-------------------------------------------------------------------- |
| **Development**  | Solidity                   | Object-oriented programming language for writing smart contracts. | [Solidity Docs](https://docs.soliditylang.org/)                       |
| **Framework**    | Foundry                    | Blazing fast, portable, and modular toolkit for Ethereum application development. | [Foundry Docs](https://book.getfoundry.sh/)                           |
| **Libraries**    | OpenZeppelin Contracts     | Secure and community-audited smart contract implementations for common patterns. | [OpenZeppelin](https://docs.openzeppelin.com/contracts/4.x/)          |
| **Automation**   | Chainlink Automation       | Decentralized oracle network providing external data and computation. | [Chainlink Automation](https://docs.chain.link/chainlink-automation/) |
| **Architecture** | UUPS Proxy Pattern         | Standard for upgradeable smart contracts to fix bugs and add features. | [UUPS Proxy](https://docs.openzeppelin.com/contracts/4.x/api/proxy#UUPSUpgradeable) |

## Contributing

We welcome contributions to the PayNode Smart Contracts project! If you're interested in improving the protocol, please follow these guidelines:

*   🐛 **Bug Reports**: If you find a bug, please open an issue describing the problem and steps to reproduce.
*   💡 **Feature Requests**: Suggest new features by opening an issue. Explain the motivation and potential benefits.
*   🤝 **Pull Requests**:
    *   Fork the repository and create a new branch for your feature or bug fix.
    *   Ensure your code adheres to the existing coding style and passes all tests.
    *   Write clear commit messages and a detailed description of your changes in the pull request.
    *   All contributions should respect the project's security and upgradeability standards.

## License
This project is licensed under the MIT License.

## Author Info

Connect with the author:

*   **Olujimi**: [LinkedIn](https://linkedin.com/in/olujimi) | [Twitter](https://twitter.com/olujimi)

---

[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
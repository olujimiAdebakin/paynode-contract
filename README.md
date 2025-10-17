# PayNode Protocol Contracts ⚡

## Overview
PayNode is a sophisticated non-custodial payment aggregation protocol designed for intelligent, parallel settlement routing across multiple off-chain liquidity providers. Built with Solidity, Foundry, and OpenZeppelin, this system minimizes transaction bottlenecks by simultaneously broadcasting settlement proposals to eligible providers, ensuring the fastest execution.

## Features
*   ✨ **Parallel Settlement:** Enables multiple liquidity providers to race to accept and fulfill orders, optimizing for speed and efficiency.
*   🔒 **Non-Custodial Escrow:** Funds are securely held in escrow within the smart contract until settlement, ensuring user assets are protected.
*   🧠 **Tier-Based Intelligent Routing:** Leverages an off-chain aggregator to categorize orders by amount and route them to appropriate provider tiers, optimizing for capacity and reputation.
*   ⚙️ **Upgradeable Architecture:** Implements the UUPS proxy pattern combined with a Timelock Controller for secure, governed contract upgrades with a mandatory 48-hour delay.
*   🔑 **Role-Based Access Control (RBAC):** Granular permissions managed by `AccessManager`, assigning specific roles (Admin, Aggregator, Pauser) to control critical functions.
*   🚫 **Provider Blacklisting & Reputation:** System for tracking provider performance, flagging fraudulent activity, and blacklisting malicious entities to maintain ecosystem integrity.
*   ⏸️ **Emergency Pause:** A global pause mechanism for the entire protocol, allowing administrators to halt operations during emergencies or maintenance.
*   🔗 **Chainlink Automation Integration:** Utilizes Chainlink Keepers (now Automation) for automated execution of scheduled upgrades and other time-sensitive tasks.

## Getting Started

To get started with the PayNode Protocol Contracts, follow the steps below to set up your local development environment and deploy the contracts.

### Installation
1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/olujimiAdebakin/paynode-contract.git
    cd paynode-contract
    ```

2.  **Install Foundry:**
    If you don't have Foundry installed, follow the instructions on the official [Foundry Book](https://book.getfoundry.sh/getting-started/installation).
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3.  **Install Dependencies:**
    Foundry uses git submodules to manage dependencies. Initialize and update them:
    ```bash
    forge update
    ```

4.  **Build Contracts:**
    Compile the smart contracts using `forge build`:
    ```bash
    forge build
    ```
    This will compile all `.sol` files in the `src` directory and output artifacts to `out/`.

### Environment Variables
While direct environment variables aren't typically configured *within* Solidity contracts for deployment, a deployment script (which would usually be in a separate `script` directory in a Foundry project) would require the following:

*   `PRIVATE_KEY`: Private key of the deployer address (e.g., `0x...`)
*   `RPC_URL`: RPC endpoint for the network to deploy to (e.g., `https://mainnet.infura.io/v3/YOUR_PROJECT_ID`)

**Example `.env` file structure (for deployment scripts):**
```
PRIVATE_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bac478cbf5e7bb81002084ee5113076" # Example: Anvil private key
RPC_URL="http://127.0.0.1:8545" # Example: Anvil local RPC
```

## Usage

The PayNode Protocol consists of several interconnected smart contracts designed for robust, secure, and upgradeable operation. Below are instructions on deploying the system and interacting with its core components.

### 🚀 Deploying the Entire System

The `PayNode.sol` contract acts as a central deployer for the entire protocol stack. This streamlines the initial setup process.

1.  **Start a Local Blockchain (e.g., Anvil):**
    Open a new terminal and run:
    ```bash
    anvil
    ```
    This will provide a local RPC endpoint (e.g., `http://127.0.0.1:8545`) and accounts with pre-funded ETH.

2.  **Deploy `PayNode.sol` and the Ecosystem:**
    You would typically write a deployment script (e.g., in `script/DeployPayNode.s.sol`) that uses `forge script`. For demonstration, here’s a conceptual interaction:
    ```solidity
    // Example conceptual deployment script logic in a Foundry script
    import "forge-std/Script.sol";
    import "../src/main/PayNode.sol";
    import "../src/interface/IAccessManager.sol";
    import "../src/interface/IPGatewaySettings.sol";
    import "../src/interface/IPGateway.sol";
    
    contract DeployPayNode is Script {
        function run() external returns (address accessManager, address timelockAdmin, address gatewaySettings, address gatewayProxy) {
            vm.startBroadcast();
    
            address _owner = vm.addr(0x70997970C51812dc3A01088e6d492B4eecbAb809); // Anvil default account 0
            address _aggregator = vm.addr(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC); // Anvil default account 1
            address _treasury = vm.addr(0x90F79bf6EB2c4f870365E011ee64d530DFdC3a0D); // Anvil default account 2
    
            PayNode deployer = new PayNode();
            deployer.deploySystem(_owner, _aggregator, _treasury);
    
            accessManager = deployer.accessManager();
            timelockAdmin = deployer.timelockAdmin();
            gatewaySettings = deployer.gatewaySettings();
            gatewayProxy = deployer.gatewayProxy();
    
            console.log("AccessManager deployed at:", accessManager);
            console.log("TimelockAdmin deployed at:", timelockAdmin);
            console.log("PGatewaySettings deployed at:", gatewaySettings);
            console.log("PGateway (Proxy) deployed at:", gatewayProxy);
    
            vm.stopBroadcast();
        }
    }
    ```
    To run a script like this with `forge`:
    ```bash
    forge script script/DeployPayNode.s.sol:DeployPayNode --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bac478cbf5e7bb81002084ee5113076 --broadcast
    ```
    Replace `0xac0974bec39a17e36ba4a6b4d238ff944bac478cbf5e7bb81002084ee5113076` with a private key from your Anvil output that corresponds to the `_owner` address.

### 📝 Interacting with Core Contracts

After deployment, you interact with the proxy address for the `PGateway` and the directly deployed `AccessManager` and `PGatewaySettings` contracts.

#### **PayNodeAccessManager (RBAC & System Control)**
The `AccessManager` handles critical roles, blacklisting, and emergency controls.

*   **Granting Roles:**
    Only the `DEFAULT_ADMIN_ROLE` can grant or revoke roles.
    ```solidity
    // Example: Grant AGGREGATOR_ROLE to an address
    // Assuming 'accessManagerContract' is an instance of IPayNodeAccessManager
    function grantAggregatorRole(IPayNodeAccessManager accessManagerContract, address newAggregatorAddress) public {
        bytes32 aggregatorRole = accessManagerContract.AGGREGATOR_ROLE();
        accessManagerContract.grantRole(aggregatorRole, newAggregatorAddress);
    }
    ```
*   **Blacklisting a User:**
    An `OPERATOR_ROLE` holder can blacklist users.
    ```solidity
    // Example: Blacklist a user
    // Assuming 'accessManagerContract' is an instance of IPayNodeAccessManager
    function blacklistUser(IPayNodeAccessManager accessManagerContract, address userToBlacklist) public {
        accessManagerContract.setBlacklistStatus(userToBlacklist, true);
    }
    ```
*   **Emergency Shutdown:**
    Only the `DEFAULT_ADMIN_ROLE` can initiate an emergency shutdown.
    ```solidity
    // Example: Trigger emergency shutdown
    // Assuming 'accessManagerContract' is an instance of IPayNodeAccessManager
    function triggerShutdown(IPayNodeAccessManager accessManagerContract) public {
        accessManagerContract.emergencyShutdown();
    }
    ```

#### **PGatewaySettings (Protocol Configuration)**
This contract centralizes configurable parameters for the PayNode Gateway.

*   **Setting Protocol Fees:**
    Only the `owner` (initially `TimelockAdmin` after deployment) can set fees.
    ```solidity
    // Example: Set protocol fee to 0.1% (100 bps)
    // Assuming 'gatewaySettingsContract' is an instance of IPGatewaySettings
    function setFees(IPGatewaySettings gatewaySettingsContract, uint64 newFeeBps) public {
        gatewaySettingsContract.setProtocolFee(newFeeBps); // e.g., 100 for 0.1%
    }
    ```
*   **Managing Supported Tokens:**
    ```solidity
    // Example: Add USDC as a supported token
    // Assuming 'gatewaySettingsContract' is an instance of IPGatewaySettings
    function addSupportedToken(IPGatewaySettings gatewaySettingsContract, address usdcAddress) public {
        gatewaySettingsContract.setSupportedToken(usdcAddress, true);
    }
    ```

#### **PGateway (Core Payment Logic - via Proxy)**
This is the main contract for order creation, provider interaction, and settlement. All interactions should be with the deployed proxy address of `PGateway`.

*   **Registering Provider Intent:**
    A liquidity provider registers their capacity and terms.
    ```solidity
    // Example: A provider registers intent
    // Assuming 'gatewayProxyContract' is an instance of IPGateway
    function registerProviderIntent(
        IPGateway gatewayProxyContract,
        string calldata currency,
        uint256 availableAmount,
        uint64 minFeeBps,
        uint64 maxFeeBps,
        uint256 commitmentWindow
    ) public {
        gatewayProxyContract.registerIntent(currency, availableAmount, minFeeBps, maxFeeBps, commitmentWindow);
    }
    ```
*   **Creating an Order:**
    A user initiates a payment order.
    ```solidity
    // Example: A user creates an order for 100 USDC
    // Assuming 'gatewayProxyContract' is an instance of IPGateway
    function createUserOrder(
        IPGateway gatewayProxyContract,
        address usdcAddress, // ERC20 token address
        uint256 amount,
        address refundAddress,
        string calldata messageHash // A hash of an off-chain message/payload
    ) public returns (bytes32 orderId) {
        // IMPORTANT: User must first approve the gatewayProxyContract to spend `amount` of `usdcAddress` tokens
        // IERC20(usdcAddress).approve(address(gatewayProxyContract), amount);
        orderId = gatewayProxyContract.createOrder(usdcAddress, amount, refundAddress, messageHash);
    }
    ```
*   **Creating a Settlement Proposal (by Aggregator):**
    The off-chain aggregator identifies a provider and creates a proposal.
    ```solidity
    // Example: Aggregator proposes settlement
    // Assuming 'gatewayProxyContract' is an instance of IPGateway
    function createSettlementProposal(
        IPGateway gatewayProxyContract,
        bytes32 orderId,
        address providerAddress,
        uint64 proposedFeeBps
    ) public returns (bytes32 proposalId) {
        // This call must come from the designated aggregator address
        proposalId = gatewayProxyContract.createProposal(orderId, providerAddress, proposedFeeBps);
    }
    ```
*   **Accepting a Proposal (by Provider):**
    A provider accepts a proposal to fulfill an order.
    ```solidity
    // Example: A provider accepts a proposal
    // Assuming 'gatewayProxyContract' is an instance of IPGateway
    function providerAcceptsProposal(IPGateway gatewayProxyContract, bytes32 proposalId) public {
        // This call must come from the designated provider address
        gatewayProxyContract.acceptProposal(proposalId);
    }
    ```
*   **Executing Settlement (by Aggregator):**
    After acceptance, the aggregator triggers the final fund transfer.
    ```solidity
    // Example: Aggregator executes settlement
    // Assuming 'gatewayProxyContract' is an instance of IPGateway
    function executeOrderSettlement(IPGateway gatewayProxyContract, bytes32 proposalId) public {
        // This call must come from the designated aggregator address
        gatewayProxyContract.executeSettlement(proposalId);
    }
    ```

## Technologies Used
The PayNode Protocol is built upon a robust stack of leading Web3 development tools and libraries.

| Technology                   | Description                                                                     | Link                                                                |
| :--------------------------- | :------------------------------------------------------------------------------ | :------------------------------------------------------------------ |
| **Solidity**                 | Object-oriented, high-level language for implementing smart contracts.          | [Solidity Lang](https://soliditylang.org/)                          |
| **Foundry**                  | Fast, portable, and modular toolkit for Ethereum application development.       | [Foundry Book](https://book.getfoundry.sh/)                         |
| **OpenZeppelin Contracts**   | Secure, community-vetted smart contract building blocks for Ethereum.           | [OpenZeppelin Docs](https://docs.openzeppelin.com/contracts/4.x/) |
| **Chainlink Automation**     | Decentralized services to automate smart contract functions on pre-set conditions. | [Chainlink Automation](https://docs.chain.link/chainlink-automation/) |

## Contributing
We welcome contributions to the PayNode Protocol! If you're interested in improving the system, please follow these guidelines:

*   💡 **Suggest Features:** Open an issue to propose new features or improvements.
*   🐞 **Report Bugs:** If you find a bug, please open an issue with a detailed description and steps to reproduce.
*   🛠️ **Submit Pull Requests:**
    *   Fork the repository.
    *   Create a new branch for your feature or bug fix.
    *   Write clean, well-commented code.
    *   Ensure your code passes all tests (`forge test`).
    *   Submit a pull request with a clear description of your changes.

## License
This project's smart contracts are released under the MIT License, as specified by their `SPDX-License-Identifier` headers.

## Author
**Olujimi**
*   LinkedIn: [Your LinkedIn Profile](https://linkedin.com/in/YOUR_LINKEDIN_USERNAME)
*   Twitter: [Your Twitter Handle](https://twitter.com/YOUR_TWITTER_HANDLE)

## Badges
[![Solidity v0.8.24](https://img.shields.io/badge/Solidity-v0.8.24-lightgray)](https://soliditylang.org/)
[![Built with Foundry](https://img.shields.io/badge/Built%20with-Foundry-red)](https://getfoundry.sh/)
[![Uses OpenZeppelin](https://img.shields.io/badge/Uses-OpenZeppelin%20Contracts-blue)](https://docs.openzeppelin.com/contracts/4.x/)
[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
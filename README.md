# PayNode Protocol: Decentralized Payment Gateway Contracts

## Overview
This project comprises the core smart contracts for the PayNode Protocol, a non-custodial payment aggregation system built on Solidity and utilizing the Foundry development framework. It facilitates parallel settlement and includes a provider intent registry, aiming to streamline decentralized payment processes.

## Features
- **Non-Custodial Payments**: Users retain control of funds until settlement, enhancing security and trust.
- **Provider Intent Registry**: Allows payment providers to register their available capacity, currencies, and fee structures.
- **Order Management**: Supports creation, tracking, and tiering of payment orders based on amount.
- **Settlement Proposals**: Aggregators can propose settlements to providers, who can then accept or reject.
- **Reputation System**: Tracks provider performance, including successful orders, failures, and no-shows.
- **Access Control**: Role-based access for `Owner`, `Aggregator`, and `Provider` roles.
- **Pausable Operations**: Core contract operations can be paused by the owner for emergency situations.
- **Reentrancy Protection**: Guards against reentrancy attacks on critical functions.
- **ERC-20 Integration**: Handles transfers of supported ERC-20 tokens for orders and settlements.
- **Upgradeability**: Built with OpenZeppelin's upgradeable patterns, allowing for future contract enhancements.

## Getting Started

To get a local copy of the project up and running, follow these steps.

### Installation
This project uses [Foundry](https://getfoundry.sh/) for its development environment.

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/your-username/paynode-contract.git
    cd paynode-contract
    ```

2.  **Install Foundry**:
    If you don't have Foundry installed, you can install it using `foundryup`:
    ```bash
    curl -L https://foundry.sh | bash
    foundryup
    ```

3.  **Install Dependencies**:
    The project relies on OpenZeppelin contracts and `forge-std`. These are managed as Git submodules and Foundry dependencies.
    ```bash
    git submodule update --init --recursive
    forge install
    ```

4.  **Build Contracts**:
    Compile the smart contracts:
    ```bash
    forge build
    ```

5.  **Run Tests (Optional)**:
    Execute the test suite to ensure everything is functioning correctly:
    ```bash
    forge test
    ```

### Environment Variables
This project primarily uses Foundry's configuration. For deployment or specific network interactions, the following environment variables are typically required:

-   `RPC_URL`: The URL of the Ethereum-compatible blockchain node you wish to interact with (e.g., `https://mainnet.infura.io/v3/YOUR_PROJECT_ID`).
    *Example*: `RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY`
-   `PRIVATE_KEY`: The private key of the account used for deploying or sending transactions. **Handle with extreme care.**
    *Example*: `PRIVATE_KEY=0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890`
-   `ETHERSCAN_API_KEY`: API key for block explorers like Etherscan for contract verification.
    *Example*: `ETHERSCAN_API_KEY=YOUR_ETHERSCAN_API_KEY`

These variables are usually set in a `.env` file (which should be in `.gitignore`) and loaded into your shell session.

## API Documentation

The PayNode Protocol is implemented as a set of Solidity smart contracts, primarily the `PayNode` contract (located in `src/PGateway.sol`). Interaction occurs directly on-chain through transaction calls and event emissions, rather than traditional HTTP requests. The functions below represent the public interface for interacting with the protocol.

### Base Contract
The main contract providing the core payment gateway logic is `PayNode`.
Contract Address: `[DeployedContractAddress]` (placeholder for a deployed instance)

### Functions (API)

#### `initialize(address _treasuryAddress, address _aggregatorAddress)`
**Description**:
Initializes the `PayNode` contract upon deployment (specifically for upgradeable proxy setups). Sets the initial treasury and aggregator addresses. Can only be called once.

**Parameters**:
-   `_treasuryAddress (address)`: The address designated to receive protocol fees.
-   `_aggregatorAddress (address)`: The address of the aggregator responsible for matching orders with providers and initiating proposals.

**Request**:
```json
{
  "_treasuryAddress": "0xABCDEF1234567890ABCDEF1234567890ABCDEF12",
  "_aggregatorAddress": "0x0987654321FEDCBA0987654321FEDCBA098765"
}
```

**Response**:
`{ "status": "Initialized" }` (Indicates successful initialization)

**Errors**:
-   `InvalidTreasuryAddress`: Provided treasury address is zero.
-   `InvalidAggregatorAddress`: Provided aggregator address is zero.
-   `Initializable: contract is already initialized`: Attempted to call `initialize` more than once.

#### `pause()`
**Description**:
Pauses all contract operations. Only callable by the contract owner. Prevents execution of `whenNotPaused` functions.

**Parameters**:
None

**Request**:
`{}`

**Response**:
`{ "status": "Contract Paused" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `Pausable: paused`: Contract is already paused.

#### `unpause()`
**Description**:
Unpauses the contract, allowing operations to resume. Only callable by the contract owner.

**Parameters**:
None

**Request**:
`{}`

**Response**:
`{ "status": "Contract Unpaused" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `Pausable: not paused`: Contract is not currently paused.

#### `setSupportedToken(address _token, bool _supported)`
**Description**:
Adds or removes an ERC-20 token from the list of supported tokens for orders. Only callable by the contract owner.

**Parameters**:
-   `_token (address)`: The address of the ERC-20 token.
-   `_supported (bool)`: `true` to add support, `false` to remove.

**Request**:
```json
{
  "_token": "0x1234567890abcdef1234567890abcdef12345678",
  "_supported": true
}
```

**Response**:
`{ "status": "Token Support Updated" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `InvalidToken`: Provided token address is zero.

#### `setTreasuryAddress(address _newTreasury)`
**Description**:
Updates the address designated to receive protocol fees. Only callable by the contract owner.

**Parameters**:
-   `_newTreasury (address)`: The new treasury address.

**Request**:
```json
{
  "_newTreasury": "0xABCDEF1234567890ABCDEF1234567890ABCDEF12"
}
```

**Response**:
`{ "status": "Treasury Address Updated" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `InvalidAddress`: Provided address is zero.

#### `setAggregatorAddress(address _newAggregator)`
**Description**:
Updates the address of the aggregator. Only callable by the contract owner.

**Parameters**:
-   `_newAggregator (address)`: The new aggregator address.

**Request**:
```json
{
  "_newAggregator": "0x0987654321FEDCBA0987654321FEDCBA098765"
}
```

**Response**:
`{ "status": "Aggregator Address Updated" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `InvalidAddress`: Provided address is zero.

#### `setProtocolFee(uint64 _newFee)`
**Description**:
Sets the protocol fee percentage in basis points (BPS). Only callable by the contract owner. Max 5000 BPS (5%).

**Parameters**:
-   `_newFee (uint64)`: The new protocol fee in basis points (e.g., `500` for 0.5%).

**Request**:
```json
{
  "_newFee": 500
}
```

**Response**:
`{ "status": "Protocol Fee Updated" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `FeeTooHigh`: Provided fee exceeds the maximum allowed (5000 BPS).

#### `setTierLimits(uint256 _smallLimit, uint256 _mediumLimit)`
**Description**:
Configures the upper limits for `SMALL` and `MEDIUM` order tiers. Only callable by the contract owner.

**Parameters**:
-   `_smallLimit (uint256)`: Maximum amount for `SMALL` tier orders (in token smallest units).
-   `_mediumLimit (uint256)`: Maximum amount for `MEDIUM` tier orders (in token smallest units).

**Request**:
```json
{
  "_smallLimit": "5000000000000000000000", // 5000 units
  "_mediumLimit": "20000000000000000000000" // 20000 units
}
```

**Response**:
`{ "status": "Tier Limits Updated" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `InvalidLimits`: Limits are not positive or `_mediumLimit` is not greater than `_smallLimit`.

#### `setOrderExpiryWindow(uint256 _newWindow)`
**Description**:
Sets the duration after which an order expires if not fulfilled. Only callable by the contract owner.

**Parameters**:
-   `_newWindow (uint256)`: The new expiry window in seconds.

**Request**:
```json
{
  "_newWindow": 3600 // 1 hour
}
```

**Response**:
`{ "status": "Order Expiry Window Updated" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `InvalidWindow`: Provided window is zero.

#### `setProposalTimeout(uint256 _newTimeout)`
**Description**:
Sets the duration within which a provider must accept a settlement proposal. Only callable by the contract owner.

**Parameters**:
-   `_newTimeout (uint256)`: The new proposal timeout in seconds.

**Request**:
```json
{
  "_newTimeout": 30 // 30 seconds
}
```

**Response**:
`{ "status": "Proposal Timeout Updated" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `InvalidTimeout`: Provided timeout is zero.

#### `registerIntent(string calldata _currency, uint256 _availableAmount, uint64 _minFeeBps, uint64 _maxFeeBps, uint256 _commitmentWindow)`
**Description**:
Allows a provider to register their intent to fulfill payments, specifying their available capacity, accepted currency, fee range, and commitment window.

**Parameters**:
-   `_currency (string)`: The currency code the provider accepts (e.g., "NGN", "USD").
-   `_availableAmount (uint256)`: The total amount (in native token units) the provider is willing to process.
-   `_minFeeBps (uint64)`: Minimum fee the provider charges, in basis points (e.g., `50` for 0.05%).
-   `_maxFeeBps (uint64)`: Maximum fee the provider charges, in basis points.
-   `_commitmentWindow (uint256)`: Time in seconds a provider has to accept a proposal.

**Request**:
```json
{
  "_currency": "USD",
  "_availableAmount": "10000000000000000000000", // 10000 USD equivalent
  "_minFeeBps": 100, // 0.1%
  "_maxFeeBps": 500, // 0.5%
  "_commitmentWindow": 600 // 10 minutes
}
```

**Response**:
`{ "status": "IntentRegisteredEventEmitted" }` (Indicates successful registration)

**Errors**:
-   `Pausable: paused`: Contract is paused.
-   `InvalidAmount`: Provided available amount is zero.
-   `InvalidFees`: Minimum fee is greater than maximum fee.
-   `FeesTooHigh`: Maximum fee exceeds 10000 BPS (10%).
-   `InvalidCommitmentWindow`: Provided commitment window is zero.
-   `ProviderBlacklisted`: The calling provider is blacklisted.

#### `updateIntent(string calldata _currency, uint256 _newAmount)`
**Description**:
Updates the available amount for an existing provider intent.

**Parameters**:
-   `_currency (string)`: The currency code of the intent to update.
-   `_newAmount (uint256)`: The new available amount for the provider (in native token units).

**Request**:
```json
{
  "_currency": "USD",
  "_newAmount": "15000000000000000000000" // 15000 USD equivalent
}
```

**Response**:
`{ "status": "IntentUpdatedEventEmitted" }`

**Errors**:
-   `NotRegisteredProvider`: Caller is not a registered provider.
-   `Pausable: paused`: Contract is paused.
-   `NoActiveIntent`: The provider does not have an active intent.
-   `InvalidAmount`: Provided new amount is zero.

#### `expireIntent(address _provider)`
**Description**:
Marks a provider's intent as expired if the expiry time has passed. Only callable by the aggregator.

**Parameters**:
-   `_provider (address)`: The address of the provider whose intent is to be expired.

**Request**:
```json
{
  "_provider": "0x0987654321FEDCBA0987654321FEDCBA098765"
}
```

**Response**:
`{ "status": "IntentExpiredEventEmitted" }`

**Errors**:
-   `OnlyAggregator`: Caller is not the aggregator address.
-   `IntentNotActive`: The provider's intent is not active.
-   `IntentNotExpired`: The intent's expiry time has not yet passed.

#### `reserveIntent(address _provider, uint256 _amount)`
**Description**:
Reserves a specified amount from a provider's available capacity when a proposal is sent to them. Only callable by the aggregator.

**Parameters**:
-   `_provider (address)`: The address of the provider.
-   `_amount (uint256)`: The amount to reserve (in native token units).

**Request**:
```json
{
  "_provider": "0x0987654321FEDCBA0987654321FEDCBA098765",
  "_amount": "500000000000000000000" // 500 units
}
```

**Response**:
`{ "status": "Capacity Reserved" }`

**Errors**:
-   `OnlyAggregator`: Caller is not the aggregator address.
-   `IntentNotActive`: The provider's intent is not active.
-   `InsufficientCapacity`: Provider does not have enough available amount to reserve.

#### `releaseIntent(address _provider, uint256 _amount, string calldata _reason)`
**Description**:
Releases a specified amount back to a provider's available capacity, typically when a proposal is rejected or times out. Only callable by the aggregator.

**Parameters**:
-   `_provider (address)`: The address of the provider.
-   `_amount (uint256)`: The amount to release (in native token units).
-   `_reason (string)`: A brief reason for the release (e.g., "Proposal Rejected").

**Request**:
```json
{
  "_provider": "0x0987654321FEDCBA0987654321FEDCBA098765",
  "_amount": "500000000000000000000", // 500 units
  "_reason": "Proposal Rejected"
}
```

**Response**:
`{ "status": "IntentReleasedEventEmitted" }`

**Errors**:
-   `OnlyAggregator`: Caller is not the aggregator address.

#### `getProviderIntent(address _provider)`
**Description**:
Retrieves the current intent details for a given provider.

**Parameters**:
-   `_provider (address)`: The address of the provider.

**Return Value**:
`(ProviderIntent memory)`: A struct containing:
-   `provider (address)`: The provider's address.
-   `currency (string)`: The currency code.
-   `availableAmount (uint256)`: Current available capacity.
-   `minFeeBps (uint64)`: Minimum fee in BPS.
-   `maxFeeBps (uint64)`: Maximum fee in BPS.
-   `registeredAt (uint256)`: Timestamp of registration.
-   `expiresAt (uint256)`: Timestamp of expiration.
-   `commitmentWindow (uint256)`: Provider's commitment window.
-   `isActive (bool)`: Whether the intent is active.

**Request**:
```json
{
  "_provider": "0x0987654321FEDCBA0987654321FEDCBA098765"
}
```

**Response**:
```json
{
  "provider": "0x0987654321FEDCBA0987654321FEDCBA098765",
  "currency": "USD",
  "availableAmount": "10000000000000000000000",
  "minFeeBps": 100,
  "maxFeeBps": 500,
  "registeredAt": 1678886400,
  "expiresAt": 1678886700,
  "commitmentWindow": 600,
  "isActive": true
}
```

**Errors**:
-   None (returns default struct if provider not found)

#### `createOrder(address _token, uint256 _amount, address _refundAddress)`
**Description**:
Initiates a new payment order. The user's tokens are transferred to the contract. A unique order ID is generated and returned.

**Parameters**:
-   `_token (address)`: The ERC-20 token address for the payment.
-   `_amount (uint256)`: The amount of tokens for the order (in token smallest units).
-   `_refundAddress (address)`: The address to which funds will be refunded if the order fails or is cancelled.

**Return Value**:
`(bytes32)`: The unique `orderId` generated for the new order.

**Request**:
```json
{
  "_token": "0x1234567890abcdef1234567890abcdef12345678",
  "_amount": "1000000000000000000", // 1 token unit
  "_refundAddress": "0xABCDEF1234567890ABCDEF1234567890ABCDEF12"
}
```

**Response**:
```json
{
  "orderId": "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b"
}
```

**Errors**:
-   `Pausable: paused`: Contract is paused.
-   `TokenNotSupported`: The specified token is not supported by the contract.
-   `InvalidAmount`: Provided amount is zero.
-   `InvalidRefundAddress`: Provided refund address is zero.
-   `ERC20: transfer amount exceeds balance` or `ERC20: transfer from failed`: User does not have sufficient tokens or allowance.

#### `getOrder(bytes32 _orderId)`
**Description**:
Retrieves the details of a specific payment order.

**Parameters**:
-   `_orderId (bytes32)`: The unique identifier of the order.

**Return Value**:
`(Order memory)`: A struct containing:
-   `orderId (bytes32)`: The unique identifier of the order.
-   `user (address)`: The address of the user who created the order.
-   `token (address)`: The ERC-20 token address.
-   `amount (uint256)`: The order amount.
-   `tier (OrderTier)`: The order's tier (SMALL, MEDIUM, LARGE).
-   `status (OrderStatus)`: The current status of the order.
-   `refundAddress (address)`: The designated refund address.
-   `createdAt (uint256)`: Timestamp of creation.
-   `expiresAt (uint256)`: Timestamp of expiration.
-   `acceptedProposalId (bytes32)`: ID of the accepted proposal (if any).
-   `fulfilledByProvider (address)`: Address of the provider who fulfilled the order (if any).

**Request**:
```json
{
  "_orderId": "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b"
}
```

**Response**:
```json
{
  "orderId": "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b",
  "user": "0xABCDEF1234567890ABCDEF1234567890ABCDEF12",
  "token": "0x1234567890abcdef1234567890abcdef12345678",
  "amount": "1000000000000000000",
  "tier": 0, // SMALL
  "status": 0, // PENDING
  "refundAddress": "0xABCDEF1234567890ABCDEF1234567890ABCDEF12",
  "createdAt": 1678886400,
  "expiresAt": 1678890000,
  "acceptedProposalId": "0x0000000000000000000000000000000000000000000000000000000000000000",
  "fulfilledByProvider": "0x0000000000000000000000000000000000000000"
}
```

**Errors**:
-   `OrderNotFound`: The provided `_orderId` does not correspond to an existing order.

#### `createProposal(bytes32 _orderId, address _provider, uint64 _proposedFeeBps)`
**Description**:
Creates a settlement proposal for a given order to a specific provider. Only callable by the aggregator.

**Parameters**:
-   `_orderId (bytes32)`: The ID of the order to settle.
-   `_provider (address)`: The address of the provider who will fulfill the order.
-   `_proposedFeeBps (uint64)`: The fee (in basis points) proposed to be paid to the provider.

**Return Value**:
`(bytes32)`: The unique `proposalId` generated for the new proposal.

**Request**:
```json
{
  "_orderId": "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b",
  "_provider": "0x0987654321FEDCBA0987654321FEDCBA098765",
  "_proposedFeeBps": 200 // 0.2%
}
```

**Response**:
```json
{
  "proposalId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
}
```

**Errors**:
-   `OnlyAggregator`: Caller is not the aggregator address.
-   `OrderNotFound`: The provided `_orderId` does not correspond to an existing order.
-   `OrderNotPending`: The order is not in `PENDING` status.
-   `OrderExpired`: The order has already expired.
-   `ProviderIntentNotActive`: The chosen provider does not have an active intent.
-   `InsufficientCapacity`: The chosen provider does not have enough available capacity for the order amount.
-   `InvalidFee`: The proposed fee is outside the provider's registered `minFeeBps` and `maxFeeBps` range.

#### `acceptProposal(bytes32 _proposalId)`
**Description**:
Allows a provider to accept a settlement proposal addressed to them. This changes the status of both the proposal and the associated order to `ACCEPTED`.

**Parameters**:
-   `_proposalId (bytes32)`: The ID of the proposal to accept.

**Request**:
```json
{
  "_proposalId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
}
```

**Response**:
`{ "status": "SettlementProposalAcceptedEventEmitted" }`

**Errors**:
-   `NotRegisteredProvider`: Caller is not a registered provider.
-   `Pausable: paused`: Contract is paused.
-   `NotProposalProvider`: Caller is not the provider associated with the proposal.
-   `ProposalNotPending`: The proposal is not in `PENDING` status.
-   `ProposalExpired`: The proposal's deadline has passed.

#### `rejectProposal(bytes32 _proposalId, string calldata _reason)`
**Description**:
Allows a provider to reject a settlement proposal addressed to them. This changes the status of the proposal to `REJECTED` and updates the provider's reputation.

**Parameters**:
-   `_proposalId (bytes32)`: The ID of the proposal to reject.
-   `_reason (string)`: A brief reason for rejecting the proposal.

**Request**:
```json
{
  "_proposalId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
  "_reason": "Capacity unavailable"
}
```

**Response**:
`{ "status": "SettlementProposalRejectedEventEmitted" }`

**Errors**:
-   `NotRegisteredProvider`: Caller is not a registered provider.
-   `NotProposalProvider`: Caller is not the provider associated with the proposal.
-   `ProposalNotPending`: The proposal is not in `PENDING` status.

#### `timeoutProposal(bytes32 _proposalId)`
**Description**:
Marks a pending proposal as `TIMEOUT` if its deadline has passed. Only callable by the aggregator.

**Parameters**:
-   `_proposalId (bytes32)`: The ID of the proposal to timeout.

**Request**:
```json
{
  "_proposalId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
}
```

**Response**:
`{ "status": "SettlementProposalTimeoutEventEmitted" }`

**Errors**:
-   `OnlyAggregator`: Caller is not the aggregator address.
-   `ProposalNotPending`: The proposal is not in `PENDING` status.
-   `ProposalNotExpired`: The proposal's deadline has not yet passed.

#### `getProposal(bytes32 _proposalId)`
**Description**:
Retrieves the details of a specific settlement proposal.

**Parameters**:
-   `_proposalId (bytes32)`: The unique identifier of the proposal.

**Return Value**:
`(SettlementProposal memory)`: A struct containing:
-   `proposalId (bytes32)`: The unique identifier of the proposal.
-   `orderId (bytes32)`: The ID of the associated order.
-   `provider (address)`: The provider's address.
-   `proposedAmount (uint256)`: The amount proposed for settlement.
-   `proposedFeeBps (uint64)`: The proposed fee in BPS.
-   `proposedAt (uint256)`: Timestamp of proposal creation.
-   `proposalDeadline (uint256)`: Deadline for provider acceptance.
-   `status (ProposalStatus)`: The current status of the proposal.

**Request**:
```json
{
  "_proposalId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
}
```

**Response**:
```json
{
  "proposalId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
  "orderId": "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b",
  "provider": "0x0987654321FEDCBA0987654321FEDCBA098765",
  "proposedAmount": "1000000000000000000",
  "proposedFeeBps": 200,
  "proposedAt": 1678890000,
  "proposalDeadline": 1678890030,
  "status": 1 // ACCEPTED
}
```

**Errors**:
-   None (returns default struct if proposal not found)

#### `executeSettlement(bytes32 _proposalId)`
**Description**:
Executes the settlement of an order based on an accepted proposal. Transfers protocol fees to the treasury and the remaining amount to the provider. Updates order status and provider reputation. Only callable by the aggregator.

**Parameters**:
-   `_proposalId (bytes32)`: The ID of the accepted proposal to execute.

**Request**:
```json
{
  "_proposalId": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
}
```

**Response**:
`{ "status": "SettlementExecutedEventEmitted" }`

**Errors**:
-   `OnlyAggregator`: Caller is not the aggregator address.
-   `ProposalNotAccepted`: The proposal is not in `ACCEPTED` status.
-   `AlreadyExecuted`: The proposal has already been executed.
-   `OrderNotAccepted`: The associated order is not in `ACCEPTED` status.
-   `ERC20: transfer amount exceeds balance` or `ERC20: transfer failed`: Insufficient balance in the contract for fees or provider payment.

#### `refundOrder(bytes32 _orderId)`
**Description**:
Refunds an order if it has not been fulfilled and has expired. Transfers the full order amount back to the `refundAddress`. Only callable by the aggregator.

**Parameters**:
-   `_orderId (bytes32)`: The ID of the order to refund.

**Request**:
```json
{
  "_orderId": "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b"
}
```

**Response**:
`{ "status": "OrderRefundedEventEmitted" }`

**Errors**:
-   `OnlyAggregator`: Caller is not the aggregator address.
-   `OrderNotFound`: The provided `_orderId` does not correspond to an existing order.
-   `OrderFulfilled`: The order has already been fulfilled.
-   `AlreadyRefunded`: The order has already been refunded.
-   `OrderNotExpired`: The order's expiry time has not yet passed.
-   `ERC20: transfer failed`: Failed to transfer tokens to the refund address.

#### `requestRefund(bytes32 _orderId)`
**Description**:
Allows the order creator to request a refund for an unfulfilled and expired order. Marks the order as `CANCELLED` and transfers funds to the `refundAddress`.

**Parameters**:
-   `_orderId (bytes32)`: The ID of the order to refund.

**Request**:
```json
{
  "_orderId": "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b"
}
```

**Response**:
`{ "status": "OrderRefundedEventEmitted" }`

**Errors**:
-   `OrderNotFound`: The provided `_orderId` does not correspond to an existing order.
-   `NotOrderCreator`: Caller is not the creator of the order.
-   `CannotRefund`: The order's status is `FULFILLED` or `REFUNDED`, or has an accepted proposal.
-   `OrderNotExpired`: The order's expiry time has not yet passed.
-   `ERC20: transfer failed`: Failed to transfer tokens to the refund address.

#### `flagFraudulent(address _provider)`
**Description**:
Flags a provider as fraudulent, deactivating their intent. Only callable by the aggregator.

**Parameters**:
-   `_provider (address)`: The address of the provider to flag.

**Request**:
```json
{
  "_provider": "0x0987654321FEDCBA0987654321FEDCBA098765"
}
```

**Response**:
`{ "status": "ProviderFraudFlaggedEventEmitted" }`

**Errors**:
-   `OnlyAggregator`: Caller is not the aggregator address.
-   `ProviderNotFound`: The provided provider address is not registered.

#### `blacklistProvider(address _provider, string calldata _reason)`
**Description**:
Blacklists a provider, deactivating their intent and preventing them from registering new intents. Only callable by the contract owner.

**Parameters**:
-   `_provider (address)`: The address of the provider to blacklist.
-   `_reason (string)`: A brief reason for blacklisting.

**Request**:
```json
{
  "_provider": "0x0987654321FEDCBA0987654321FEDCBA098765",
  "_reason": "Repeated failed settlements"
}
```

**Response**:
`{ "status": "ProviderBlacklistedEventEmitted" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.

#### `getProviderReputation(address _provider)`
**Description**:
Retrieves the reputation metrics for a specific provider.

**Parameters**:
-   `_provider (address)`: The address of the provider.

**Return Value**:
`(ProviderReputation memory)`: A struct containing:
-   `provider (address)`: The provider's address.
-   `totalOrders (uint256)`: Total orders processed.
-   `successfulOrders (uint256)`: Count of successfully fulfilled orders.
-   `failedOrders (uint256)`: Count of failed orders.
-   `noShowCount (uint256)`: Count of proposals rejected or timed out by the provider.
-   `totalSettlementTime (uint256)`: Total time taken for successful settlements.
-   `lastUpdated (uint256)`: Timestamp of last reputation update.
-   `isFraudulent (bool)`: Whether the provider is flagged as fraudulent.
-   `isBlacklisted (bool)`: Whether the provider is blacklisted.

**Request**:
```json
{
  "_provider": "0x0987654321FEDCBA0987654321FEDCBA098765"
}
```

**Response**:
```json
{
  "provider": "0x0987654321FEDCBA0987654321FEDCBA098765",
  "totalOrders": 10,
  "successfulOrders": 8,
  "failedOrders": 1,
  "noShowCount": 1,
  "totalSettlementTime": 1200,
  "lastUpdated": 1678890100,
  "isFraudulent": false,
  "isBlacklisted": false
}
```

**Errors**:
-   None (returns default struct if provider not found)

#### `getRegisteredProviders()`
**Description**:
Returns an array of all currently registered provider addresses.

**Parameters**:
None

**Return Value**:
`(address[] memory)`: An array of provider addresses.

**Request**:
`{}`

**Response**:
```json
{
  "providers": [
    "0x0987654321FEDCBA0987654321FEDCBA098765",
    "0x112233445566778899AABBCCDDEEFF0011223344"
  ]
}
```

**Errors**:
-   None

#### `getActiveOrders()`
**Description**:
Returns an array of `orderId` for all currently active (pending, proposed, accepted) orders.

**Parameters**:
None

**Return Value**:
`(bytes32[] memory)`: An array of active order IDs.

**Request**:
`{}`

**Response**:
```json
{
  "orderIds": [
    "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b",
    "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
  ]
}
```

**Errors**:
-   None

#### `getUserNonce(address _user)`
**Description**:
Retrieves the nonce for a specific user, used internally for generating unique `orderId`s and preventing replay attacks.

**Parameters**:
-   `_user (address)`: The address of the user.

**Return Value**:
`(uint256)`: The current nonce for the user.

**Request**:
```json
{
  "_user": "0xABCDEF1234567890ABCDEF1234567890ABCDEF12"
}
```

**Response**:
```json
{
  "nonce": 5
}
```

**Errors**:
-   None

#### `emergencyWithdraw(address _token)`
**Description**:
Allows the contract owner to withdraw any accidentally sent or stuck ERC-20 tokens from the contract to the treasury address.

**Parameters**:
-   `_token (address)`: The address of the ERC-20 token to withdraw.

**Request**:
```json
{
  "_token": "0x1234567890abcdef1234567890abcdef12345678"
}
```

**Response**:
`{ "status": "Emergency Withdrawal Successful" }`

**Errors**:
-   `Ownable: caller is not the owner`: Caller is not the contract owner.
-   `NoBalance`: There is no balance of the specified token in the contract.
-   `ERC20: transfer failed`: Failed to transfer tokens to the treasury.

## Technologies Used
| Technology          | Description                                         |
| :------------------ | :-------------------------------------------------- |
| Solidity            | Smart contract programming language                 |
| Foundry             | Fast, portable and modular toolkit for Ethereum application development |
| OpenZeppelin Contracts | Standard, tested, and audited smart contract libraries |
| ERC-20              | Standard for fungible tokens on Ethereum            |

## Contributing
We welcome contributions to the PayNode Protocol! If you're interested in improving the project, please follow these guidelines:

*   **Fork the repository:** Start by forking the official repository to your GitHub account.
*   **Create a new branch:** For each feature or bug fix, create a new branch from `main` with a descriptive name (e.g., `feature/add-reputation-logic`, `bugfix/fix-overflow-error`).
*   **Write clean code:** Adhere to Solidity best practices and maintain consistent coding style.
*   **Add tests:** Ensure your changes are thoroughly tested using Foundry's testing framework.
*   **Document your work:** Update relevant comments and documentation for new functions or significant changes.
*   **Open a Pull Request:** Submit your changes via a pull request to the `main` branch, explaining your changes and their purpose.

## License
This project is licensed under the MIT License.

## Author
*   **Your Name/Alias**
    *   LinkedIn: [YourLinkedIn](https://linkedin.com/in/yourprofile)
    *   Twitter: [@YourTwitter](https://twitter.com/yourprofile)

---

[![Solidity](https://img.shields.io/badge/Solidity-^0.8.18-363636?logo=solidity)](https://soliditylang.org/)
[![Foundry](https://img.shields.io/badge/Foundry-darkgray?logo=foundry&logoColor=white)](https://getfoundry.sh/)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-Contracts-593E70?logo=openzeppelin)](https://openzeppelin.com/contracts/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Readme was generated by Dokugen](https://img.shields.io/badge/Readme%20was%20generated%20by-Dokugen-brightgreen)](https://www.npmjs.com/package/dokugen)
# PayNode Smart Contract Architecture

## Overview

PayNode is a **non-custodial payment aggregation protocol** that connects users with multiple liquidity providers for fast, efficient settlements. Instead of routing orders to a single provider (bottleneck), PayNode **sends simultaneous settlement proposals to multiple providers in parallel**—the first to accept executes the order.

**Core Innovation**: Providers pre-register their available capacity (intent), eliminating stale pricing and enabling intelligent provider selection. The system automatically ranks providers by success rate, speed, uptime, and fees, then races them for each order.

**Architecture**:

- **AccessManager** enforces role-based permissions across all contracts
- **TimelockAdmin** ensures secure upgrades with 48-hour delays
- **GatewaySettings** centralizes protocol configuration
- **Gateway** handles order lifecycle, provider intents, parallel proposals, and settlement

**Non-Custodial**: User funds stay locked in the contract until a provider accepts and confirms execution. No intermediary ever holds the money.

---

## System Architecture

```ansi
[34m┌─────────────────────────────────────────────────────────┐[0m
[34m│[0m                    [1;37mAccessManager[0m                         [34m│[0m
[34m│[0m  [33m• Admin role control[0m                                    [34m│[0m
[34m│[0m  [33m• Pause/Unpause permissions[0m                            [34m│[0m
[34m│[0m  [33m• Blacklist management[0m                                 [34m│[0m
[34m│[0m  [33m• Role-based access control (RBAC)[0m                     [34m│[0m
[34m└─────────────────────────────────────────────────────────┘[0m
         [36m↓[0m
[32m┌─────────────────────────────────────────────────────────┐[0m
[32m│[0m                  [1;37mTimelockAdmin[0m                          [32m│[0m
[32m│[0m  [33m• Upgrade scheduling (48h delay)[0m                       [32m│[0m
[32m│[0m  [33m• Proposal queuing[0m                                     [32m│[0m
[32m│[0m  [33m• Execution after timelock[0m                            [32m│[0m
[32m│[0m  [33m• Cancel malicious upgrades[0m                           [32m│[0m
[32m└─────────────────────────────────────────────────────────┘[0m
         [36m↓[0m
[35m┌─────────────────────────────────────────────────────────┐[0m
[35m│[0m            [1;37mPayNodeGatewaySettings[0m                       [35m│[0m
[35m│[0m  [33m• Configuration parameters[0m                             [35m│[0m
[35m│[0m  [33m• Token whitelist[0m                                     [35m│[0m
[35m│[0m  [33m• Fee settings[0m                                        [35m│[0m
[35m│[0m  [33m• Tier limits (SMALL/MEDIUM/LARGE)[0m                    [35m│[0m
[35m└─────────────────────────────────────────────────────────┘[0m
         [36m↓[0m
[31m┌─────────────────────────────────────────────────────────┐[0m
[31m│[0m             [1;37mPayNodeGateway (Proxy)[0m                       [31m│[0m
[31m│[0m  [33m• Order creation & management[0m                          [31m│[0m
[31m│[0m  [33m• Provider intent registry[0m                             [31m│[0m
[31m│[0m  [33m• Settlement proposals (parallel)[0m                      [31m│[0m
[31m│[0m  [33m• Settlement execution[0m                                [31m│[0m
[31m│[0m  [33m• Refund handling[0m                                      [31m│[0m
[31m│[0m  [33m• Reputation tracking[0m                                 [31m│[0m
[31m└─────────────────────────────────────────────────────────┘[0m
```

---

## Contract Layers

### 1. AccessManager (RBAC)

**Purpose**: Centralized permission control

**Roles**:

- `ADMIN_ROLE` - Full system control
- `PAUSER_ROLE` - Can pause contracts
- `AGGREGATOR_ROLE` - Settlement operations
- `UPGRADER_ROLE` - Can queue upgrades

**Functions**:

```
- grantRole(role, account)
- revokeRole(role, account)
- hasRole(role, account)
- blacklistProvider(address)
- removeFromBlacklist(address)
- isBlacklisted(address)
- pause()
- unpause()
```

**Events**:

```
- RoleGranted(role, account)
- RoleRevoked(role, account)
- ProviderBlacklisted(provider)
- ProviderWhitelisted(provider)
- ContractPaused()
- ContractUnpaused()
```

---

### 2. TimelockAdmin (Upgrade Control)

**Purpose**: Secure contract upgrades with delay

**Parameters**:

- Minimum delay: 2 days
- Execution window: 7 days

**Functions**:

```
- scheduleUpgrade(implementation, data)
- executeUpgrade(proposalId)
- cancelUpgrade(proposalId)
- getUpgradeStatus(proposalId)
```

**States**:

- PENDING → READY → EXECUTED / CANCELLED

**Events**:

```
- UpgradeScheduled(proposalId, implementation, eta)
- UpgradeExecuted(proposalId, implementation)
- UpgradeCancelled(proposalId)
```

---

### 3. PayNodeGatewaySettings (Configuration)

**Purpose**: Centralized settings management (inherited by Gateway)

**Configuration Variables**:

```
- MAX_BPS = 100,000
- protocolFeePercent (0-5%)
- SMALL_TIER_LIMIT (< 5,000)
- MEDIUM_TIER_LIMIT (5,000 - 20,000)
- LARGE_TIER_LIMIT (> 20,000)
- orderExpiryWindow (default 1 hour)
- proposalTimeout (default 30 seconds)
- treasuryAddress
- aggregatorAddress
```

**Token Management**:

```
- supportedTokens mapping
- addSupportedToken(address)
- removeSupportedToken(address)
```

**Functions**:

```
- setProtocolFee(uint64)
- setTierLimits(small, medium)
- setOrderExpiryWindow(uint256)
- setProposalTimeout(uint256)
- setSupportedToken(address, bool)
```

**Events**:

```
- ProtocolFeeUpdated(newFee)
- TierLimitsUpdated(small, medium)
- SupportedTokenUpdated(token, supported)
```

---

### 4. PayNodeGateway (Main Contract)

**Purpose**: Core order and settlement execution

#### A. Data Structures

```solidity
enum OrderTier { SMALL, MEDIUM, LARGE }
enum OrderStatus { PENDING, PROPOSED, ACCEPTED, FULFILLED, REFUNDED, CANCELLED }
enum ProposalStatus { PENDING, ACCEPTED, REJECTED, TIMEOUT, CANCELLED }

struct Provider {
    address provider
    OrderTier tier            // Self-declared tier
    string currency
    uint256 maxCapacity       // Max capacity they can handle
    uint64 minFeeBps, maxFeeBps
    uint256 registeredAt
    bool isActive
}

struct Order {
    bytes32 orderId
    address user
    address token
    uint256 amount
    OrderTier tier
    OrderStatus status
    address refundAddress
    uint256 createdAt, expiresAt
    bytes32 acceptedProposalId
    address fulfilledByProvider
}

struct SettlementProposal {
    bytes32 proposalId, orderId
    address provider
    uint256 proposedAmount
    uint64 proposedFeeBps
    uint256 proposedAt, proposalDeadline
    ProposalStatus status
}

struct ProviderReputation {
    address provider
    uint256 totalOrders, successfulOrders, failedOrders
    uint256 totalSettlementTime
    bool isFraudulent, isBlacklisted
}

```

B. Provider Registration & Intent Flow

Provider Registration
├─ registerProvider(tier, currency, capacity, fees)
│ └─ Stored in providers mapping
│ └─ Added to registeredProviders array
│ └─ Emits ProviderRegistered
│
├─ updateProvider(tier, capacity, fees)
│ └─ Refresh tier & capacity
│ └─ Emits ProviderUpdated
│
├─ deactivateProvider(provider)
│ └─ Mark isActive = false
│ └─ Emits ProviderDeactivated

---

#### B. Provider Intent Flow

```
Provider Registration
├─ registerIntent(currency, amount, fees, window)
│  └─ Stored in providerIntents mapping
│  └─ Added to registeredProviders array
│  └─ Emits IntentRegistered
│
├─ updateIntent(currency, newAmount)
│  └─ Refresh capacity & expiry
│  └─ Emits IntentUpdated
│
├─ expireIntent(provider)
│  └─ Called by aggregator
│  └─ Sets isActive = false
│  └─ Emits IntentExpired
│
├─ reserveIntent(provider, amount)
│  └─ Lock capacity when proposal sent
│  └─ availableAmount -= amount
│
└─ releaseIntent(provider, amount, reason)
   └─ Unlock capacity if proposal rejected
   └─ availableAmount += amount
```

**Functions**:

```
- registerIntent(currency, amount, minFee, maxFee, window)
- updateIntent(currency, newAmount)
- expireIntent(provider)
- reserveIntent(provider, amount)
- releaseIntent(provider, amount, reason)
- getProviderIntent(provider)
```

---

#### C. Order Creation Flow

```
User Action
├─ createOrder(token, amount, refundAddress)
│  ├─ Validate: token supported, amount > 0
│  ├─ Determine tier (SMALL/MEDIUM/LARGE)
│  ├─ Transfer token from user to contract
│  ├─ Generate orderId (nonce-based)
│  ├─ Create Order struct
│  ├─ Store in orders mapping
│  ├─ Emit OrderCreated
│  └─ Return orderId
│
└─ Order Status: PENDING
```

**Functions**:

```
- createOrder(token, amount, refundAddress)
- getOrder(orderId)
- getUserNonce(user)
```

---

#### D. Settlement Proposal Flow (Parallel Execution)

```
Aggregator Action
├─ createProposal(orderId, provider, feeBps) × N providers
│  ├─ Validate: order pending, intent active
│  ├─ Check capacity >= order amount
│  ├─ Generate proposalId
│  ├─ Reserve capacity via reserveIntent()
│  ├─ Create SettlementProposal
│  ├─ Emit SettlementProposalCreated
│  └─ Order Status: PROPOSED
│
├─ Provider accepts (Race Condition)
│  ├─ acceptProposal(proposalId)
│  │  ├─ Validate: provider matches
│  │  ├─ Set ProposalStatus = ACCEPTED
│  │  ├─ Set Order.acceptedProposalId
│  │  ├─ Order Status: ACCEPTED
│  │  └─ Emit SettlementProposalAccepted
│  │
│  └─ Other proposals auto-rejected
│     ├─ rejectProposal(proposalId, reason)
│     ├─ releaseIntent() for all others
│     └─ Emit SettlementProposalRejected
│
├─ Proposal Timeout
│  ├─ timeoutProposal(proposalId)
│  ├─ block.timestamp > proposalDeadline
│  ├─ Set ProposalStatus = TIMEOUT
│  ├─ releaseIntent() for reserved capacity
│  └─ Emit SettlementProposalTimeout
│
└─ Result: First accepted proposal wins
```

**Functions**:

```
- createProposal(orderId, provider, feeBps)
- acceptProposal(proposalId)
- rejectProposal(proposalId, reason)
- timeoutProposal(proposalId)
- getProposal(proposalId)
```

---

#### E. Settlement Execution Flow

```
Aggregator Action
├─ executeSettlement(proposalId)
│  ├─ Validate: proposal accepted
│  ├─ Retrieve Order & Proposal
│  ├─ Calculate fees:
│  │  ├─ protocolFee = (amount × protocolFeePercent) / MAX_BPS
│  │  ├─ providerFee = (amount × proposedFeeBps) / MAX_BPS
│  │  └─ providerAmount = amount - protocolFee - providerFee
│  ├─ Transfer protocolFee → treasuryAddress
│  ├─ Transfer providerAmount → provider
│  ├─ Mark proposalExecuted[proposalId] = true
│  ├─ Order Status: FULFILLED
│  ├─ Update provider reputation (success)
│  └─ Emit SettlementExecuted
│
└─ Order Complete
```

**Functions**:

```
- executeSettlement(proposalId)
```

---

#### F. Refund Flow

```
Auto-Refund (Timeout)
├─ refundOrder(orderId) - called by aggregator
│  ├─ Validate: order not fulfilled, expired
│  ├─ Order Status: REFUNDED
│  ├─ Transfer full amount → refundAddress
│  └─ Emit OrderRefunded

Manual-Refund (User)
├─ requestRefund(orderId) - called by user
│  ├─ Validate: order creator, not fulfilled, expired
│  ├─ Order Status: CANCELLED
│  ├─ Transfer amount → refundAddress
│  └─ Emit OrderRefunded
```

**Functions**:

```
- refundOrder(orderId)
- requestRefund(orderId)
```

---

#### G. Reputation System

```
On Success
├─ _updateProviderSuccess(provider, settlementTime)
│  ├─ totalOrders++
│  ├─ successfulOrders++
│  ├─ totalSettlementTime += settlementTime
│  └─ Emit ProviderReputationUpdated

On Failure
├─ flagFraudulent(provider)
│  ├─ isFraudulent = true
│  ├─ isActive = false
│  └─ Emit ProviderFraudFlagged

Blacklist
├─ blacklistProvider(provider, reason)
│  ├─ isBlacklisted = true
│  ├─ Called via AccessManager
│  └─ Emit ProviderBlacklisted
```

**Functions**:

```
- getProviderReputation(provider)
- flagFraudulent(provider)
- (blacklistProvider in AccessManager)
```

---

## Complete Order Lifecycle

```
1. USER CREATES ORDER
   createOrder() → Order Status: PENDING

2. AGGREGATOR SENDS PROPOSALS
   createProposal() × 3 providers → Order Status: PROPOSED

3. PROVIDERS RACE (First wins)
   Provider A: acceptProposal() ✅ WINS
   Provider B: timeout / reject
   Provider C: timeout / reject

4. AGGREGATOR EXECUTES
   executeSettlement() → Order Status: FULFILLED

5. OUTCOME
   ✓ Provider gets funds
   ✓ Protocol gets fees
   ✓ User gets service
```

---

## Tier-Based Routing

```
SMALL (< 5,000)
├─ Send to all active providers
├─ First to accept wins
└─ Fast execution

MEDIUM (5,000 - 20,000)
├─ Filter providers (score > 80)
├─ Send to top 5 only
└─ Balanced execution

LARGE (> 20,000)
├─ Premium providers only
├─ Must have sufficient capacity
└─ Quality over speed
```

---

## Access Control Matrix

| Function          | Admin | Pauser | Aggregator | Provider | User |
| ----------------- | ----- | ------ | ---------- | -------- | ---- |
| createOrder       | ✓     | ✓      | ✓          | -        | ✓    |
| registerIntent    | ✓     | ✓      | ✓          | ✓        | -    |
| createProposal    | ✓     | ✓      | ✓          | -        | -    |
| acceptProposal    | ✓     | ✓      | -          | ✓        | -    |
| executeSettlement | ✓     | ✓      | ✓          | -        | -    |
| refundOrder       | ✓     | ✓      | ✓          | -        | -    |
| pause             | ✓     | ✓      | -          | -        | -    |
| blacklist         | ✓     | -      | -          | -        | -    |

---

## Key Features

✅ **Parallel Settlement** - Multiple providers compete
✅ **Time-Bound Proposals** - Commitment windows enforced
✅ **Tier-Based Routing** - Optimized for order size
✅ **Reputation Tracking** - Provider scoring
✅ **Non-Custodial** - Funds in escrow until settlement
✅ **Upgradeable** - Timelock + proxy pattern
✅ **Role-Based Access** - Fine-grained permissions
✅ **Pause Mechanism** - Emergency controls
✅ **Fraud Detection** - Blacklist malicious providers
✅ **Auto-Cleanup** - Expired intents & orders

---

## Events Summary

**Provider Intent**:

- IntentRegistered
- IntentUpdated
- IntentExpired
- IntentReleased

**Orders**:

- OrderCreated
- OrderQueued

**Proposals**:

- SettlementProposalCreated
- SettlementProposalAccepted
- SettlementProposalRejected
- SettlementProposalTimeout

**Settlement**:

- SettlementExecuted
- OrderRefunded

**Reputation**:

- ProviderReputationUpdated
- ProviderBlacklisted
- ProviderFraudFlagged

**Access Control**:

- RoleGranted
- RoleRevoked
- ContractPaused
- ContractUnpaused

---

## Deployment Order

```
1. Deploy AccessManager
2. Deploy TimelockAdmin (owner = AccessManager)
3. Deploy PayNodeGatewaySettings
4. Deploy PayNodeGateway (implementation)
5. Deploy ERC1967Proxy (points to PayNodeGateway)
6. Call initialize() on proxy
7. Transfer ownership to TimelockAdmin
```

---

## Security Considerations

- ✅ ReentrancyGuard on state-changing functions
- ✅ Pausable for emergency stops
- ✅ Role-based access control
- ✅ 48-hour upgrade timelock
- ✅ Provider blacklisting
- ✅ Capacity reservations prevent double-booking
- ✅ Time-bound proposals prevent hanging orders
- ✅ Event emissions for transparency

PayNode Smart Contract Architecture
Overview

PayNode is a non-custodial payment aggregation protocol connecting users to multiple off-chain liquidity providers for intelligent, parallel settlement routing.

Instead of sending a transaction to a single provider (bottleneck), PayNode broadcasts settlement proposals to eligible providers simultaneously — the first to accept executes the order.

Core Innovation:
Providers pre-register their capacity and tier (intent) off-chain. The aggregator routes orders based on provider tier, capacity, and performance scores.

Key Principles:

⚙️ Modular contract design (Settings, Access, Gateway)

🔐 Non-custodial escrow

🧠 Tier-based intelligent routing

⚡ Parallel proposal execution

🧱 Upgradeable and role-secured architecture

System Architecture
┌───────────────────────────────────────────────────────────┐
│                      AccessManager                        │
│ • Role-based permissions (ADMIN, PAUSER, AGGREGATOR)      │
│ • Provider blacklist management                           │
│ • Global pause/unpause                                    │
└───────────────────────────────────────────────────────────┘
           ↓
┌───────────────────────────────────────────────────────────┐
│                     TimelockAdmin                         │
│ • 48-hour delay for upgrades                              │
│ • Queued + cancellable proposals                          │
│ • Prevents instant malicious upgrades                     │
└───────────────────────────────────────────────────────────┘
           ↓
┌───────────────────────────────────────────────────────────┐
│               PayNodeGatewaySettings                      │
│ • Protocol config, fees, and tier limits                  │
│ • Supported token registry                                │
│ • Treasury + Aggregator addresses                         │
└───────────────────────────────────────────────────────────┘
           ↓
┌───────────────────────────────────────────────────────────┐
│                   PayNodeGateway (Proxy)                  │
│ • Order lifecycle management                              │
│ • Provider registration & tracking                        │
│ • Proposal creation & execution                           │
│ • Refunds and reputation updates                          │
└───────────────────────────────────────────────────────────┘

Contract Layers
1️⃣ AccessManager (RBAC)

Centralized permission control.

Roles

ADMIN_ROLE       → Full system control
PAUSER_ROLE      → Pause/unpause
AGGREGATOR_ROLE  → Manage off-chain routing + proposals
UPGRADER_ROLE    → Queue upgrades


Core Functions

grantRole(role, account)
revokeRole(role, account)
blacklistProvider(address)
removeFromBlacklist(address)
pause()
unpause()

2️⃣ TimelockAdmin (Secure Upgrades)

Controls all upgrades with enforced delay.

Parameters

minDelay = 2 days
executionWindow = 7 days


Flow

scheduleUpgrade(implementation, data)
→ queued for 48h
→ executeUpgrade(proposalId)
→ or cancelUpgrade(proposalId)

3️⃣ PayNodeGatewaySettings (Configuration)

Purpose:
Central hub for configurable parameters.

Core Variables

MAX_BPS = 100_000
protocolFeePercent (0–5%)
orderExpiryWindow = 1 hour
proposalTimeout = 30 seconds
treasuryAddress
aggregatorAddress


Tier Limits

ALPHA (< 3,000)
BETA (3,000 - 5,000)
DELTA (5,000 - 7,000)
OMEGA (7,000 - 10,000)
TITAN (> 10,000)


Token Management

supportedTokens mapping
addSupportedToken(address)
removeSupportedToken(address)

4️⃣ PayNodeGateway (Main Contract)

Responsibilities

Order lifecycle (create → propose → accept → settle)

Provider registration & tracking

Settlement execution

Refunds & reputation scoring

Provider Registration (Intent System)
Flow
Provider registers intent
├─ registerIntent(currency, amount, fees, window)
│  └ stored in providerIntents mapping
│  └ emits IntentRegistered
│
updateIntent(currency, newAmount)
├─ refresh capacity & expiry
└─ emits IntentUpdated

expireIntent(provider)
├─ sets isActive = false
└─ emits IntentExpired


Functions

registerIntent(currency, amount, minFee, maxFee, window)
updateIntent(currency, newAmount)
expireIntent(provider)
reserveIntent(provider, amount)
releaseIntent(provider, amount, reason)
getProviderIntent(provider)

Order Lifecycle
A. Creation
createOrder(token, amount, refundAddress)
├─ Validate supported token
├─ Determine tier (via GatewaySettings)
├─ Lock user funds in contract
├─ Emit OrderCreated
└─ Status: PENDING


Functions

createOrder(token, amount, refundAddress)
getOrder(orderId)
getUserNonce(user)

B. Tier-Based Routing
ALPHA (< 3,000)
├─ Route to all active ALPHA-tier providers
├─ First to accept wins

BETA (3,000 - 5,000)
├─ Route to all active BETA-tier providers
├─ First to accept wins

DELTA (5,000 - 7,000)
├─ Filter DELTA-tier providers by score
├─ Send to top 5 only

OMEGA (7,000 - 10,000)
├─ Filter OMEGA-tier providers by score
├─ Send to top 3 only
├─ Sequential fallback if provider rejects

TITAN (> 10,000)
├─ Route only to TITAN-tier providers
├─ Must have sufficient capacity
├─ Sequential fallback if provider rejects


Tier logic lives off-chain — aggregator applies these routing rules using provider data from its backend.

C. Proposal Flow (Parallel Execution)
Aggregator:
createProposal(orderId, provider, feeBps)
├─ Validate: order pending & active intent
├─ Check capacity >= order amount
├─ Reserve provider capacity
├─ Emit SettlementProposalCreated
└─ Status: PROPOSED

Provider:
acceptProposal(proposalId)
├─ Validate provider identity
├─ Mark as ACCEPTED
├─ Reject all other proposals
└─ Emit SettlementProposalAccepted

Timeout:
timeoutProposal(proposalId)
├─ block.timestamp > deadline
├─ Mark as TIMEOUT
└─ Release capacity

D. Settlement Execution
executeSettlement(proposalId)
├─ Validate: proposal accepted
├─ Calculate protocol + provider fees
├─ Transfer protocolFee → treasury
├─ Transfer providerAmount → provider
├─ Mark order as FULFILLED
└─ Emit SettlementExecuted

E. Refunds
Auto-Refund
refundOrder(orderId)
├─ Called by aggregator
├─ Validate: expired or unfulfilled
└─ Refund user

Manual Refund
requestRefund(orderId)
├─ Called by user
├─ Validate: not fulfilled
└─ Refund user

F. Reputation System
_updateProviderSuccess(provider)
├─ successfulOrders++
├─ totalSettlementTime += Δt
└─ Emit ProviderReputationUpdated

flagFraudulent(provider)
├─ isFraudulent = true
├─ isActive = false
└─ Emit ProviderFraudFlagged

Blacklist
blacklistProvider(provider)
├─ AccessManager-only
└─ Emit ProviderBlacklisted

Access Control Matrix
Function	Admin	Pauser	Aggregator	Provider	User
createOrder	✓	-	✓	-	✓
registerIntent	✓	-	✓	✓	-
createProposal	✓	-	✓	-	-
acceptProposal	✓	-	-	✓	-
executeSettlement	✓	-	✓	-	-
refundOrder	✓	-	✓	-	-
blacklistProvider	✓	-	-	-	-
pause/unpause	✓	✓	-	-	-
Key Features

✅ Parallel Settlement – Multiple providers race to accept
✅ Time-Bound Proposals – Prevents hanging orders
✅ Tier-Based Routing – Intelligent, off-chain optimization
✅ Reputation Scoring – Penalizes slow or failed providers
✅ Non-Custodial – Funds never leave escrow before settlement
✅ Upgradeable & Secure – Timelock + UUPS proxy pattern
✅ Access Control – Granular roles
✅ Emergency Pause – Fast failsafe
✅ Blacklist Protection – Malicious providers blocked

Deployment Order
1. Deploy AccessManager
2. Deploy TimelockAdmin (owner = AccessManager)
3. Deploy PayNodeGatewaySettings
4. Deploy PayNodeGateway (implementation)
5. Deploy ERC1967Proxy (pointing to Gateway)
6. Call initialize() on proxy
7. Transfer ownership to TimelockAdmin

Security Features

✅ ReentrancyGuard on state-changing functions

✅ Pausable fallback for emergencies

✅ RBAC with AccessManager

✅ 48-hour upgrade timelock

✅ Fraud and blacklist system

✅ Tier-based routing for fair load distribution

✅ Transparent events for all critical actions


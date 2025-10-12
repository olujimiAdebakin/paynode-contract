# PayNode Architecture Diagram

## System Layers

```
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                          🔐 AccessManager                                ║
║                                                                           ║
║  ├─ Admin role control                                                   ║
║  ├─ Pause/Unpause permissions                                            ║
║  ├─ Blacklist management                                                 ║
║  └─ Role-based access control (RBAC)                                     ║
║                                                                           ║
║                        [Permissions Layer]                               ║
╚═══════════════════════════════════════════════════════════════════════════╝
                                    ↓
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                          ⏱️  TimelockAdmin                               ║
║                                                                           ║
║  ├─ Upgrade scheduling (48h delay)                                       ║
║  ├─ Proposal queuing                                                     ║
║  ├─ Execution after timelock                                             ║
║  └─ Cancel malicious upgrades                                            ║
║                                                                           ║
║                       [Governance Layer]                                 ║
╚═══════════════════════════════════════════════════════════════════════════╝
                                    ↓
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                    ⚙️  PayNodeGatewaySettings                            ║
║                                                                           ║
║  ├─ Configuration parameters (fees, limits)                              ║
║  ├─ Token whitelist management                                           ║
║  ├─ Fee settings (protocol fee, tier fees)                               ║
║  └─ Tier limits (SMALL < 5K, MEDIUM 5K-20K, LARGE > 20K)                ║
║                                                                           ║
║                     [Configuration Layer]                                ║
╚═══════════════════════════════════════════════════════════════════════════╝
                                    ↓
╔═══════════════════════════════════════════════════════════════════════════╗
║                                                                           ║
║                    💳 PayNodeGateway (Proxy)                             ║
║                                                                           ║
║  ├─ Order creation & management                                          ║
║  ├─ Provider intent registry (capacity pre-registration)                 ║
║  ├─ Parallel settlement proposals (multiple providers race)              ║
║  ├─ Settlement execution & fund transfers                                ║
║  ├─ Refund handling (auto & manual)                                      ║
║  └─ Provider reputation tracking & scoring                               ║
║                                                                           ║
║                        [Core Logic Layer]                                ║
╚═══════════════════════════════════════════════════════════════════════════╝

🔑 Key Features:
   ✓ Non-Custodial (funds locked in escrow)
   ✓ Parallel Settlement (multiple providers compete)
   ✓ Role-Based Access (fine-grained permissions)
   ✓ Timelocked Upgrades (48h security delay)
   ✓ Provider Reputation (smart scoring system)
   ✓ Tier-Based Routing (optimized for order size)
```

---

## Order Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         USER CREATES ORDER                              │
│                                                                         │
│  createOrder(token, amount, refundAddress)                             │
│         ↓                                                               │
│  ✓ Validate token supported & amount > 0                               │
│  ✓ Determine tier (SMALL/MEDIUM/LARGE)                                 │
│  ✓ Transfer tokens from user to contract                               │
│  ✓ Generate unique orderId                                             │
│  ✓ Store order with status = PENDING                                   │
│         ↓                                                               │
│              Order Status: PENDING ✓                                    │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    AGGREGATOR SENDS PROPOSALS                           │
│                                                                         │
│  createProposal(orderId, provider_A, fee)                              │
│  createProposal(orderId, provider_B, fee)                              │
│  createProposal(orderId, provider_C, fee)  ← Parallel!                 │
│         ↓                                                               │
│  ✓ Check intent active & capacity sufficient                           │
│  ✓ Reserve capacity for each provider                                  │
│  ✓ Set proposal deadline = now + commitmentWindow                      │
│  ✓ Store proposals with status = PENDING                               │
│         ↓                                                               │
│              Order Status: PROPOSED ✓                                   │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                    PROVIDERS RACE (First Wins!)                         │
│                                                                         │
│  Provider_A: acceptProposal(proposalId_A) ✅ ACCEPTED                  │
│  Provider_B: timeout / rejected                                         │
│  Provider_C: timeout / rejected                                         │
│         ↓                                                               │
│  ✓ Set proposal status = ACCEPTED                                      │
│  ✓ Release reserved capacity for B & C                                 │
│  ✓ Update order with acceptedProposalId                                │
│         ↓                                                               │
│              Order Status: ACCEPTED ✓                                   │
└─────────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                     AGGREGATOR EXECUTES                                 │
│                                                                         │
│  executeSettlement(proposalId_A)                                       │
│         ↓                                                               │
│  ✓ Calculate fees:                                                      │
│    - protocolFee = (amount × protocolFeePercent) / 100,000             │
│    - providerFee = (amount × proposedFeeBps) / 100,000                 │
│    - providerAmount = amount - protocolFee - providerFee               │
│         ↓                                                               │
│  ✓ Transfer protocolFee → treasuryAddress                              │
│  ✓ Transfer providerAmount → provider_A                                │
│  ✓ Update provider reputation (success)                                │
│         ↓                                                               │
│              Order Status: FULFILLED ✓                                  │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Provider Intent Flow

```
┌──────────────────────────────────────┐
│   Provider Registration              │
│                                      │
│  registerIntent(                     │
│    currency: "NGN",                  │
│    amount: 50,000,                   │
│    minFee: 200 BPS,                  │
│    maxFee: 500 BPS,                  │
│    commitmentWindow: 30s              │
│  )                                   │
│                                      │
│  → Stored in providerIntents         │
│  → Expires in 5 minutes              │
│  → isActive = true                   │
└──────────────────────────────────────┘
           ↓
┌──────────────────────────────────────┐
│   Intent Active (Ready to match)     │
│                                      │
│  ✓ Listed in provider rankings       │
│  ✓ Available for proposals           │
│  ✓ Can be updated anytime            │
└──────────────────────────────────────┘
           ↓
        (If selected)
           ↓
┌──────────────────────────────────────┐
│   Capacity Reserved                  │
│                                      │
│  ✓ availableAmount -= orderAmount    │
│  ✓ Prevents double-booking           │
│  ✓ Locked until acceptance/timeout   │
└──────────────────────────────────────┘
           ↓
    (Provider accepts or rejects)
           ↓
┌──────────────────────────────────────┐
│   Capacity Released/Kept             │
│                                      │
│  If REJECTED or TIMEOUT:             │
│  ✓ availableAmount += orderAmount    │
│  ✓ Released for other orders         │
│                                      │
│  If ACCEPTED:                        │
│  ✓ Capacity held until execution     │
│  ✓ Transferred to provider on settle │
└──────────────────────────────────────┘
```

---

## Tier-Based Routing

```
Order Created
    ↓
┌─────────────────────────────────────────────────────────────┐
│ DETERMINE TIER                                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SMALL ORDER (< 5,000)        MEDIUM (5K - 20K)   LARGE (> 20K)
│  ├─ Send to ALL providers     ├─ Filter by score  ├─ Premium only
│  ├─ First to accept wins      ├─ Top 5 providers  ├─ Must have capacity
│  ├─ Fastest execution         ├─ Balanced speed   ├─ Quality > speed
│  └─ High throughput           └─ Quality + speed  └─ Lower volume
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Access Control Roles

```
┌─────────────────┐         ┌──────────────────┐
│   ADMIN_ROLE    │         │  PAUSER_ROLE     │
├─────────────────┤         ├──────────────────┤
│ • Full control  │         │ • Pause/Unpause  │
│ • Blacklist     │         │ • Emergency stop │
│ • Settings      │         │ • System health  │
│ • Grant roles   │         │                  │
└─────────────────┘         └──────────────────┘
         ↑                           ↑
         │                           │
         └───────────────────────────┘
                   ↓
            AccessManager
                   ↑
         ┌─────────────────┐         ┌──────────────────┐
         │ AGGREGATOR_ROLE │         │ UPGRADER_ROLE    │
         ├─────────────────┤         ├──────────────────┤
         │ • Create orders │         │ • Queue upgrades │
         │ • Send proposals│         │ • Execute after  │
         │ • Execute settle│         │   timelock (48h) │
         │ • Timeout/refund│         │ • Cancel upgrade │
         └─────────────────┘         └──────────────────┘
```

graph TD
    A["🔐 AccessManager<br/>Permissions Layer<br/>────────────────<br/>• Admin role control<br/>• Pause/Unpause<br/>• Blacklist management<br/>• RBAC"] 
    
    B["⏱️ TimelockAdmin<br/>Governance Layer<br/>────────────────<br/>• Upgrade scheduling<br/>• 48h delay<br/>• Proposal queuing<br/>• Cancel malicious"]
    
    C["⚙️ PayNodeGatewaySettings<br/>Configuration Layer<br/>────────────────<br/>• Fee settings<br/>• Token whitelist<br/>• Tier limits<br/>• Protocol params"]
    
    D["💳 PayNodeGateway<br/>Core Logic Layer<br/>────────────────<br/>• Order creation<br/>• Provider intents<br/>• Parallel proposals<br/>• Settlement exec<br/>• Reputation tracking"]
    
    A --> B
    B --> C
    C --> D
    
    style A fill:#e0e7ff,stroke:#2563eb,stroke-width:2px,color:#1e40af
    style B fill:#e0e7ff,stroke:#2563eb,stroke-width:2px,color:#1e40af
    style C fill:#e0e7ff,stroke:#2563eb,stroke-width:2px,color:#1e40af
    style D fill:#cffafe,stroke:#0891b2,stroke-width:3px,color:#0c4a6e
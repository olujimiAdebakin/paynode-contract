pragma solidity ^0.8.18;

abstract contract TestConstants {
    // Tier Limits
    uint256 public constant ALPHA_LIMIT = 3000 ether;
    uint256 public constant BETA_LIMIT = 5000 ether;
    uint256 public constant DELTA_LIMIT = 7000 ether;
    uint256 public constant OMEGA_LIMIT = 10000 ether;
    uint256 public constant TITAN_LIMIT = 15000 ether;
    
    // Fees
    uint64 public constant PROTOCOL_FEE = 100; // 1%
    uint64 public constant INTEGRATOR_FEE = 200; // 2%
    uint64 public constant MIN_INTEGRATOR_FEE = 10; // 0.1%
    uint64 public constant MAX_INTEGRATOR_FEE = 500; // 5%
    
    // Time Durations
    uint256 public constant ORDER_EXPIRY = 1 hours;
    uint256 public constant PROPOSAL_TIMEOUT = 30 minutes;
    uint256 public constant INTENT_EXPIRY = 24 hours;
    
    // Test Amounts
    uint256 public constant TEST_AMOUNT = 1000 ether;
    uint256 public constant PROVIDER_CAPACITY = 5000 ether;
    
    // Currency
    string public constant TEST_CURRENCY = "USDT";
}
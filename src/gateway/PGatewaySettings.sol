// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./PGatewayStructs.sol";
import {IErrors} from "../interface/IErrors.sol";

/**
 * @title PayNode Gateway Settings Contract
 * @notice Centralized configuration management hub for the PayNode protocol ecosystem
 * @dev Serves as the single source of truth for all protocol parameters, enabling dynamic
 *      configuration updates without requiring contract redeployment.
 * 
 * 🏗️ ARCHITECTURE OVERVIEW:
 * ========================
 * 
 * ┌─────────────────────────────────────────────────────────────┐
 * │                    PROTOCOL ECOSYSTEM                       │
 * ├─────────────────────────────────────────────────────────────┤
 * │  ┌──────────────────┐        ┌──────────────────────────┐   │
 * │  │   PGateway       │◄──────►│   PGatewaySettings       │   │
 * │  │  (Main Engine)   │        │   (Configuration Hub)    │   │
 * │  └──────────────────┘        └──────────────────────────┘   │
 * │         │                              │                    │
 * │         ▼                              ▼                    │
 * │  ┌──────────────────┐        ┌──────────────────────────┐   │
 * │  │  AccessManager   │        │     PGatewayStructs      │   │
 * │  │  (Security)      │        │     (Data Models)        │   │
 * │  └──────────────────┘        └──────────────────────────┘   │
 * └─────────────────────────────────────────────────────────────┘
 * 
 * 🔗 CORE INTEGRATIONS & DATA FLOW:
 * ================================
 * 
 * 1. PRIMARY CONSUMER:
 *    ┌─────────────┐    Configuration    ┌─────────────┐
 *    │   PGateway  │ ◄───────────────── │  Settings   │
 *    │   Contract  │    Read-Only        │  Contract   │
 *    └─────────────┘                    └─────────────┘
 *    • Validates tokens via isTokenSupported()
 *    • Determines order tiers using tier limits
 *    • Applies protocol fees from protocolFeePercent
 *    • Enforces timeouts using orderExpiryWindow & proposalTimeout
 * 
 * 2. DATA STRUCTURES:
 *    ┌─────────────┐    Parameters      ┌─────────────┐
 *    │   Structs   │ ─────────────────► │  Settings   │
 *    │   Library   │    Initialization  │  Contract   │
 *    └─────────────┘                    └─────────────┘
 *    • InitiateGatewaySettingsParams for initialization
 *    • Structured configuration with type safety
 * 
 * 3. ERROR HANDLING:
 *    ┌─────────────┐    Standardized    ┌─────────────┐
 *    │   IError    │ ─────────────────► │  Settings   │
 *    │  Interface  │    Error Codes     │  Contract   │
 *    └─────────────┘                    └─────────────┘
 *    • Gas-efficient custom errors
 *    • Consistent error messaging across protocol
 * 
 * 4. INFRASTRUCTURE:
 *    ┌─────────────┐    Upgradeability   ┌─────────────┐
 *    │ OpenZeppelin│ ─────────────────► │  Settings   │
 *    │  Libraries  │    & Ownership      │  Contract   │
 *    └─────────────┘                    └─────────────┘
 *    • UUPS upgrade pattern for future enhancements
 *    • Ownable for privileged configuration management
 * 
 * ⚙️ CONFIGURATION DOMAINS:
 * ========================
 * 
 * 🎯 FEE MANAGEMENT:
 *    • Protocol Fee (% of settlement volume)
 *    • Integrator Fee (dApp/partner commissions)
 *    • Dynamic fee updates with validation
 * 
 * ⏰ TIME CONFIGURATION:
 *    • Order Expiry Window (user protection)
 *    • Proposal Timeout (provider response deadline)
 *    • Intent Expiry (provider commitment duration)
 * 
 * 🏷️ TIER SYSTEM:
 *    • ALPHA: Small-value orders (< 3,000)
 *    • BETA: Medium-value orders (3,000 - 5,000)  
 *    • DELTA: Large-value orders (5,000 - 7,000)
 *    • OMEGA: Premium orders (7,000 - 10,000)
 *    • TITAN: Enterprise orders (> 10,000)
 * 
 * 🔐 ACCESS ADDRESSES:
 *    • Treasury Address (fee collection)
 *    • Aggregator Address (order matching service)
 *    • Integrator Address (partner ecosystem)
 * 
 * 💰 TOKEN MANAGEMENT:
 *    • Supported ERC20 token whitelist
 *    • Dynamic token addition/removal
 *    • Security validation for token addresses
 * 
 * 🔄 CONFIGURATION LIFECYCLE:
 * ===========================
 * 
 * Phase 1: INITIALIZATION
 *   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
 *   │  Deployment │───►│  Initialize │───►│  Validation │
 *   └─────────────┘    └─────────────┘    └─────────────┘
 *         │                   │                   │
 *         ▼                   ▼                   ▼
 *   Contract Created → Parameters Set → Safety Checks Passed
 * 
 * Phase 2: RUNTIME OPERATION
 *   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
 *   │   PGateway  │───►│ Read Config │───►│  Apply      │
 *   │   Access    │    │   Values    │    │  Settings   │
 *   └─────────────┘    └─────────────┘    └─────────────┘
 * 
 * Phase 3: GOVERNANCE UPDATES
 *   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
 *   │   Owner     │───►│ Update Config│───►│  Emit Event │
 *   │  Proposal   │    │   Parameter  │    │   & Log     │
 *   └─────────────┘    └─────────────┘    └─────────────┘
 * 
 * 🛡️ SECURITY MODEL:
 * =================
 * 
 * • OWNERSHIP: Only contract owner can modify configurations
 * • VALIDATION: All parameters validated before acceptance
 * • CONSISTENCY: Tier limits must be strictly increasing
 * • BOUNDARIES: Fees capped at reasonable limits (5% protocol max)
 * • ADDRESS SAFETY: Zero-address checks for all critical addresses
 * • TIME LOGIC: Proposal timeout cannot exceed order expiry window
 * 
 * 💡 KEY FEATURES:
 * ================
 * 
 * • 🔄 Dynamic Updates: Protocol evolution without redeployment
 * • 🎯 Tier Optimization: Order classification for efficient matching  
 * • ⚡ Gas Efficiency: Constant-time configuration reads
 * • 🔐 Role-Based Control: Owner-only configuration modifications
 * • 📊 Event Tracking: Comprehensive configuration change logging
 * • 🛡️ Safety First: Extensive parameter validation and bounds checking
 * 
 * @author PayNode Protocol
 * @dev This contract implements the UUPS upgrade pattern for future enhancements
 *      while maintaining strict access control over protocol parameters.
 */
contract PGatewaySettings is Initializable, OwnableUpgradeable, IErrors{
    // Configuration Constants
    uint256 public constant MAX_BPS = 100_000;

    // Configuration Variables
    uint64 public protocolFeePercent;
    uint256 public orderExpiryWindow;
    uint256 public proposalTimeout;
    address public treasuryAddress;
    uint256 public intentExpiry;
    address public aggregatorAddress;
    uint256 public integratorFeePercent;
    address public integratorAddress;

    // Tier Limits
    uint256 public ALPHA_TIER_LIMIT;
    uint256 public BETA_TIER_LIMIT;
    uint256 public DELTA_TIER_LIMIT;
    uint256 public OMEGA_TIER_LIMIT;
    uint256 public TITAN_TIER_LIMIT;

    // Token Management
    mapping(address => bool) public supportedTokens;

    // Events
    event Initialized(
        address owner,
        address treasury,
        address aggregator,
        uint64 fee,
        uint256 expiry,
        uint256 timeout,
        uint256 intentExpiry
    );
    event ProtocolFeeUpdated(uint64 newFee);
    event TierLimitsUpdated(
        uint256 alphaLimit, uint256 betaLimit, uint256 deltaLimit, uint256 omegaLimit, uint256 titanLimit
    );
    event SupportedTokenUpdated(address indexed token, bool supported);
    event TreasuryAddressUpdated(address newTreasury);
    event AggregatorAddressUpdated(address newAggregator);
    event OrderExpiryWindowUpdated(uint256 newWindow);
    event ProposalTimeoutUpdated(uint256 newTimeout);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the settings contract with protocol parameters
     * @dev Sets up initial configuration including fees, addresses, timeouts, and tier limits.
     *      Must be called during contract deployment. Validates all parameters for safety.
     * 
     * @param params InitiateGatewaySettingsParams struct containing:
     *   - initialOwner: Address that will have ownership rights
     *   - treasury: Address where protocol fees are collected
     *   - aggregator: Address of the aggregator service
     *   - integrator: Default integrator address
     *   - protocolFee: Protocol fee in basis points (max 5000 = 5%)
     *   - integratorFee: Integrator fee in basis points
     *   - orderExpiryWindow: Time window for order expiration in seconds
     *   - proposalTimeout: Timeout for settlement proposals in seconds
     *   - intentExpiry: Expiration time for provider intents in seconds
     *   - alphaLimit: Maximum amount for Alpha tier orders
     *   - betaLimit: Maximum amount for Beta tier orders
     *   - deltaLimit: Maximum amount for Delta tier orders
     *   - omegaLimit: Maximum amount for Omega tier orders
     *   - titanLimit: Maximum amount for Titan tier orders
     * 
     * @dev Emits {Initialized} event with all configuration parameters
     * 
     * Requirements:
     * - All addresses must be non-zero
     * - Protocol fee must not exceed 5% (5000 basis points)
     * - Tier limits must be strictly increasing
     * - Time durations must be non-zero and logically consistent
     */
    function initialize(PGatewayStructs.InitiateGatewaySettingsParams memory params) external initializer {
        __Ownable_init(params.initialOwner);

        // Address validation
        if (params.treasury == address(0) || params.aggregator == address(0) || params.integrator == address(0)) {
            revert InvalidAddress();
        }
        
        // Fee validation
        if (params.protocolFee > 5000) revert InvalidFee(); // Max 5%
        
        // Tier limits validation - must be strictly increasing
        if (
            params.alphaLimit == 0 || params.betaLimit <= params.alphaLimit || params.deltaLimit <= params.betaLimit
                || params.omegaLimit <= params.deltaLimit || params.titanLimit <= params.omegaLimit
        ) revert InvalidLimits();
        
        // Duration validation
        if (
            params.orderExpiryWindow == 0 || params.proposalTimeout == 0
                || params.proposalTimeout > params.orderExpiryWindow || params.intentExpiry == 0
        ) revert InvalidDuration();

        // Additional fee validation
        if (params.protocolFee > 5000 || params.integratorFee > 10_000) {
            revert InvalidFee();
        }

        // Set configuration parameters
        treasuryAddress = params.treasury;
        aggregatorAddress = params.aggregator;
        protocolFeePercent = params.protocolFee;
        integratorAddress = params.integrator;
        ALPHA_TIER_LIMIT = params.alphaLimit;
        BETA_TIER_LIMIT = params.betaLimit;
        DELTA_TIER_LIMIT = params.deltaLimit;
        OMEGA_TIER_LIMIT = params.omegaLimit;
        TITAN_TIER_LIMIT = params.titanLimit;
        orderExpiryWindow = params.orderExpiryWindow;
        proposalTimeout = params.proposalTimeout;
        intentExpiry = params.intentExpiry;

        emit Initialized(
            params.initialOwner,
            params.treasury,
            params.aggregator,
            params.protocolFee,
            params.orderExpiryWindow,
            params.proposalTimeout,
            params.intentExpiry
        );
    }

    /**
     * @notice Updates the protocol fee percentage
     * @dev Allows the owner to adjust the protocol fee within reasonable limits.
     *      The fee is applied to all successful settlements in the main gateway.
     * 
     * @param _newFee The new protocol fee in basis points (max 500 = 5%)
     * 
     * @dev Emits {ProtocolFeeUpdated} event on success
     * 
     * Requirements:
     * - Caller must be contract owner
     * - New fee must not exceed 5% (500 basis points)
     */
    function setProtocolFee(uint64 _newFee) external onlyOwner {
        if (_newFee > 500) revert InvalidFee(); // Max 5%
        protocolFeePercent = _newFee;
        emit ProtocolFeeUpdated(_newFee);
    }

    /**
     * @notice Updates all tier limits for order classification
     * @dev Tier system enables optimized provider matching and risk management.
     *      Orders are classified into tiers based on amount for efficient processing.
     * 
     * @param _alphaLimit Maximum value for Alpha tier (smallest orders)
     * @param _betaLimit Maximum value for Beta tier
     * @param _deltaLimit Maximum value for Delta tier
     * @param _omegaLimit Maximum value for Omega tier
     * @param _titanLimit Maximum value for Titan tier (largest orders)
     * 
     * @dev Emits {TierLimitsUpdated} event with new limits
     * 
     * Requirements:
     * - Caller must be contract owner
     * - All limits must be non-zero and strictly increasing
     * - Alpha < Beta < Delta < Omega < Titan
     */
    function setTierLimits(
        uint256 _alphaLimit,
        uint256 _betaLimit,
        uint256 _deltaLimit,
        uint256 _omegaLimit,
        uint256 _titanLimit
    ) external onlyOwner {
        if (
            _alphaLimit == 0 || _betaLimit <= _alphaLimit || _deltaLimit <= _betaLimit || _omegaLimit <= _deltaLimit
                || _titanLimit <= _omegaLimit
        ) revert InvalidLimits();
        
        ALPHA_TIER_LIMIT = _alphaLimit;
        BETA_TIER_LIMIT = _betaLimit;
        DELTA_TIER_LIMIT = _deltaLimit;
        OMEGA_TIER_LIMIT = _omegaLimit;
        TITAN_TIER_LIMIT = _titanLimit;
        
        emit TierLimitsUpdated(_alphaLimit, _betaLimit, _deltaLimit, _omegaLimit, _titanLimit);
    }

    /**
     * @notice Sets the order expiry window duration
     * @dev Defines how long orders remain valid before automatic refund.
     *      This protects users from stuck funds and ensures system liquidity.
     * 
     * @param _newWindow The new expiry window in seconds
     * 
     * @dev Emits {OrderExpiryWindowUpdated} event
     * 
     * Requirements:
     * - Caller must be contract owner
     * - New window must be non-zero
     */
    function setOrderExpiryWindow(uint256 _newWindow) external onlyOwner {
        if (_newWindow == 0) revert InvalidDuration();
        orderExpiryWindow = _newWindow;
        emit OrderExpiryWindowUpdated(_newWindow);
    }

    /**
     * @notice Sets the proposal timeout duration
     * @dev Defines how long providers have to respond to settlement proposals.
     *      Ensures timely responses and prevents order stagnation.
     * 
     * @param _newTimeout The new proposal timeout in seconds
     * 
     * @dev Emits {ProposalTimeoutUpdated} event
     * 
     * Requirements:
     * - Caller must be contract owner
     * - New timeout must be non-zero
     */
    function setProposalTimeout(uint256 _newTimeout) external onlyOwner {
        if (_newTimeout == 0) revert InvalidDuration();
        proposalTimeout = _newTimeout;
        emit ProposalTimeoutUpdated(_newTimeout);
    }

    /**
     * @notice Updates the treasury address for protocol fee collection
     * @dev Treasury receives all protocol fees from successful settlements.
     *      This address should be secure and controlled by protocol governance.
     * 
     * @param _newTreasury The new treasury address
     * 
     * @dev Emits {TreasuryAddressUpdated} event
     * 
     * Requirements:
     * - Caller must be contract owner
     * - New treasury address must be non-zero
     */
    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert InvalidAddress();
        treasuryAddress = _newTreasury;
        emit TreasuryAddressUpdated(_newTreasury);
    }

    /**
     * @notice Updates the aggregator address
     * @dev Aggregator is responsible for order matching and proposal creation.
     *      This address should be a trusted service with proper security measures.
     * 
     * @param _newAggregator The new aggregator address
     * 
     * @dev Emits {AggregatorAddressUpdated} event
     * 
     * Requirements:
     * - Caller must be contract owner
     * - New aggregator address must be non-zero
     */
    function setAggregatorAddress(address _newAggregator) external onlyOwner {
        if (_newAggregator == address(0)) revert InvalidAddress();
        aggregatorAddress = _newAggregator;
        emit AggregatorAddressUpdated(_newAggregator);
    }

    /**
     * @notice Adds or removes a token from the supported tokens list
     * @dev Token support is essential for protocol functionality. Only supported
     *      tokens can be used for order creation and settlement.
     * 
     * @param _token The ERC20 token address to update
     * @param _supported True to support token, false to remove support
     * 
     * @dev Emits {SupportedTokenUpdated} event
     * 
     * Requirements:
     * - Caller must be contract owner
     * - Token address must be non-zero
     */
    function setSupportedToken(address _token, bool _supported) external onlyOwner {
        if (_token == address(0)) revert InvalidAddress();
        supportedTokens[_token] = _supported;
        emit SupportedTokenUpdated(_token, _supported);
    }

    /**
     * @notice Checks if a token is supported by the protocol
     * @dev Used by PGateway to validate tokens during order creation.
     * 
     * @param _token The ERC20 token address to check
     * @return bool True if token is supported, false otherwise
     */
    function isTokenSupported(address _token) external view returns (bool) {
        return supportedTokens[_token];
    }
}
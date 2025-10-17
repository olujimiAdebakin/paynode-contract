// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title PayNodeGatewaySettings
 * @notice Centralized configuration management for the PayNode protocol
 */
contract PGatewaySettings is Initializable, OwnableUpgradeable {
    // Configuration Constants
    uint256 public constant MAX_BPS = 100_000;

    // Configuration Variables
    uint64 public protocolFeePercent;
    uint256 public orderExpiryWindow;
    uint256 public proposalTimeout;
    address public treasuryAddress;
     uint256 public intentExpiry;
    address public aggregatorAddress;

    // Tier Limits
    uint256 public ALPHA_TIER_LIMIT; // < 3,000
    uint256 public BETA_TIER_LIMIT; // 3,000 - 5,000
    uint256 public DELTA_TIER_LIMIT; // 5,000 - 7,000
    uint256 public OMEGA_TIER_LIMIT; // 7,000 - 10,000
    uint256 public TITAN_TIER_LIMIT; // > 10,000

    // Token Management
    mapping(address => bool) public supportedTokens;

    // Events
     event Initialized(address owner, address treasury, address aggregator, uint64 fee, uint256 expiry, uint256 timeout, uint256 intentExpiry);
    event ProtocolFeeUpdated(uint64 newFee);
    event TierLimitsUpdated(
        uint256 alphaLimit, uint256 betaLimit, uint256 deltaLimit, uint256 omegaLimit, uint256 titanLimit
    );
    event SupportedTokenUpdated(address indexed token, bool supported);
    event TreasuryAddressUpdated(address newTreasury);
    event AggregatorAddressUpdated(address newAggregator);
    event OrderExpiryWindowUpdated(uint256 newWindow);
    event ProposalTimeoutUpdated(uint256 newTimeout);

    // Errors
    error InvalidFee();
    error InvalidLimits();
    error InvalidAddress();
    error InvalidDuration();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        address _treasury,
        address _aggregator,
        uint64 _protocolFee,
        uint256 _alphaLimit,
        uint256 _betaLimit,
        uint256 _deltaLimit,
        uint256 _omegaLimit,
        uint256 _titanLimit,
        uint256 _orderExpiryWindow,
        uint256 _proposalTimeout,
        uint256 _intentExpiry
    ) external initializer {
        __Ownable_init(initialOwner);

        if (_treasury == address(0) || _aggregator == address(0)) revert InvalidAddress();
        if (_protocolFee > 5000) revert InvalidFee(); // Max 5%
        if (
            _alphaLimit == 0 || _betaLimit <= _alphaLimit || _deltaLimit <= _betaLimit || _omegaLimit <= _deltaLimit
                || _titanLimit <= _omegaLimit
        ) revert InvalidLimits();
        if (_orderExpiryWindow == 0 || _proposalTimeout == 0 || _proposalTimeout > _orderExpiryWindow || _intentExpiry == 0) revert InvalidDuration();

        treasuryAddress = _treasury;
        aggregatorAddress = _aggregator;
        protocolFeePercent = _protocolFee;
        ALPHA_TIER_LIMIT = _alphaLimit;
        BETA_TIER_LIMIT = _betaLimit;
        DELTA_TIER_LIMIT = _deltaLimit;
        OMEGA_TIER_LIMIT = _omegaLimit;
        TITAN_TIER_LIMIT = _titanLimit;
        orderExpiryWindow = _orderExpiryWindow;
        proposalTimeout = _proposalTimeout;
        intentExpiry = _intentExpiry;

        emit Initialized(initialOwner, _treasury, _aggregator, _protocolFee, _orderExpiryWindow, _proposalTimeout, _intentExpiry);
    }

    /// @notice Updates the protocol fee percentage
    /// @param _newFee The new protocol fee in basis points (max 5000 = 5%)
    /// @dev Only callable by contract owner
    function setProtocolFee(uint64 _newFee) external onlyOwner {
        if (_newFee > 500) revert InvalidFee(); // Max 5%
        protocolFeePercent = _newFee;
        emit ProtocolFeeUpdated(_newFee);
    }

    /// @notice Updates all tier limits for the protocol
    /// @param _alphaLimit Maximum value for Alpha tier (< 3,000)
    /// @param _betaLimit Maximum value for Beta tier (3,000 - 5,000)
    /// @param _deltaLimit Maximum value for Delta tier (5,000 - 7,000)
    /// @param _omegaLimit Maximum value for Omega tier (7,000 - 10,000)
    /// @param _titanLimit Maximum value for Titan tier (> 10,000)
    /// @dev Only callable by contract owner. Validates that each limit is greater than the previous.
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

    /// @notice Sets the order expiry window duration
    /// @param _newWindow The new expiry window in seconds
    /// @dev Only callable by contract owner. Cannot be zero.
    function setOrderExpiryWindow(uint256 _newWindow) external onlyOwner {
        if (_newWindow == 0) revert InvalidDuration();
        orderExpiryWindow = _newWindow;
        emit OrderExpiryWindowUpdated(_newWindow);
    }

    /// @notice Sets the proposal timeout duration
    /// @param _newTimeout The new proposal timeout in seconds
    /// @dev Only callable by contract owner. Cannot be zero.
    function setProposalTimeout(uint256 _newTimeout) external onlyOwner {
        if (_newTimeout == 0) revert InvalidDuration();
        proposalTimeout = _newTimeout;
        emit ProposalTimeoutUpdated(_newTimeout);
    }

    /// @notice Updates the treasury address for protocol fee collection
    /// @param _newTreasury The new treasury address
    /// @dev Only callable by contract owner. Cannot be zero address.
    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert InvalidAddress();
        treasuryAddress = _newTreasury;
        emit TreasuryAddressUpdated(_newTreasury);
    }

    /// @notice Updates the aggregator address
    /// @param _newAggregator The new aggregator address
    /// @dev Only callable by contract owner. Cannot be zero address.
    function setAggregatorAddress(address _newAggregator) external onlyOwner {
        if (_newAggregator == address(0)) revert InvalidAddress();
        aggregatorAddress = _newAggregator;
        emit AggregatorAddressUpdated(_newAggregator);
    }

    /// @notice Adds or removes a token from the supported tokens list
    /// @param _token The token address to update
    /// @param _supported True to add token, false to remove
    /// @dev Only callable by contract owner. Cannot be zero address.
    function setSupportedToken(address _token, bool _supported) external onlyOwner {
        if (_token == address(0)) revert InvalidAddress();
        supportedTokens[_token] = _supported;
        emit SupportedTokenUpdated(_token, _supported);
    }

    /// @notice Checks if a token is supported by the protocol
    /// @param _token The token address to check
    /// @return bool True if token is supported, false otherwise
    function isTokenSupported(address _token) external view returns (bool) {
        return supportedTokens[_token];
    }
}

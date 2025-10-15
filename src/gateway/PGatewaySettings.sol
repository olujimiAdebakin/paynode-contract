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
    uint256 public SMALL_TIER_LIMIT;
    uint256 public MEDIUM_TIER_LIMIT;
    uint64 public protocolFeePercent;
    uint256 public orderExpiryWindow;
    uint256 public proposalTimeout;
    address public treasuryAddress;
    address public aggregatorAddress;

    // Token Management
    mapping(address => bool) public supportedTokens;

    // Events
    event ProtocolFeeUpdated(uint64 newFee);
    event TierLimitsUpdated(uint256 smallLimit, uint256 mediumLimit);
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
        uint256 _smallLimit,
        uint256 _mediumLimit,
        uint256 _orderExpiryWindow,
        uint256 _proposalTimeout
    ) external initializer {
        __Ownable_init(initialOwner);

        if (_treasury == address(0) || _aggregator == address(0)) revert InvalidAddress();
        if (_protocolFee > 5000) revert InvalidFee(); // Max 5%
        if (_smallLimit == 0 || _mediumLimit <= _smallLimit) revert InvalidLimits();
        if (_orderExpiryWindow == 0 || _proposalTimeout == 0) revert InvalidDuration();

        treasuryAddress = _treasury;
        aggregatorAddress = _aggregator;
        protocolFeePercent = _protocolFee;
        SMALL_TIER_LIMIT = _smallLimit;
        MEDIUM_TIER_LIMIT = _mediumLimit;
        orderExpiryWindow = _orderExpiryWindow;
        proposalTimeout = _proposalTimeout;
    }

    function setProtocolFee(uint64 _newFee) external onlyOwner {
        if (_newFee > 5000) revert InvalidFee(); // Max 5%
        protocolFeePercent = _newFee;
        emit ProtocolFeeUpdated(_newFee);
    }

    function setTierLimits(uint256 _smallLimit, uint256 _mediumLimit) external onlyOwner {
        if (_smallLimit == 0 || _mediumLimit <= _smallLimit) revert InvalidLimits();
        SMALL_TIER_LIMIT = _smallLimit;
        MEDIUM_TIER_LIMIT = _mediumLimit;
        emit TierLimitsUpdated(_smallLimit, _mediumLimit);
    }

    function setOrderExpiryWindow(uint256 _newWindow) external onlyOwner {
        if (_newWindow == 0) revert InvalidDuration();
        orderExpiryWindow = _newWindow;
        emit OrderExpiryWindowUpdated(_newWindow);
    }

    function setProposalTimeout(uint256 _newTimeout) external onlyOwner {
        if (_newTimeout == 0) revert InvalidDuration();
        proposalTimeout = _newTimeout;
        emit ProposalTimeoutUpdated(_newTimeout);
    }

    function setTreasuryAddress(address _newTreasury) external onlyOwner {
        if (_newTreasury == address(0)) revert InvalidAddress();
        treasuryAddress = _newTreasury;
        emit TreasuryAddressUpdated(_newTreasury);
    }

    function setAggregatorAddress(address _newAggregator) external onlyOwner {
        if (_newAggregator == address(0)) revert InvalidAddress();
        aggregatorAddress = _newAggregator;
        emit AggregatorAddressUpdated(_newAggregator);
    }

    function setSupportedToken(address _token, bool _supported) external onlyOwner {
        if (_token == address(0)) revert InvalidAddress();
        supportedTokens[_token] = _supported;
        emit SupportedTokenUpdated(_token, _supported);
    }

    // View Functions
    function isTokenSupported(address _token) external view returns (bool) {
        return supportedTokens[_token];
    }
}

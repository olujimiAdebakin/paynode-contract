
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IPGatewaySettings
 * @notice Interface for PayNode Gateway Settings configuration management
 */
interface IPGatewaySettings {
    // Events
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

    /**
     * @notice Updates the protocol fee percentage
     * @param _newFee The new protocol fee in basis points (max 5000 = 5%)
     */
    function setProtocolFee(uint64 _newFee) external;

    /**
     * @notice Updates all tier limits for the protocol
     * @param _alphaLimit Maximum value for Alpha tier (< 3,000)
     * @param _betaLimit Maximum value for Beta tier (3,000 - 5,000)
     * @param _deltaLimit Maximum value for Delta tier (5,000 - 7,000)
     * @param _omegaLimit Maximum value for Omega tier (7,000 - 10,000)
     * @param _titanLimit Maximum value for Titan tier (> 10,000)
     */
    function setTierLimits(
        uint256 _alphaLimit,
        uint256 _betaLimit,
        uint256 _deltaLimit,
        uint256 _omegaLimit,
        uint256 _titanLimit
    ) external;

    /**
     * @notice Sets the order expiry window duration
     * @param _newWindow The new expiry window in seconds
     */
    function setOrderExpiryWindow(uint256 _newWindow) external;

    /**
     * @notice Sets the proposal timeout duration
     * @param _newTimeout The new proposal timeout in seconds
     */
    function setProposalTimeout(uint256 _newTimeout) external;

    /**
     * @notice Updates the treasury address for protocol fee collection
     * @param _newTreasury The new treasury address
     */
    function setTreasuryAddress(address _newTreasury) external;

    /**
     * @notice Updates the aggregator address
     * @param _newAggregator The new aggregator address
     */
    function setAggregatorAddress(address _newAggregator) external;

    /**
     * @notice Adds or removes a token from the supported tokens list
     * @param _token The token address to update
     * @param _supported True to add token, false to remove
     */
    function setSupportedToken(address _token, bool _supported) external;

    /**
     * @notice Checks if a token is supported by the protocol
     * @param _token The token address to check
     * @return bool True if token is supported, false otherwise
     */
    function isTokenSupported(address _token) external view returns (bool);

    // State variable getters
    function protocolFeePercent() external view returns (uint64);
    function orderExpiryWindow() external view returns (uint256);
    function proposalTimeout() external view returns (uint256);
    function treasuryAddress() external view returns (address);
    function aggregatorAddress() external view returns (address);
    function ALPHA_TIER_LIMIT() external view returns (uint256);
    function BETA_TIER_LIMIT() external view returns (uint256);
    function DELTA_TIER_LIMIT() external view returns (uint256);
    function OMEGA_TIER_LIMIT() external view returns (uint256);
    function TITAN_TIER_LIMIT() external view returns (uint256);
    function MAX_BPS() external view returns (uint256);
}
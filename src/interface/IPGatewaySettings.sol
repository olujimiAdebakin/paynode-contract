// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title IPGatewaySettings
 * @notice Interface for configuring and managing PayNode Gateway protocol parameters.
 * @dev Defines administrative and configuration methods for managing protocol fees,
 * tier limits, expiry windows, and supported tokens. Only callable by governance or authorized admin.
 * @author Olujimi
 */
interface IPGatewaySettings {
    // ============================
    // Events
    // ============================

    event Initialized(
        address accessManager,
        address treasury,
        address aggregator,
        uint64 fee,
        uint64 maxFee,
        uint256 expiry,
        uint256 timeout,
        uint256 intentExpiry
    );

    /**
     * @notice Emitted when the protocol fee percentage is updated.
     * @param newFee The new protocol fee value in basis points (bps).
     */
    event ProtocolFeeUpdated(uint64 newFee);

    event MaxProtocolFeeUpdated(uint64 newMaxFee);

    event IntentExpiryUpdated(uint256 newExpiry);

    /**
     * @notice Emitted when all tier limits are updated.
     * @param alphaLimit Maximum transaction limit for Alpha tier.
     * @param betaLimit Maximum transaction limit for Beta tier.
     * @param deltaLimit Maximum transaction limit for Delta tier.
     * @param omegaLimit Maximum transaction limit for Omega tier.
     * @param titanLimit Maximum transaction limit for Titan tier.
     */
    event TierLimitsUpdated(
        uint256 alphaLimit, uint256 betaLimit, uint256 deltaLimit, uint256 omegaLimit, uint256 titanLimit
    );

    /**
     * @notice Emitted when token support is added or removed.
     * @param token The token address.
     * @param supported Whether the token is supported (true) or not (false).
     */
    event SupportedTokenUpdated(address indexed token, bool supported);

    /**
     * @notice Emitted when the treasury address is updated.
     * @param newTreasury The new treasury address.
     */
    event TreasuryAddressUpdated(address newTreasury);

    /**
     * @notice Emitted when the aggregator contract address is updated.
     * @param newAggregator The new aggregator address.
     */
    event AggregatorAddressUpdated(address newAggregator);

    /**
     * @notice Emitted when the order expiry window duration is updated.
     * @param newWindow The new expiry window value in seconds.
     */
    event OrderExpiryWindowUpdated(uint256 newWindow);

    /**
     * @notice Emitted when the proposal timeout duration is updated.
     * @param newTimeout The new timeout duration in seconds.
     */
    event ProposalTimeoutUpdated(uint256 newTimeout);

    // ============================
    // Errors
    // ============================

    /// @notice Thrown when an invalid fee value is provided.
    error InvalidFee();

    /// @notice Thrown when tier limits are inconsistent or below required thresholds.
    error InvalidLimits();

    /// @notice Thrown when an invalid or zero address is provided.
    error InvalidAddress();

    /// @notice Thrown when the provided duration value is invalid (e.g., zero or too short).
    error InvalidDuration();

    // ============================
    // Admin Functions
    // ============================

    /**
     * @notice Updates the protocol fee percentage.
     * @dev The fee is denominated in basis points (bps), where 10000 = 100%.
     * Maximum allowed fee is capped at 5000 bps (5%).
     * @param _newFee The new protocol fee in basis points.
     */
    function setProtocolFee(uint64 _newFee) external;

    /**
     * @notice Updates all tier limits for the protocol.
     * @dev Defines transaction boundaries for each tier classification.
     * @param _alphaLimit Maximum value for Alpha tier (< 3,000).
     * @param _betaLimit Maximum value for Beta tier (3,000 - 5,000).
     * @param _deltaLimit Maximum value for Delta tier (5,000 - 7,000).
     * @param _omegaLimit Maximum value for Omega tier (7,000 - 10,000).
     * @param _titanLimit Maximum value for Titan tier (> 10,000).
     */
    function setTierLimits(
        uint256 _alphaLimit,
        uint256 _betaLimit,
        uint256 _deltaLimit,
        uint256 _omegaLimit,
        uint256 _titanLimit
    ) external;

    /**
     * @notice Sets the order expiry window duration.
     * @dev Determines how long an order remains valid before expiring.
     * @param _newWindow The new expiry window in seconds.
     */
    function setOrderExpiryWindow(uint256 _newWindow) external;
    function integratorAddress() external view returns (address);
    function integratorFeePercent() external view returns (uint64);
    function setIntentExpiry(uint256 _newExpiry) external;
    function intentExpiry() external view returns (uint256);

    function setMaxProtocolFee(uint64 _newMaxFee) external;

    /**
     * @notice Sets the proposal timeout duration.
     * @dev Determines how long a provider has to respond to a proposal before it expires.
     * @param _newTimeout The new timeout value in seconds.
     */
    function setProposalTimeout(uint256 _newTimeout) external;

    /**
     * @notice Updates the treasury address for collecting protocol fees.
     * @dev Only callable by admin. Must not be a zero address.
     * @param _newTreasury The new treasury address.
     */
    function setTreasuryAddress(address _newTreasury) external;

    /**
     * @notice Updates the aggregator address responsible for off-chain coordination.
     * @dev The aggregator handles proposal generation and provider selection.
     * @param _newAggregator The new aggregator contract address.
     */
    function setAggregatorAddress(address _newAggregator) external;

    /**
     * @notice Adds or removes a token from the supported tokens list.
     * @dev Enables or disables a token for use within the payment gateway.
     * @param _token The token address to update.
     * @param _supported True to add token, false to remove.
     */
    function setSupportedToken(address _token, bool _supported) external;

    // ============================
    // View Functions
    // ============================

    /**
     * @notice Checks if a token is supported by the protocol.
     * @param _token The token address to check.
     * @return bool True if the token is supported, false otherwise.
     */
    function isTokenSupported(address _token) external view returns (bool);

    /// @notice Returns the current protocol fee percentage in basis points.
    function protocolFeePercent() external view returns (uint64);

    /// @notice Returns the configured order expiry window duration in seconds.
    function orderExpiryWindow() external view returns (uint256);

    ///
    function maxProtocolFee() external view returns (uint64);

    /// @notice Returns the proposal timeout duration in seconds.
    function proposalTimeout() external view returns (uint256);

    /// @notice Returns the current treasury address.
    function treasuryAddress() external view returns (address);

    /// @notice Returns the current aggregator contract address.
    function aggregatorAddress() external view returns (address);

    /// @notice Returns the configured Alpha tier limit.
    function ALPHA_TIER_LIMIT() external view returns (uint256);

    /// @notice Returns the configured Beta tier limit.
    function BETA_TIER_LIMIT() external view returns (uint256);

    /// @notice Returns the configured Delta tier limit.
    function DELTA_TIER_LIMIT() external view returns (uint256);

    /// @notice Returns the configured Omega tier limit.
    function OMEGA_TIER_LIMIT() external view returns (uint256);

    /// @notice Returns the configured Titan tier limit.
    function TITAN_TIER_LIMIT() external view returns (uint256);

    /// @notice Returns the constant representing 100% in basis points (10,000).
    function MAX_BPS() external view returns (uint256);
}

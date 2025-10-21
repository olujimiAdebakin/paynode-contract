
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PayNode Gateway Errors Interface
 * @notice Interface for PayNode Cuatom Errors - Houses all custom errors
 * @notice Centralized error definitions for the PayNode Gateway ecosystemadmin changes
 */
interface IErrors {
      // General Errors
    error InvalidAmount();
    error InvalidAddress();
    error InvalidFee();
    error InvalidOrder();
    error InvalidProposal();
    error InvalidIntent();
    error IntentNotExpired();
    error OrderExpired();
    error Unauthorized();
    error ErrorProviderBlacklisted();
    error TokenNotSupported();
    
    // Settings Errors
    error InvalidLimits();
    error InvalidDuration();
    
    // Integrator Errors
    error AlreadyRegistered();
    error FeeOutOfRange();
    error InvalidName();
    error NotRegistered();
    
    // Order & Proposal Errors
    error OrderNotFound();
    error InvalidMessageHash();
    error MessageHashAlreadyUsed();
    error OrderNotExpired();
    error InvalidProvider();
    
    // Access Control Errors
    error UserBlacklisted();
    error NotRegisteredProvider();
}
// test/DebugInitialization.t.sol
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/gateway/PGatewaySettings.sol";
import "../src/gateway/PGatewayStructs.sol";
import "./utils/TestConstants.sol";

contract DebugInitializationTest is Test, TestConstants {
    
    function test_StepByStepDebug() public {
        console.log("=== STEP-BY-STEP INITIALIZATION DEBUG ===");
        
        address owner = address(0x1);
        address treasury = address(0x2);
        address aggregator = address(0x3);
        address integrator = address(0x4);
        
        // Log all values
        console.log("\n1. ADDRESS CHECKS:");
        console.log("Owner:", owner);
        console.log("Treasury:", treasury);
        console.log("Aggregator:", aggregator);
        console.log("Integrator:", integrator);
        
        console.log("\n2. FEE CHECKS:");
        console.log("Protocol Fee:", PROTOCOL_FEE);
        console.log("Protocol Fee <= 500 (5%):", PROTOCOL_FEE <= 500);
        console.log("Integrator Fee:", INTEGRATOR_FEE);
        console.log("Integrator Fee <= 1000 (10%):", INTEGRATOR_FEE <= 1000);
        
        console.log("\n3. TIME WINDOW CHECKS:");
        console.log("Order Expiry:", ORDER_EXPIRY);
        console.log("Order Expiry > 0:", ORDER_EXPIRY > 0);
        console.log("Proposal Timeout:", PROPOSAL_TIMEOUT);
        console.log("Proposal Timeout > 0:", PROPOSAL_TIMEOUT > 0);
        console.log("Intent Expiry:", INTENT_EXPIRY);
        console.log("Intent Expiry > 0:", INTENT_EXPIRY > 0);
        console.log("Proposal Timeout <= Order Expiry:", PROPOSAL_TIMEOUT <= ORDER_EXPIRY);
        
        console.log("\n4. TIER LIMIT CHECKS:");
        console.log("Alpha Limit:", ALPHA_LIMIT);
        console.log("Beta Limit:", BETA_LIMIT);
        console.log("Delta Limit:", DELTA_LIMIT);
        console.log("Omega Limit:", OMEGA_LIMIT);
        console.log("Titan Limit:", TITAN_LIMIT);
        console.log("Alpha > 0:", ALPHA_LIMIT > 0);
        console.log("Beta > Alpha:", BETA_LIMIT > ALPHA_LIMIT);
        console.log("Delta > Beta:", DELTA_LIMIT > BETA_LIMIT);
        console.log("Omega > Delta:", OMEGA_LIMIT > DELTA_LIMIT);
        console.log("Titan > Omega:", TITAN_LIMIT > OMEGA_LIMIT);
        
        // Create params
        PGatewayStructs.InitiateGatewaySettingsParams memory initParams = 
            PGatewayStructs.InitiateGatewaySettingsParams({
                initialOwner: owner,
                treasury: treasury,
                aggregator: aggregator,
                integrator: integrator,
                protocolFee: PROTOCOL_FEE,
                integratorFee: INTEGRATOR_FEE,
                orderExpiryWindow: ORDER_EXPIRY,
                proposalTimeout: PROPOSAL_TIMEOUT,
                intentExpiry: INTENT_EXPIRY,
                alphaLimit: ALPHA_LIMIT,
                betaLimit: BETA_LIMIT,
                deltaLimit: DELTA_LIMIT,
                omegaLimit: OMEGA_LIMIT,
                titanLimit: TITAN_LIMIT
            });
        
        console.log("\n5. DEPLOYING CONTRACT:");
        PGatewaySettings settings = new PGatewaySettings();
        console.log("Contract deployed at:", address(settings));
        
        console.log("\n6. ATTEMPTING INITIALIZATION:");
        try settings.initialize(initParams) {
            console.log("SUCCESS: Initialization completed!");
            console.log("Owner set to:", settings.owner());
        } catch Error(string memory reason) {
            console.log("FAILED with reason:", reason);
            revert(reason);
        } catch (bytes memory lowLevelData) {
            console.log("FAILED with low-level error");
            console.logBytes(lowLevelData);
            
            // Try to decode common errors
            if (lowLevelData.length >= 4) {
                bytes4 selector = bytes4(lowLevelData);
                console.log("Error selector:");
                console.logBytes4(selector);
                
                // Common error selectors
                if (selector == bytes4(keccak256("InvalidInitialization()"))) {
                    console.log("Error: InvalidInitialization - Contract already initialized or in initializing state");
                } else if (selector == bytes4(keccak256("InvalidAddress()"))) {
                    console.log("Error: InvalidAddress - One of the addresses is zero");
                } else if (selector == bytes4(keccak256("InvalidFee()"))) {
                    console.log("Error: InvalidFee - Fee exceeds maximum allowed");
                } else if (selector == bytes4(keccak256("InvalidLimits()"))) {
                    console.log("Error: InvalidLimits - Tier limits are not strictly increasing");
                } else {
                    console.log("Error: Unknown error selector");
                }
            }
            
            assembly {
                revert(add(lowLevelData, 32), mload(lowLevelData))
            }
        }
    }
    
    function test_CheckTestConstants() public view {
        console.log("=== TEST CONSTANTS VALUES ===");
        console.log("PROTOCOL_FEE:", PROTOCOL_FEE);
        console.log("INTEGRATOR_FEE:", INTEGRATOR_FEE);
        console.log("ORDER_EXPIRY:", ORDER_EXPIRY);
        console.log("PROPOSAL_TIMEOUT:", PROPOSAL_TIMEOUT);
        console.log("INTENT_EXPIRY:", INTENT_EXPIRY);
        console.log("ALPHA_LIMIT:", ALPHA_LIMIT);
        console.log("BETA_LIMIT:", BETA_LIMIT);
        console.log("DELTA_LIMIT:", DELTA_LIMIT);
        console.log("OMEGA_LIMIT:", OMEGA_LIMIT);
        console.log("TITAN_LIMIT:", TITAN_LIMIT);
        console.log("TEST_AMOUNT:", TEST_AMOUNT);
        console.log("PROVIDER_CAPACITY:", PROVIDER_CAPACITY);
        console.log("TEST_CURRENCY:", TEST_CURRENCY);
    }
}
// // test/PGatewaySettings.t.sol
// pragma solidity ^0.8.18;

// import "forge-std/Test.sol";
// import "../src/gateway/PGatewaySettings.sol";
// import "../src/gateway/PGatewayStructs.sol";
// import "./mocks/MockAccessManager.sol";
// import "./utils/TestConstants.sol";

// contract PGatewaySettingsTest is Test, TestConstants {
//     PGatewaySettings public settings;
//     MockAccessManager public accessManager;
    
// address public owner = address(0x1);
//     address public treasury = address(0x2);
//     address public aggregator = address(0x3);
//     address public integrator = address(0x4);
    
//     PGatewayStructs.InitiateGatewaySettingsParams public initParams;
    
//     function setUp() public {
//         console.log("Setting up PGatewaySettings test environment...");
        
//         initParams = PGatewayStructs.InitiateGatewaySettingsParams({
//             initialOwner: owner,
//             treasury: treasury,
//             aggregator: aggregator,
//             integrator: integrator,
//             protocolFee: PROTOCOL_FEE,
//             integratorFee: INTEGRATOR_FEE,
//             orderExpiryWindow: ORDER_EXPIRY,
//             proposalTimeout: PROPOSAL_TIMEOUT,
//             intentExpiry: INTENT_EXPIRY,
//             alphaLimit: ALPHA_LIMIT,
//             betaLimit: BETA_LIMIT,
//             deltaLimit: DELTA_LIMIT,
//             omegaLimit: OMEGA_LIMIT,
//             titanLimit: TITAN_LIMIT
//         });
        
//         settings = new PGatewaySettings();
//         settings.initialize(initParams);
        
//         console.log("PGatewaySettings test setup completed");
//     }
    
//     function test_Initialization() public view {
//         console.log("Testing PGatewaySettings initialization...");
//         assertEq(settings.owner(), owner);
//         assertEq(settings.treasuryAddress(), treasury);
//         assertEq(settings.aggregatorAddress(), aggregator);
//         assertEq(settings.protocolFeePercent(), PROTOCOL_FEE);
//         assertEq(settings.orderExpiryWindow(), ORDER_EXPIRY);
//         assertEq(settings.proposalTimeout(), PROPOSAL_TIMEOUT);

//         console.log("PGatewaySettings initialization test passed");
//     }
    
// //     function test_Initialization() public {
// //         assertEq(settings.owner(), owner);
// //         assertEq(settings.treasuryAddress(), treasury);
// //         assertEq(settings.aggregatorAddress(), aggregator);
// //         assertEq(settings.protocolFeePercent(), PROTOCOL_FEE);
// //         assertEq(settings.orderExpiryWindow(), ORDER_EXPIRY);
// //         assertEq(settings.proposalTimeout(), PROPOSAL_TIMEOUT);
// //         assertEq(settings.ALPHA_TIER_LIMIT(), ALPHA_LIMIT);
// //         assertEq(settings.BETA_TIER_LIMIT(), BETA_LIMIT);
// //     }

// // test/PGatewaySettings.t.sol - Add this function
// function test_DebugInitialization() public {
//     console.log("=== DEBUG INITIALIZATION ===");
    
//     // Check individual parameters
//     console.log("Owner: %s (zero: %s)", owner, owner == address(0));
//     console.log("Treasury: %s (zero: %s)", treasury, treasury == address(0));
//     console.log("Aggregator: %s (zero: %s)", aggregator, aggregator == address(0));
//     console.log("Integrator: %s (zero: %s)", integrator, integrator == address(0));
    
//     console.log("Protocol Fee: %s (valid: %s)", PROTOCOL_FEE, PROTOCOL_FEE <= 5000);
//     console.log("Integrator Fee: %s (valid: %s)", INTEGRATOR_FEE, INTEGRATOR_FEE <= 10000);
    
//     console.log("Order Expiry: %s (zero: %s)", ORDER_EXPIRY, ORDER_EXPIRY == 0);
//     console.log("Proposal Timeout: %s (zero: %s)", PROPOSAL_TIMEOUT, PROPOSAL_TIMEOUT == 0);
//     console.log("Intent Expiry: %s (zero: %s)", INTENT_EXPIRY, INTENT_EXPIRY == 0);
    
//     console.log("Proposal Timeout <= Order Expiry: %s", PROPOSAL_TIMEOUT <= ORDER_EXPIRY);
    
//     console.log("Alpha Limit: %s (zero: %s)", ALPHA_LIMIT, ALPHA_LIMIT == 0);
//     console.log("Beta Limit: %s (> alpha: %s)", BETA_LIMIT, BETA_LIMIT > ALPHA_LIMIT);
//     console.log("Delta Limit: %s (> beta: %s)", DELTA_LIMIT, DELTA_LIMIT > BETA_LIMIT);
//     console.log("Omega Limit: %s (> delta: %s)", OMEGA_LIMIT, OMEGA_LIMIT > DELTA_LIMIT);
//     console.log("Titan Limit: %s (> omega: %s)", TITAN_LIMIT, TITAN_LIMIT > OMEGA_LIMIT);
    
//     // Try to initialize with the same parameters
//     PGatewaySettings testSettings = new PGatewaySettings();
    
//     console.log("Attempting initialization...");
//     try testSettings.initialize(initParams) {
//         console.log("SUCCESS: Initialization worked!");
//     } catch (bytes memory reason) {
//         console.log("FAILED: Initialization reverted");
//         console.logBytes(reason);
//     }
// }

    
//     function test_Initialization_InvalidAddress() public {
//         PGatewayStructs.InitiateGatewaySettingsParams memory invalidParams = initParams;
//         invalidParams.treasury = address(0);
        
//         PGatewaySettings newSettings = new PGatewaySettings();
//         vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
//         newSettings.initialize(invalidParams);
//     }
    
//     function test_Initialization_InvalidFee() public {
//         PGatewayStructs.InitiateGatewaySettingsParams memory invalidParams = initParams;
//         invalidParams.protocolFee = 6000; // Exceeds 5%
        
//         PGatewaySettings newSettings = new PGatewaySettings();
//         vm.expectRevert(abi.encodeWithSignature("InvalidFee()"));
//         newSettings.initialize(invalidParams);
//     }
    
//     function test_Initialization_InvalidLimits() public {
//         PGatewayStructs.InitiateGatewaySettingsParams memory invalidParams = initParams;
//         invalidParams.betaLimit = invalidParams.alphaLimit; // Not strictly increasing
        
//         PGatewaySettings newSettings = new PGatewaySettings();
//         vm.expectRevert(abi.encodeWithSignature("InvalidLimits()"));
//         newSettings.initialize(invalidParams);
//     }
    
//     function test_SetProtocolFee() public {
//         vm.prank(owner);
//         settings.setProtocolFee(200); // 2%
        
//         assertEq(settings.protocolFeePercent(), 200);
//     }
    
//     function test_SetProtocolFee_OnlyOwner() public {
//         vm.prank(address(0x999));
//         vm.expectRevert("Ownable: caller is not the owner");
//         settings.setProtocolFee(200);
//     }
    
//     function test_SetProtocolFee_InvalidFee() public {
//         vm.prank(owner);
//         vm.expectRevert(abi.encodeWithSignature("InvalidFee()"));
//         settings.setProtocolFee(600); // Exceeds 5%
//     }
    
//     function test_SetTierLimits() public {
//         vm.prank(owner);
//         settings.setTierLimits(
//             ALPHA_LIMIT + 1000,
//             BETA_LIMIT + 1000, 
//             DELTA_LIMIT + 1000,
//             OMEGA_LIMIT + 1000,
//             TITAN_LIMIT + 1000
//         );
        
//         assertEq(settings.ALPHA_TIER_LIMIT(), ALPHA_LIMIT + 1000);
//     }
    
//     function test_SetTierLimits_Invalid() public {
//         vm.prank(owner);
//         vm.expectRevert(abi.encodeWithSignature("InvalidLimits()"));
//         settings.setTierLimits(
//             ALPHA_LIMIT,
//             ALPHA_LIMIT, // Same as alpha - invalid
//             DELTA_LIMIT,
//             OMEGA_LIMIT,
//             TITAN_LIMIT
//         );
//     }
    
//     function test_SetSupportedToken() public {
//         address token = address(0x123);
        
//         vm.prank(owner);
//         settings.setSupportedToken(token, true);
        
//         assertTrue(settings.isTokenSupported(token));
//     }
    
//     function test_RevertWhen_NonOwnerSetsToken() public {
//         address token = address(0x123);
        
//         vm.prank(address(0x999));
//         vm.expectRevert("Ownable: caller is not the owner");
//         settings.setSupportedToken(token, true);
//     }
// }


pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/gateway/PGatewaySettings.sol";
import "../src/gateway/PGatewayStructs.sol";
import "./mocks/MockAccessManager.sol";
import "./utils/TestConstants.sol";

contract PGatewaySettingsTest is Test, TestConstants {
    PGatewaySettings public settings;
    MockAccessManager public accessManager;
    
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public aggregator = address(0x3);
    address public integrator = address(0x4);
    
    PGatewayStructs.InitiateGatewaySettingsParams public initParams;
    
    function setUp() public {
        console.log("Setting up PGatewaySettings test environment...");
        
        // Create the params struct
        initParams = PGatewayStructs.InitiateGatewaySettingsParams({
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
        
        // Deploy a fresh contract for each test
        settings = new PGatewaySettings();
        console.log("PGatewaySettings deployed at:", address(settings));
        
        // Initialize the contract
        settings.initialize(initParams);
        console.log("PGatewaySettings initialized with owner:", settings.owner());
        
        console.log("PGatewaySettings test setup completed");
    }
    
    function test_Initialization() public view {
        console.log("Testing PGatewaySettings initialization...");
        assertEq(settings.owner(), owner);
        assertEq(settings.treasuryAddress(), treasury);
        assertEq(settings.aggregatorAddress(), aggregator);
        assertEq(settings.protocolFeePercent(), PROTOCOL_FEE);
        assertEq(settings.orderExpiryWindow(), ORDER_EXPIRY);
        assertEq(settings.proposalTimeout(), PROPOSAL_TIMEOUT);
        console.log("PGatewaySettings initialization test passed");
    }
    
    function test_Initialization_InvalidAddress() public {
        PGatewayStructs.InitiateGatewaySettingsParams memory invalidParams = initParams;
        invalidParams.treasury = address(0);
        
        PGatewaySettings newSettings = new PGatewaySettings();
        vm.expectRevert(abi.encodeWithSignature("InvalidAddress()"));
        newSettings.initialize(invalidParams);
    }
    
    function test_Initialization_InvalidFee() public {
        PGatewayStructs.InitiateGatewaySettingsParams memory invalidParams = initParams;
        invalidParams.protocolFee = 6000; // Exceeds 50% (5000 bps)
        
        PGatewaySettings newSettings = new PGatewaySettings();
        vm.expectRevert(abi.encodeWithSignature("InvalidFee()"));
        newSettings.initialize(invalidParams);
    }
    
    function test_Initialization_InvalidLimits() public {
        PGatewayStructs.InitiateGatewaySettingsParams memory invalidParams = initParams;
        invalidParams.betaLimit = invalidParams.alphaLimit; // Not strictly increasing
        
        PGatewaySettings newSettings = new PGatewaySettings();
        vm.expectRevert(abi.encodeWithSignature("InvalidLimits()"));
        newSettings.initialize(invalidParams);
    }
    
    function test_Initialization_InvalidTimeWindows() public {
        PGatewayStructs.InitiateGatewaySettingsParams memory invalidParams = initParams;
        invalidParams.proposalTimeout = invalidParams.orderExpiryWindow + 1; // Proposal timeout > order expiry
        
        PGatewaySettings newSettings = new PGatewaySettings();
        vm.expectRevert(); // Should revert with appropriate error
        newSettings.initialize(invalidParams);
    }
    
    function test_SetProtocolFee() public {
        vm.prank(owner);
        settings.setProtocolFee(200); // 2%
        
        assertEq(settings.protocolFeePercent(), 200);
    }
    
    function test_SetProtocolFee_OnlyOwner() public {
         address unauthorizedUser = address(0x999);
          vm.prank(unauthorizedUser);
          vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", unauthorizedUser));
        settings.setProtocolFee(200);
    }
    
    function test_SetProtocolFee_InvalidFee() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("InvalidFee()"));
        settings.setProtocolFee(6000); // Exceeds max
    }
    
    function test_SetTierLimits() public {
        vm.prank(owner);
        settings.setTierLimits(
            ALPHA_LIMIT + 1000 ether,
            BETA_LIMIT + 1000 ether, 
            DELTA_LIMIT + 1000 ether,
            OMEGA_LIMIT + 1000 ether,
            TITAN_LIMIT + 1000 ether
        );
        
        assertEq(settings.ALPHA_TIER_LIMIT(), ALPHA_LIMIT + 1000 ether);
        assertEq(settings.BETA_TIER_LIMIT(), BETA_LIMIT + 1000 ether);
    }
    
    function test_SetTierLimits_Invalid() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSignature("InvalidLimits()"));
        settings.setTierLimits(
            ALPHA_LIMIT,
            ALPHA_LIMIT, // Same as alpha - invalid
            DELTA_LIMIT,
            OMEGA_LIMIT,
            TITAN_LIMIT
        );
    }
    
    function test_SetSupportedToken() public {
        address token = address(0x123);
        
        vm.prank(owner);
        settings.setSupportedToken(token, true);
        
        assertTrue(settings.isTokenSupported(token));
    }
    
    function test_RemoveSupportedToken() public {
        address token = address(0x123);
        
        // Add token
        vm.prank(owner);
        settings.setSupportedToken(token, true);
        assertTrue(settings.isTokenSupported(token));
        
        // Remove token
        vm.prank(owner);
        settings.setSupportedToken(token, false);
        assertFalse(settings.isTokenSupported(token));
    }
    
     function test_RevertWhen_NonOwnerSetsToken() public {
        address token = address(0x123);
        address unauthorizedUser = address(0x999);
        
        vm.prank(unauthorizedUser);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", unauthorizedUser));
        settings.setSupportedToken(token, true);
    }
    
    function test_CannotReinitialize() public {
        vm.expectRevert(); // Should revert with InvalidInitialization
        settings.initialize(initParams);
    }
}
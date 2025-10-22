// test/PGateway.t.sol
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/gateway/PGateway.sol";
import "../src/gateway/PGatewaySettings.sol";
import "../src/gateway/PGatewayStructs.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockAccessManager.sol";
import "./utils/TestConstants.sol";

contract PGatewayTest is Test, TestConstants {
    PGateway public gateway;
    PGatewaySettings public settings;
    MockAccessManager public accessManager;
    MockERC20 public testToken;
    
    // Test Accounts
    address public owner = address(0x1);
    address public treasury = address(0x2);
    address public aggregator = address(0x3);
    address public integrator = address(0x4);
    address public user = address(0x5);
    address public provider = address(0x6);
    address public randomUser = address(0x7);
    
    PGatewayStructs.InitiateGatewaySettingsParams public settingsParams;
    
    function setUp() public {
        console.log("Setting up test environment...");
        
        // Setup accounts with ETH
        vm.deal(owner, 100 ether);
        vm.deal(user, 100 ether);
        vm.deal(provider, 100 ether);
        
        // Deploy MockAccessManager with owner as superAdmin
        // This automatically grants owner the DEFAULT_ADMIN_ROLE
        accessManager = new MockAccessManager(owner);
        console.log("AccessManager deployed, owner has DEFAULT_ADMIN_ROLE");
        
        // Deploy test token
        testToken = new MockERC20("Test Token", "TEST");
        console.log("Test token deployed");
        
        // Create settings params
        settingsParams = PGatewayStructs.InitiateGatewaySettingsParams({
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
        
        // Deploy and initialize settings
        settings = new PGatewaySettings();
        settings.initialize(settingsParams);
        console.log("PGatewaySettings initialized");
        
        // Deploy and initialize gateway
        gateway = new PGateway();
        gateway.initialize(address(accessManager), address(settings));
        console.log("PGateway initialized");
        
        // Grant roles as owner (who has DEFAULT_ADMIN_ROLE from constructor)
        vm.startPrank(owner);
        console.log("Granting AGGREGATOR_ROLE to:", aggregator);
        accessManager.grantRole(accessManager.AGGREGATOR_ROLE(), aggregator);
        console.log("Granting PROVIDER_ROLE to:", provider);
        accessManager.grantRole(accessManager.PROVIDER_ROLE(), provider);
        
        // Setup supported token
        console.log("Setting supported token");
        settings.setSupportedToken(address(testToken), true);
        vm.stopPrank();
        
        // Mint tokens to user
        testToken.mint(user, TEST_AMOUNT * 10);
        console.log("Minted tokens to user");
        
        // Register integrator
        console.log("Registering integrator");
        vm.prank(integrator);
        gateway.registerAsIntegrator(INTEGRATOR_FEE, "TestIntegrator");
        
        console.log("Test setup completed successfully");
    }
    
    function test_Initialization() public {
        console.log("Testing contract initialization...");
        assertEq(address(gateway.accessManager()), address(accessManager));
        assertEq(address(gateway.settings()), address(settings));
        
        // Verify roles are properly set
        console.log("Verifying roles:");
        console.log("- Provider has PROVIDER_ROLE:", accessManager.hasRole(accessManager.PROVIDER_ROLE(), provider));
        console.log("- Aggregator has AGGREGATOR_ROLE:", accessManager.hasRole(accessManager.AGGREGATOR_ROLE(), aggregator));
        console.log("- Owner has DEFAULT_ADMIN_ROLE:", accessManager.hasRole(accessManager.DEFAULT_ADMIN_ROLE(), owner));
        
        assertTrue(accessManager.hasRole(accessManager.PROVIDER_ROLE(), provider), "Provider should have role");
        assertTrue(accessManager.hasRole(accessManager.AGGREGATOR_ROLE(), aggregator), "Aggregator should have role");
        
        console.log("Contract initialization test passed");
    }
    
    function test_IntegratorRegistration() public {
        console.log("Testing integrator registration...");
        
        address newIntegrator = address(0x99);
        uint64 fee = 150; // 1.5%
        string memory name = "NewIntegrator";
        
        vm.prank(newIntegrator);
        gateway.registerAsIntegrator(fee, name);
        
        PGatewayStructs.IntegratorInfo memory info = gateway.getIntegratorInfo(newIntegrator);
        assertTrue(info.isRegistered);
        assertEq(info.feeBps, fee);
        assertEq(info.name, name);
        
        console.log("Integrator registration test passed");
    }
    
    function test_IntegratorRegistration_InvalidFee() public {
        console.log("Testing integrator registration with invalid fee...");
        
        address newIntegrator = address(0x99);
        
        vm.prank(newIntegrator);
        vm.expectRevert(abi.encodeWithSignature("FeeOutOfRange()"));
        gateway.registerAsIntegrator(600, "NewIntegrator"); // Exceeds max
        
        console.log("Invalid fee rejection test passed");
    }
    
    function test_ProviderIntentRegistration() public {
        console.log("Testing provider intent registration...");
        
        vm.prank(provider);
        gateway.registerIntent(
            TEST_CURRENCY,
            PROVIDER_CAPACITY,
            50,  // min fee 0.5%
            200, // max fee 2%
            1 hours
        );
        
        PGatewayStructs.ProviderIntent memory intent = gateway.getProviderIntent(provider);
        assertTrue(intent.isActive);
        assertEq(intent.availableAmount, PROVIDER_CAPACITY);
        assertEq(intent.currency, TEST_CURRENCY);
        
        console.log("Provider intent registration test passed");
    }
    
    function test_CreateOrder() public {
        console.log("Testing order creation...");
        
        // Setup
        vm.prank(provider);
        gateway.registerIntent(TEST_CURRENCY, PROVIDER_CAPACITY, 50, 200, 1 hours);
        
        // Prepare order
        uint256 amount = TEST_AMOUNT;
        console.log("Order amount: %s tokens", amount / 1e18);
        
        vm.prank(user);
        testToken.approve(address(gateway), amount);
        
        // Create order
        vm.prank(user);
        bytes32 orderId = gateway.createOrder(
            address(testToken),
            amount,
            user,
            integrator,
            INTEGRATOR_FEE,
            keccak256("test-order")
        );
        
        console.log("Order created");
        
        // Verify order status
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.PENDING);

        PGatewayStructs.Order memory order = gateway.getOrder(orderId);
        assertEq(order.user, user);
        
        console.log("Order creation test passed");
    }
    
    function test_CreateOrder_InvalidToken() public {
        console.log("Testing order creation with invalid token...");
        
        address invalidToken = address(0x999);
        bytes32 messageHash = keccak256("test-order");
        
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSignature("TokenNotSupported()"));
        gateway.createOrder(
            invalidToken,
            TEST_AMOUNT,
            user,
            integrator,
            INTEGRATOR_FEE,
            messageHash
        );
        
        console.log("Invalid token rejection test passed");
    }
    
    function test_CreateProposal() public {
        console.log("Testing proposal creation...");
        
        // Setup provider intent
        vm.prank(provider);
        gateway.registerIntent(TEST_CURRENCY, PROVIDER_CAPACITY, 50, 200, 1 hours);
        
        // Create order
        bytes32 messageHash = keccak256("test-order");
        vm.prank(user);
        testToken.approve(address(gateway), TEST_AMOUNT);
        vm.prank(user);
        bytes32 orderId = gateway.createOrder(
            address(testToken),
            TEST_AMOUNT,
            user,
            integrator,
            INTEGRATOR_FEE,
            messageHash
        );
        
        // Create proposal
        vm.prank(aggregator);
        bytes32 proposalId = gateway.createProposal(orderId, provider, 100); // 1% fee
        
        console.log("Proposal created");
        
        // Verify proposal and order status
        _assertProposalStatus(proposalId, PGatewayStructs.ProposalStatus.PENDING);
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.PROPOSED);
        
        // Verify proposal details
        PGatewayStructs.SettlementProposal memory proposal = gateway.getProposal(proposalId);
        assertEq(proposal.orderId, orderId);
        assertEq(proposal.provider, provider);
        
        console.log("Proposal creation test passed");
    }
    
    function test_AcceptProposal() public {
        console.log("Testing proposal acceptance...");
        
        // Setup complete flow up to proposal creation
        bytes32 orderId = _setupOrderAndProposal();
        bytes32 proposalId = _getFirstProposalId(orderId);
        
        // Provider accepts proposal
        vm.prank(provider);
        gateway.acceptProposal(proposalId);
        
        // Verify acceptance
        _assertProposalStatus(proposalId, PGatewayStructs.ProposalStatus.ACCEPTED);
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.ACCEPTED);
        
        // Verify order details
        PGatewayStructs.Order memory order = gateway.getOrder(orderId);
        assertEq(order.acceptedProposalId, proposalId);
        assertEq(order.fulfilledByProvider, provider);
        
        console.log("Proposal acceptance test passed");
    }
    
    function test_ExecuteSettlement() public {
        console.log("Testing settlement execution...");
        
        // Setup complete flow up to proposal acceptance
        bytes32 orderId = _setupOrderAndProposal();
        bytes32 proposalId = _getFirstProposalId(orderId);
        
        vm.prank(provider);
        gateway.acceptProposal(proposalId);
        
        // Execute settlement
        uint256 initialTreasuryBalance = testToken.balanceOf(treasury);
        uint256 initialIntegratorBalance = testToken.balanceOf(integrator);
        uint256 initialProviderBalance = testToken.balanceOf(provider);
        
        vm.prank(aggregator);
        gateway.executeSettlement(proposalId);
        
        // Verify fund distribution
        uint256 protocolFee = (TEST_AMOUNT * PROTOCOL_FEE) / settings.MAX_BPS();
        uint256 integratorFee = (TEST_AMOUNT * INTEGRATOR_FEE) / settings.MAX_BPS();
        uint256 providerAmount = TEST_AMOUNT - protocolFee - integratorFee;
        
        assertEq(testToken.balanceOf(treasury), initialTreasuryBalance + protocolFee);
        assertEq(testToken.balanceOf(integrator), initialIntegratorBalance + integratorFee);
        assertEq(testToken.balanceOf(provider), initialProviderBalance + providerAmount);
        
        // Verify state updates
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.FULFILLED);
        assertTrue(gateway.proposalExecuted(proposalId));
        
        console.log("Settlement execution test passed");
    }
    
    function test_RefundOrder() public {
        console.log("Testing order refund by aggregator...");
        
        // Create order but don't create proposal
        bytes32 messageHash = keccak256("test-order");
        vm.prank(user);
        testToken.approve(address(gateway), TEST_AMOUNT);
        vm.prank(user);
        bytes32 orderId = gateway.createOrder(
            address(testToken),
            TEST_AMOUNT,
            user,
            integrator,
            INTEGRATOR_FEE,
            messageHash
        );
        
        // Fast forward past expiry
        vm.warp(block.timestamp + ORDER_EXPIRY + 1);
        
        // Refund order
        uint256 initialUserBalance = testToken.balanceOf(user);
        vm.prank(aggregator);
        gateway.refundOrder(orderId);
        
        // Verify refund
        assertEq(testToken.balanceOf(user), initialUserBalance + TEST_AMOUNT);
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.REFUNDED);
        
        console.log("Order refund test passed");
    }
    
    function test_UserRequestRefund() public {
        console.log("Testing user-requested refund...");
        
        // Create order
        bytes32 messageHash = keccak256("test-order");
        vm.prank(user);
        testToken.approve(address(gateway), TEST_AMOUNT);
        vm.prank(user);
        bytes32 orderId = gateway.createOrder(
            address(testToken),
            TEST_AMOUNT,
            user,
            integrator,
            INTEGRATOR_FEE,
            messageHash
        );
        
        // Fast forward past expiry
        vm.warp(block.timestamp + ORDER_EXPIRY + 1);
        
        // User requests refund
        uint256 initialUserBalance = testToken.balanceOf(user);
        vm.prank(user);
        gateway.requestRefund(orderId);
        
        // Verify refund
        assertEq(testToken.balanceOf(user), initialUserBalance + TEST_AMOUNT);
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.CANCELLED);
        
        console.log("User-requested refund test passed");
    }
    
    function test_BlacklistProvider() public {
        console.log("Testing provider blacklisting...");
        
        // Register provider
        vm.prank(provider);
        gateway.registerIntent(TEST_CURRENCY, PROVIDER_CAPACITY, 50, 200, 1 hours);
        
        // Blacklist provider
        vm.prank(owner);
        gateway.blacklistProvider(provider, "Test blacklist");
        
        // Verify blacklist
        PGatewayStructs.ProviderReputation memory rep = gateway.getProviderReputation(provider);
        assertTrue(rep.isBlacklisted);
        
        // Verify intent deactivated
        PGatewayStructs.ProviderIntent memory intent = gateway.getProviderIntent(provider);
        assertFalse(intent.isActive);
        
        console.log("Provider blacklisting test passed");
    }
    
    function test_CompleteOrderFlow() public {
        console.log("Testing complete order flow...");
        
        // 1. Provider Registration
        console.log("Step 1: Provider registration");
        vm.prank(provider);
        gateway.registerIntent(TEST_CURRENCY, PROVIDER_CAPACITY, 50, 200, 1 hours);
        
        // 2. Order Creation
        console.log("Step 2: Order creation");
        vm.prank(user);
        testToken.approve(address(gateway), TEST_AMOUNT);
        
        vm.prank(user);
        bytes32 orderId = gateway.createOrder(
            address(testToken),
            TEST_AMOUNT,
            user,
            integrator,
            INTEGRATOR_FEE,
            keccak256("test-order")
        );
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.PENDING);
        
        // 3. Proposal Creation
        console.log("Step 3: Proposal creation");
        vm.prank(aggregator);
        bytes32 proposalId = gateway.createProposal(orderId, provider, 100);
        _assertProposalStatus(proposalId, PGatewayStructs.ProposalStatus.PENDING);
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.PROPOSED);
        
        // 4. Proposal Acceptance
        console.log("Step 4: Proposal acceptance");
        vm.prank(provider);
        gateway.acceptProposal(proposalId);
        _assertProposalStatus(proposalId, PGatewayStructs.ProposalStatus.ACCEPTED);
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.ACCEPTED);
        
        // 5. Settlement Execution
        console.log("Step 5: Settlement execution");
        vm.prank(aggregator);
        gateway.executeSettlement(proposalId);
        _assertOrderStatus(orderId, PGatewayStructs.OrderStatus.FULFILLED);
        
        console.log("Complete order flow test passed");
    }
    
    // Helper Functions
    function _setupOrderAndProposal() internal returns (bytes32 orderId) {
        // Setup provider
        vm.prank(provider);
        gateway.registerIntent(TEST_CURRENCY, PROVIDER_CAPACITY, 50, 200, 1 hours);
        
        // Create order
        bytes32 messageHash = keccak256("test-order");
        vm.prank(user);
        testToken.approve(address(gateway), TEST_AMOUNT);
        vm.prank(user);
        orderId = gateway.createOrder(
            address(testToken),
            TEST_AMOUNT,
            user,
            integrator,
            INTEGRATOR_FEE,
            messageHash
        );
        
        // Create proposal
        vm.prank(aggregator);
        gateway.createProposal(orderId, provider, 100);
        
        return orderId;
    }
    
    function _getFirstProposalId(bytes32 orderId) internal view returns (bytes32) {
        return keccak256(abi.encode(orderId, provider, block.timestamp, block.number));
    }

    function _assertOrderStatus(bytes32 orderId, PGatewayStructs.OrderStatus expectedStatus) internal view {
        PGatewayStructs.Order memory order = gateway.getOrder(orderId);
        assertEq(uint256(order.status), uint256(expectedStatus), "Order status mismatch");
    }

    function _assertProposalStatus(bytes32 proposalId, PGatewayStructs.ProposalStatus expectedStatus) internal view {
        PGatewayStructs.SettlementProposal memory proposal = gateway.getProposal(proposalId);
        assertEq(uint256(proposal.status), uint256(expectedStatus), "Proposal status mismatch");
    }
}
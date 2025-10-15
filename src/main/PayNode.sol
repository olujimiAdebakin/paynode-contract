// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./access/AccessManager.sol";
import "./access/TimelockAdmin.sol";
import "./gateway/PGateway.sol";
import "./gateway/PGatewaySettings.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract PayNode {
    AccessManager public accessManager;
    TimelockAdmin public timelockAdmin;
    PGatewaySettings public gatewaySettings;
    PGateway public gatewayProxy;

    address public owner;
    bool public deployed;

    event PayNodeDeployed(address indexed admin, address gatewayProxy, address timelockAdmin, address settings);

    constructor() {
        owner = msg.sender;
    }

    function deploySystem(address _admin, address _aggregator, address _treasury) external {
        require(msg.sender == owner, "Only owner");
        require(!deployed, "Already deployed");

        // 1️⃣ Deploy AccessManager
        accessManager = new AccessManager(_admin);

        // 2️⃣ Deploy TimelockAdmin
        timelockAdmin = new TimelockAdmin(address(accessManager), 2 days);

        // 3️⃣ Deploy GatewaySettings
        gatewaySettings = new PGatewaySettings(_aggregator, _treasury, address(accessManager));

        // 4️⃣ Deploy Gateway Implementation
        PGateway gatewayImpl = new PGateway(address(gatewaySettings));

        // 5️⃣ Deploy Proxy for Gateway
        gatewayProxy = PGateway(
            address(new ERC1967Proxy(address(gatewayImpl), abi.encodeWithSelector(PGateway.initialize.selector)))
        );

        // 6️⃣ Transfer ownership to Timelock
        accessManager.transferOwnership(address(timelockAdmin));
        gatewaySettings.transferOwnership(address(timelockAdmin));

        deployed = true;

        emit PayNodeDeployed(_admin, address(gatewayProxy), address(timelockAdmin), address(gatewaySettings));
    }
}

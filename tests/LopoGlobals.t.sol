// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { MockLopoGlobalsV2 } from "./mocks/MockLopoGlobalsV2.sol";
import "./BaseTest.t.sol";

contract LopoGlobalsTest is BaseTest {
    MockLopoGlobalsV2 globalsV2;
    MockLopoGlobalsV2 wrappedLopoProxyV2;

    address GOVERNORV2;

    function setUp() public override {
        super.setUp();

        GOVERNORV2 = ACCOUNTS[3];

        vm.prank(DEFAULT_GOVERNOR);
        wrappedLopoProxyV1.setValidBuyer(DEFAULT_BUYER, true);
    }

    function test_canUpgrade() public {
        globalsV2 = new MockLopoGlobalsV2();

        /**
         * only the governor can call upgradeTo()
         * upgradeTo() has a onlyProxy mpdifier, and calls _authorizeUpgrade()
         * _authorizeUpgrade() has a onlyGovernor modifier, which implements in LopoGlobals
         */

        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.upgradeTo(address(globalsV2));

        // re-wrap the proxy to the new implementation
        wrappedLopoProxyV2 = MockLopoGlobalsV2(address(LopoProxy));

        console.log("-> GOVERNORV1: %s", wrappedLopoProxyV1.governor());
        console.log("-> GovernorV2 before initialize: %s", wrappedLopoProxyV2.governor());
        assertEq(wrappedLopoProxyV2.governor(), DEFAULT_GOVERNOR);

        wrappedLopoProxyV2.initialize(GOVERNORV2);

        console.log("-> GovernorV2 after initialize: %s", wrappedLopoProxyV2.governor());
        assertEq(wrappedLopoProxyV2.governor(), GOVERNORV2);

        console.log("-> wrappedLopoProxyV1.isBuyer(DEFAULT_BUYER): %s", wrappedLopoProxyV1.isBuyer(DEFAULT_BUYER));
        console.log("-> wrappedLopoProxyV2.isBuyer(DEFAULT_BUYER): %s", wrappedLopoProxyV2.isBuyer(DEFAULT_BUYER));
        assertTrue(wrappedLopoProxyV2.isBuyer(DEFAULT_BUYER));

        console.log("-> wrappedLopoProxyV1.isBuyer(DEFAULT_SELLER): %s", wrappedLopoProxyV1.isBuyer(DEFAULT_SELLER));
        vm.prank(GOVERNORV2);
        wrappedLopoProxyV2.setValidBuyer(DEFAULT_SELLER, true);
        console.log("-> wrappedLopoProxyV1.isBuyer(DEFAULT_SELLER): %s", wrappedLopoProxyV1.isBuyer(DEFAULT_SELLER));
        console.log("-> wrappedLopoProxyV2.isBuyer(DEFAULT_SELLER): %s", wrappedLopoProxyV2.isBuyer(DEFAULT_SELLER));

        // new function in V2
        string memory text = wrappedLopoProxyV2.upgradeV2Test();
        console.log("-> text: %s", text);
        assertEq(text, "Hello World V2");
    }
}

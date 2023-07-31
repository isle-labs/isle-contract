// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { MockLopoGlobalsV2 } from "./mocks/MockLopoGlobalsV2.sol";
import "./BaseTest.t.sol";

contract LopoGlobalsTest is BaseTest {
    MockLopoGlobalsV2 globalsV2;
    MockLopoGlobalsV2 wrappedProxyV2;

    address GOVERNORV2;

    function setUp() public override {
        super.setUp();

        GOVERNORV2 = ACCOUNTS[3];

        vm.prank(DEFAULT_GOVERNOR);
        wrappedProxyV1.setValidBuyer(DEFAULT_BUYER, true);
    }

    function test_canUpgrade() public {
        globalsV2 = new MockLopoGlobalsV2();

        /**
         * only the governor can call upgradeTo()
         * upgradeTo() has a onlyProxy mpdifier, and calls _authorizeUpgrade()
         * _authorizeUpgrade() has a onlyGovernor modifier, which implements in LopoGlobals
         */

        vm.prank(GOVERNOR);
        wrappedProxyV1.upgradeTo(address(globalsV2));

        // re-wrap the proxy to the new implementation
        wrappedProxyV2 = MockLopoGlobalsV2(address(proxy));

        console.log("-> GOVERNORV1: %s", wrappedProxyV1.governor());
        console.log("-> GovernorV2 before initialize: %s", wrappedProxyV2.governor());
        assertEq(wrappedProxyV2.governor(), DEFAULT_GOVERNOR);

        wrappedProxyV2.initialize(GOVERNORV2);

        console.log("-> GovernorV2 after initialize: %s", wrappedProxyV2.governor());
        assertEq(wrappedProxyV2.governor(), GOVERNORV2);

        console.log("-> wrappedProxyV1.isBuyer(DEFAULT_BUYER): %s", wrappedProxyV1.isBuyer(DEFAULT_BUYER));
        console.log("-> wrappedProxyV2.isBuyer(DEFAULT_BUYER): %s", wrappedProxyV2.isBuyer(DEFAULT_BUYER));
        assertTrue(wrappedProxyV2.isBuyer(DEFAULT_BUYER));

        // due to the state is stored in the proxy, so we set the state in V1, and can get it in V2
        // at the same time, we can also set the state in V2, and get it in V1
        console.log("-> wrappedProxyV1.isBuyer(DEFAULT_SELLER): %s", wrappedProxyV1.isBuyer(DEFAULT_SELLER));
        vm.prank(GOVERNORV2);
        wrappedProxyV2.setValidBuyer(DEFAULT_SELLER, true);
        console.log("-> wrappedProxyV1.isBuyer(DEFAULT_SELLER): %s", wrappedProxyV1.isBuyer(DEFAULT_SELLER));
        console.log("-> wrappedProxyV2.isBuyer(DEFAULT_SELLER): %s", wrappedProxyV2.isBuyer(DEFAULT_SELLER));

        // new function in V2
        string memory text = wrappedProxyV2.upgradeV2Test();
        console.log("-> text: %s", text);
        assertEq(text, "Hello World V2");
    }
}

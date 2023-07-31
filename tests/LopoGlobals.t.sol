// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "../contracts/libraries/Errors.sol";
import { MockLopoGlobalsV2 } from "./mocks/MockLopoGlobalsV2.sol";
import "./BaseTest.t.sol";

contract LopoGlobalsTest is BaseTest {
    MockLopoGlobalsV2 globalsV2;
    MockLopoGlobalsV2 wrappedLopoProxyV2;

    event GovernorshipAccepted(address indexed previousGovernor_, address indexed currentGovernor_);
    event PendingGovernorSet(address indexed pendingGovernor_);

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

        assertEq(wrappedLopoProxyV2.governor(), DEFAULT_GOVERNOR);

        wrappedLopoProxyV2.initialize(GOVERNORV2);

        assertEq(wrappedLopoProxyV2.governor(), GOVERNORV2);

        assertTrue(wrappedLopoProxyV2.isBuyer(DEFAULT_BUYER));

        vm.prank(GOVERNORV2);
        wrappedLopoProxyV2.setValidBuyer(DEFAULT_SELLER, true);

        // new function in V2
        string memory text = wrappedLopoProxyV2.upgradeV2Test();
        assertEq(text, "Hello World V2");
    }

    function test_setPendingLopoGovernor_and_acceptLopoGovernor() public {
        vm.expectEmit(true, true, true, true);
        emit PendingGovernorSet(GOVERNORV2);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setPendingLopoGovernor(GOVERNORV2);

        assertEq(wrappedLopoProxyV1.pendingLopoGovernor(), GOVERNORV2);

        vm.expectEmit(true, true, true, true);
        emit GovernorshipAccepted(GOVERNOR, GOVERNORV2);
        vm.prank(GOVERNORV2);
        wrappedLopoProxyV1.acceptLopoGovernor();
        assertEq(wrappedLopoProxyV1.governor(), GOVERNORV2);
    }

    function test_Revert_IfZeroAddress_setLopoVault() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_InvalidVault.selector, address(0)));
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setLopoVault(address(0));
    }
}

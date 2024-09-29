// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Governable_Test } from "../../../shared/governable/Governable.t.sol";

contract CancelPendingGovenor_Governable_Unit_Concrete_Test is Governable_Test {
    function setUp() public virtual override(Governable_Test) {
        Governable_Test.setUp();

        changePrank(users.governor);
        mockGovernable.nominateGovernor(users.eve);
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        mockGovernable.cancelPendingGovenor();
    }

    function test_CancelPendingGovernor() external whenCallerGovernor {
        vm.expectEmit(true, false, false, false);
        emit CancelPendingGovernor(users.eve);

        mockGovernable.cancelPendingGovenor();
        assertEq(mockGovernable.governor(), users.governor);
        assertEq(mockGovernable.pendingGovernor(), address(0));
    }
}

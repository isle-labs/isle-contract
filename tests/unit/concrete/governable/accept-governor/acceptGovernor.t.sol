// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Governable_Test } from "../../../shared/governable/Governable.t.sol";

contract AcceptGovernor_Governable_Unit_Concrete_Test is Governable_Test {
    function setUp() public virtual override(Governable_Test) {
        Governable_Test.setUp();

        changePrank(users.governor);
        mockGovernable.nominateGovernor(users.eve);
    }

    function test_RevertWhen_CallerNotPendingGovenor() external {
        changePrank(users.governor);
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_CallerNotPendingGovernor.selector, users.eve));
        mockGovernable.acceptGovernor();
    }

    function test_AcceptGovenor() external whenCallerIsPendingGovernor {
        vm.expectEmit(true, true, false, false);
        emit AcceptGovernor(users.governor, users.eve);
        mockGovernable.acceptGovernor();
    }

    modifier whenCallerIsPendingGovernor() {
        changePrank(users.eve);
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Governable_Test } from "../../../shared/governable/Governable.t.sol";

contract NominateGovernor_Governable_Unit_Concrete_Test is Governable_Test {
    function setUp() public virtual override(Governable_Test) {
        Governable_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        mockGovernable.nominateGovernor(users.eve);
    }

    function test_RevertWhen_NewGovernorIsZeroAddress() external whenCallerGovernor {
        vm.expectRevert(Errors.GovernorZeroAddress.selector);
        mockGovernable.nominateGovernor(address(0));
    }

    function test_TransferGovernor() external whenGovernorNotZeroAddress whenCallerGovernor {
        vm.expectEmit(true, true, false, false);
        emit NominateGovernor(users.governor, users.eve);

        mockGovernable.nominateGovernor(users.eve);
        assertEq(mockGovernable.pendingGovernor(), users.eve);
    }

    modifier whenGovernorNotZeroAddress() {
        _;
    }
}

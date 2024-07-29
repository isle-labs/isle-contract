// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Governable_Test } from "../../../shared/governable/Governable.t.sol";

contract TransferGovernor_Governable_Unit_Concrete_Test is Governable_Test {
    function setUp() public virtual override(Governable_Test) {
        Governable_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        mockGovernable.transferGovernor(users.eve);
    }

    function test_TransferGovernor() external whenCallerGovernor {
        vm.expectEmit(true, true, false, false);
        emit TransferGovernor(users.governor, users.eve);

        mockGovernable.transferGovernor(users.eve);
        assertEq(mockGovernable.governor(), users.eve);
    }
}

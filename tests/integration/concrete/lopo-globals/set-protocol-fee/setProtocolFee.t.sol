// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LopoGlobals_Integration_Concrete_Test } from "../LopoGlobals.t.sol";
import { Callable_Integration_Shared_Test } from "tests/integration/shared/lopo-globals/callable.t.sol";

contract SetProtocolFee_Integration_Concrete_Test is
    LopoGlobals_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LopoGlobals_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LopoGlobals_Integration_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        uint24 protocolFee = defaults.PROTOCOL_FEE_RATE();
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_CallerNotGovernor.selector, users.governor, users.eve));
        lopoGlobals.setProtocolFee(protocolFee);
    }

    function test_SetProtocolFee() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit ProtocolFeeSet(defaults.PROTOCOL_FEE_RATE());
        lopoGlobals.setProtocolFee(defaults.PROTOCOL_FEE_RATE());
    }
}

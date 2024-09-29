// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Unit_Concrete_Test } from "../IsleGlobals.t.sol";

contract SetProtocolFee_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        uint24 protocolFee = defaults.PROTOCOL_FEE_RATE();
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        isleGlobals.setProtocolFee(protocolFee);
    }

    function test_SetProtocolFee() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit ProtocolFeeSet(defaults.PROTOCOL_FEE_RATE());
        isleGlobals.setProtocolFee(defaults.PROTOCOL_FEE_RATE());
    }
}

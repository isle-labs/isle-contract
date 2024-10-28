// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Receivable_Unit_Shared_Test } from "../../../shared/receivable/Receivable.t.sol";

import { IReceivable } from "contracts/interfaces/IReceivable.sol";

import { Receivable } from "contracts/Receivable.sol";
import { UUPSProxy } from "contracts/libraries/upgradability/UUPSProxy.sol";
import { Errors } from "contracts/libraries/Errors.sol";

contract Initialize_Receivable_Unit_Concrete_Test is Receivable_Unit_Shared_Test {
    function setUp() public virtual override(Receivable_Unit_Shared_Test) {
        Receivable_Unit_Shared_Test.setUp();
    }

    function test_Initialize_RevertWhen_IsleGlobalZeroAddress() public {
        IReceivable receivable_ = Receivable(address(new UUPSProxy(address(new Receivable()), "")));

        vm.expectRevert(abi.encodeWithSelector(Errors.ZeroAddress.selector));
        receivable_.initialize(address(0));
    }

    function test_Initialize() public {
        IReceivable receivable_ = deployReceivable(isleGlobals);
        assertEq(receivable_.governor(), users.governor);
    }
}

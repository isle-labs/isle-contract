// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Receivable_Unit_Shared_Test } from "../../../shared/receivable/Receivable.t.sol";

import { IReceivable } from "contracts/interfaces/IReceivable.sol";
import { IAdminable } from "contracts/interfaces/IAdminable.sol";

import { Receivable } from "contracts/libraries/types/DataTypes.sol";

contract Initialize_Receivable_Unit_Concrete_Test is Receivable_Unit_Shared_Test {
    function setUp() public virtual override(Receivable_Unit_Shared_Test) {
        Receivable_Unit_Shared_Test.setUp();
    }

    function test_Initialize() public {
        IReceivable receivable_ = deployReceivable();

        assertEq(IAdminable(address(receivable_)).admin(), users.governor);
    }
}

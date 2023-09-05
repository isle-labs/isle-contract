// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Receivable_Unit_Shared_Test } from "../../../shared/receivable/Receivable.t.sol";

contract CreateReceivable_Unit_Concrete_Test is Receivable_Unit_Shared_Test {
    function setUp() public virtual override(Receivable_Unit_Shared_Test) {
        Receivable_Unit_Shared_Test.setUp();
    }
}

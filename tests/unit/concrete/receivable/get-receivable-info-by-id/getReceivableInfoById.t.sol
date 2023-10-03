// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Receivable_Unit_Shared_Test } from "../../../shared/receivable/Receivable.t.sol";

import { Receivable } from "contracts/libraries/types/DataTypes.sol";

contract GetReceivableInfoById_Receivable_Unit_Concrete_Test is Receivable_Unit_Shared_Test {
    function setUp() public virtual override(Receivable_Unit_Shared_Test) {
        Receivable_Unit_Shared_Test.setUp();
    }

    function test_GetReceivableInfoById() public {
        uint256 tokenId_ = createDefaultReceivable();
        Receivable.Info memory actualRECVInfo = receivable.getReceivableInfoById(tokenId_);
        assertEq(actualRECVInfo, defaults.receivableInfo());
    }
}

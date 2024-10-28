// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { VersionedInitializable } from "contracts/libraries/upgradability/VersionedInitializable.sol";
import { IsleGlobals_Unit_Concrete_Test } from "./IsleGlobals.t.sol";

contract GetRevision_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
    }

    function test_getRevision() external {
        assertEq(VersionedInitializable(address(isleGlobals)).getRevision(), 0x1);
    }
}

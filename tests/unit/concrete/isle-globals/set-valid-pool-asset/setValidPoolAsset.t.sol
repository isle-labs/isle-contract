// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IsleGlobals_Unit_Concrete_Test } from "../IsleGlobals.t.sol";

contract SetValidPoolAsset_IsleGlobals_Unit_Concrete_Test is IsleGlobals_Unit_Concrete_Test {
    function setUp() public virtual override(IsleGlobals_Unit_Concrete_Test) {
        IsleGlobals_Unit_Concrete_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));
        isleGlobals.setValidPoolAsset(address(usdc), true);
    }

    function test_SetValidPoolAsset() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit ValidPoolAssetSet(address(usdc), true);
        isleGlobals.setValidPoolAsset(address(usdc), true);
    }
}

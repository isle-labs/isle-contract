// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract lockedLiquidity_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_LockedLiquidity_NotInTheWindow() public {
        uint256 expectedLockedLiquidity_ = 0;
        uint256 actualLockedLiquidity_ = withdrawalManager.lockedLiquidity();
        
        assertEq(actualLockedLiquidity_, expectedLockedLiquidity_);
    }

    function test_lockedLiquidity() public {
        addDefaultShares();

        vm.warp(defaults.WINDOW_3());

        uint256 actualLockedLiquidity_ = withdrawalManager.lockedLiquidity();
        uint256 expectedLockedLiquidity_ = defaults.ADD_SHARES() * defaults.POOL_ASSETS() / defaults.POOL_SHARES();

        assertEq(actualLockedLiquidity_, expectedLockedLiquidity_);
    }
}

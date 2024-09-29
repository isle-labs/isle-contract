// SPDX-Lincense-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Pool } from "contracts/Pool.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract TotalAssets_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_TotalAssets() external {
        // before loan created
        assertEq(pool.totalAssets(), defaults.POOL_ASSETS(), "total assets");

        // after loan created
        fundDefaultLoan();
        assertEq(
            pool.totalAssets(), usdc.balanceOf(address(pool)) + loanManager.assetsUnderManagement(), "total assets"
        );
        assertEq(pool.totalAssets(), defaults.POOL_ASSETS(), "total assets");

        // when loan matured
        vm.warp(defaults.REPAYMENT_TIMESTAMP());
        assertEq(
            pool.totalAssets(), usdc.balanceOf(address(pool)) + loanManager.assetsUnderManagement(), "total assets"
        );
    }
}

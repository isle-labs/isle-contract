// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract ConvertTo_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_convertToAssets() external {
        assertEq(pool.convertToAssets(defaults.SHARES()), defaults.EXPECTED_ASSETS());
    }

    function test_convertToShares() external {
        assertEq(pool.convertToShares(defaults.ASSETS()), defaults.EXPECTED_SHARES());
    }

    function test_convertToExitAssets() external {
        _createUnrealizedLosses();
        assertEq(pool.convertToExitAssets(defaults.SHARES()), defaults.EXPECTED_EXIT_ASSETS());
    }

    function test_convertToExitShares() external {
        _createUnrealizedLosses();
        assertEq(pool.convertToExitShares(defaults.ASSETS()), defaults.EXPECTED_EXIT_SHARES());
    }

    function _createUnrealizedLosses() internal {
        // Unrealized losses is FACE_AMOUNT
        createDefaultLoan();
        loanManager.impairLoan(1);
    }
}

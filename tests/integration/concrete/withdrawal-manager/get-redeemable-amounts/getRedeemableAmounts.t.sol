// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract GetRedeemableAmounts_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    // Currently, this only tests the case where loans are not involved.
    function test_GetRedeemableAmounts() public {
        uint256 addShares_ = defaults.ADD_SHARES();

        addDefaultShares();

        (uint256 redeemableShares_, uint256 resultingAssets_) =
            withdrawalManager.getRedeemableAmounts({ lockedShares_: addShares_, owner_: users.receiver });

        assertEq(redeemableShares_, addShares_);
        assertEq(resultingAssets_, addShares_ * defaults.POOL_ASSETS() / defaults.POOL_SHARES());
    }
}

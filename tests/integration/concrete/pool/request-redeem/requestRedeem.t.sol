// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract RequestRedeem_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_RequestRedeem() external {
        uint256 originalReceiverBalance_ = pool.balanceOf(users.receiver);
        uint256 originalWithdrawalManagerBalance_ = pool.balanceOf(address(withdrawalManager));

        requestDefaultRedeem();

        assertEq(pool.balanceOf(users.receiver), originalReceiverBalance_ - defaults.REDEEM_SHARES());
        assertEq(
            pool.balanceOf(address(withdrawalManager)), originalWithdrawalManagerBalance_ + defaults.REDEEM_SHARES()
        );
    }
}

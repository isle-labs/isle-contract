// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Pool } from "contracts/Pool.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract RemoveShares_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_RemoveShares() external {
        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        uint256 actualSharesRemoved_ = removeDefaultShares();

        assertEq(actualSharesRemoved_, defaults.REMOVE_SHARES());
    }

    function test_RemoveShares_WhenCallerNotOwner() external {
        uint256 removeShares_ = defaults.REMOVE_SHARES();

        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        changePrank(users.receiver);
        pool.approve(users.caller, removeShares_);
        assertEq(pool.allowance(users.receiver, users.caller), removeShares_);

        changePrank(users.caller);
        uint256 actualSharesRemoved_ = pool.removeShares({ owner_: users.receiver, shares_: removeShares_ });

        assertEq(actualSharesRemoved_, removeShares_);
        assertEq(pool.allowance(users.receiver, users.caller), 0);
    }
}

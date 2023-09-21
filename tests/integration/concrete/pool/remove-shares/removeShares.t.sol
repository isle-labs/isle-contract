// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

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
}

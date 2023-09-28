// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract removeShares_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();
    }

    function test_removeShares() external whenCallerPool {
        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        vm.expectEmit(address(poolConfigurator));
        emit SharesRemoved({ owner_: users.receiver, shares_: defaults.REMOVE_SHARES() });

        uint256 actualSharesRemoved_ = removeDefaultShares();

        assertEq(actualSharesRemoved_, defaults.REMOVE_SHARES());
    }
}

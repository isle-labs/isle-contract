// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract Pool_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        changePrank(users.poolAdmin);
        setupPoolConfigurator();
        setupPool();

        // Make the msg sender the default caller
        changePrank(users.caller);
    }

    function setupPoolConfigurator() internal {
        poolConfigurator.setOpenToPublic(true);
        poolConfigurator.setLiquidityCap(defaults.POOL_LIMIT());
        poolConfigurator.setValidLender(users.receiver, true);
        poolConfigurator.setValidLender(users.caller, true);
    }

    function setupPool() internal {
        changePrank(users.caller);

        pool.deposit({ assets: defaults.POOL_SHARES(), receiver: users.caller });

        airdropTo(address(pool), defaults.POOL_ASSETS() - usdc.balanceOf(address(pool)));
    }
}

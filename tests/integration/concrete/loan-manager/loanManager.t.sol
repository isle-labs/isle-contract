// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract LoanManager_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        changePrank(users.poolAdmin);
        setUpPoolConfigurator();

        changePrank(users.caller);
        setUpPool(); // initialized pool state for testing

        // Make the msg sender the default pool admin
        changePrank(users.poolAdmin);
    }

    function setUpPoolConfigurator() internal {
        poolConfigurator.setOpenToPublic(true);
        poolConfigurator.setLiquidityCap(defaults.POOL_LIMIT());
        poolConfigurator.setValidLender(users.receiver, true);
        poolConfigurator.setValidLender(users.caller, true);

        poolConfigurator.setValidBuyer(users.buyer, true);
        poolConfigurator.setValidSeller(users.seller, true);
    }

    function setUpPool() internal {
        // Caller is the singler depositor initially
        pool.deposit({ assets: defaults.POOL_LIQUIDITY(), receiver: users.caller });
    }
}

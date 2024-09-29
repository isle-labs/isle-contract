// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract LoanManager_Integration_Concrete_Test is Integration_Test {
    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        initializePool();

        // Make the msg sender the default pool admin
        changePrank(users.poolAdmin);
        depositCover();
    }

    function depositCover() internal {
        poolConfigurator.depositCover(defaults.COVER_AMOUNT());
    }
}

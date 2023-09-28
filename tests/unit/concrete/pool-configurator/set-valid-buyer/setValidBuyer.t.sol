// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Unit_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetValidBuyer_Unit_Concrete_Test is PoolConfigurator_Unit_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Unit_Shared_Test) {
        PoolConfigurator_Unit_Shared_Test.setUp();

        poolConfigurator.setValidBuyer(users.buyer, false);
    }

    function test_RevertWhen_CallerNotPoolAdmin() external {
        // Make eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.poolAdmin, users.eve));
        poolConfigurator.setValidBuyer(users.buyer, true);
    }

    function test_setValidBuyer() external whenCallerPoolAdmin {
        assertFalse(poolConfigurator.isBuyer(users.buyer));

        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit ValidBuyerSet({ buyer_: users.buyer, isValid_: true });
        poolConfigurator.setValidBuyer(users.buyer, true);

        assertTrue(poolConfigurator.isBuyer(users.buyer));
    }
}

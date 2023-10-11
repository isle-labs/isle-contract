// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Unit_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract AssignPoolBuyer_Unit_Concrete_Test is PoolConfigurator_Unit_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Unit_Shared_Test) {
        PoolConfigurator_Unit_Shared_Test.setUp();

        // switch current pool buyer for testing purposes
        poolConfigurator.assignPoolBuyer(users.caller);
    }

    function test_RevertWhen_CallerNotPoolAdmin() external {
        // Make eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.poolAdmin, users.eve));
        poolConfigurator.assignPoolBuyer(users.buyer);
    }

    function test_AssignPoolBuyer() external whenCallerPoolAdmin {
        assertNotEq(poolConfigurator.buyer(), users.buyer);

        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit PoolBuyerAssign({ buyer_: users.buyer });
        poolConfigurator.assignPoolBuyer(users.buyer);

        assertEq(poolConfigurator.buyer(), users.buyer);
    }
}

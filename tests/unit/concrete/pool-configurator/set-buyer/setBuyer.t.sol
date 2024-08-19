// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Unit_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetBuyer_Unit_Concrete_Test is PoolConfigurator_Unit_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Unit_Shared_Test) {
        PoolConfigurator_Unit_Shared_Test.setUp();

        // switch current pool buyer for testing purposes
        poolConfigurator.setBuyer(users.caller);
    }

    function test_RevertWhen_CallerNotPoolAdminOrGovernor() external {
        // Make eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.PoolConfigurator_CallerNotPoolAdminOrGovernor.selector, users.eve)
        );
        poolConfigurator.setBuyer(users.buyer);
    }

    function test_SetBuyer() external whenCallerPoolAdmin {
        assertNotEq(poolConfigurator.buyer(), users.buyer);
        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit BuyerSet({ buyer_: users.buyer });
        poolConfigurator.setBuyer(users.buyer);

        assertEq(poolConfigurator.buyer(), users.buyer);
    }
}

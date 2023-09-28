// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Unit_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetValidLender_Unit_Concrete_Test is PoolConfigurator_Unit_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Unit_Shared_Test) {
        PoolConfigurator_Unit_Shared_Test.setUp();
    }

    function test_RevertWhen_CallerNotPoolAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.poolAdmin, users.eve));

        poolConfigurator.setValidLender(users.receiver, true);
    }

    function test_setValidLender() external whenCallerPoolAdmin {
        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit ValidLenderSet({ lender_: users.receiver, isValid_: true });
        poolConfigurator.setValidLender(users.receiver, true);

        assertTrue(poolConfigurator.isLender(users.receiver));
    }
}

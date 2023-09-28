// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Unit_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetValidSeller_Unit_Concrete_Test is PoolConfigurator_Unit_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Unit_Shared_Test) {
        PoolConfigurator_Unit_Shared_Test.setUp();

        poolConfigurator.setValidSeller(users.seller, false);
    }

    function test_RevertWhen_CallerNotPoolAdmin() external {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.poolAdmin, users.eve));

        poolConfigurator.setValidSeller(users.seller, true);
    }

    function test_setValidSeller() external whenCallerPoolAdmin {
        assertFalse(poolConfigurator.isSeller(users.seller));

        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit ValidSellerSet({ seller_: users.seller, isValid_: true });
        poolConfigurator.setValidSeller(users.seller, true);

        assertTrue(poolConfigurator.isSeller(users.seller));
    }
}

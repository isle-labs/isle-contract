// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Unit_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetAdminFee_Unit_Concrete_Test is PoolConfigurator_Unit_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Unit_Shared_Test) {
        PoolConfigurator_Unit_Shared_Test.setUp();
    }

    function test_RevertWhen_CallerNotPoolAdminOrGovernor() external {
        // Make eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.PoolConfigurator_CallerNotPoolAdminOrGovernor.selector, users.eve)
        );
        setDefaultAdminFee();
    }

    function test_setAdminFee() external whenCallerPoolAdmin {
        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit AdminFeeSet({ adminFee_: defaults.ADMIN_FEE_RATE() });

        setDefaultAdminFee();
        assertEq(poolConfigurator.adminFee(), defaults.ADMIN_FEE_RATE());
    }
}

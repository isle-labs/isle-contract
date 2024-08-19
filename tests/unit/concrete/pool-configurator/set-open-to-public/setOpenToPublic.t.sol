// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Unit_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetOpenToPublic_Unit_Concrete_Test is PoolConfigurator_Unit_Shared_Test {
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
        setDefaultOpenToPublic();
    }

    function test_setOpenToPublic() external whenCallerPoolAdmin {
        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit OpenToPublicSet({ isOpenToPublic_: defaults.OPEN_TO_PUBLIC() });
        setDefaultOpenToPublic();
        assertEq(poolConfigurator.openToPublic(), defaults.OPEN_TO_PUBLIC());
    }
}

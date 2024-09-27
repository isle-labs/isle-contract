// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetMaxCoverLiquidation_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override {
        PoolConfigurator_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        uint24 maxCoverLiquidation = defaults.MAX_COVER_LIQUIDATION();
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_CallerNotGovernor.selector, users.eve));
        poolConfigurator.setMaxCoverLiquidation(maxCoverLiquidation);
    }

    function test_SetMaxCoverLiquidation() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit MaxCoverLiquidationSet(defaults.MAX_COVER_LIQUIDATION());
        poolConfigurator.setMaxCoverLiquidation(defaults.MAX_COVER_LIQUIDATION());
        assertEq(poolConfigurator.maxCoverLiquidation(), defaults.MAX_COVER_LIQUIDATION());
    }
}

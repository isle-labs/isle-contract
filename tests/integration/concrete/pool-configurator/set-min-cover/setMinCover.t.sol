// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract SetMinCover_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override {
        PoolConfigurator_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.eve);
        uint104 minCover = defaults.MIN_COVER_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_CallerNotGovernor.selector, users.eve));
        poolConfigurator.setMinCover(minCover);
    }

    function test_SetMinCover() external whenCallerGovernor {
        vm.expectEmit(true, true, true, true);
        emit MinCoverSet(defaults.MIN_COVER_AMOUNT());
        poolConfigurator.setMinCover(defaults.MIN_COVER_AMOUNT());
        assertEq(poolConfigurator.minCover(), defaults.MIN_COVER_AMOUNT());
    }
}

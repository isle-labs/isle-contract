// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract TriggerDefault_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        poolConfigurator.depositCover(defaults.COVER_AMOUNT());
        fundDefaultLoan();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ProtocolPaused() external {
        pauseProtoco();
        poolConfigurator.triggerDefault(1);
    }

    function test_RevertWhen_PoolConfiguratorPaused_ContractPaused() external {
        pauseContract();
        poolConfigurator.triggerDefault(1);
    }

    function test_RevertWhen_PoolConfiguratorPaused_FunctionPaused() external {
        pauseFunction(bytes4(keccak256("triggerDefault(uint16)")));
        poolConfigurator.triggerDefault(1);
    }

    function test_RevertWhen_CallerNotPoolAdminOrGovernor() external whenFunctionNotPause {
        changePrank(users.caller);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.PoolConfigurator_CallerNotPoolAdminOrGovernor.selector, users.caller)
        );
        poolConfigurator.triggerDefault(1);
    }

    function test_TriggerDefault() external whenFunctionNotPause whenCallerPoolAdmin {
        uint256 coverAmount_ = 0;

        vm.warp(defaults.MAY_31_2023() + defaults.GRACE_PERIOD() + 1);

        expectCallToTransfer(address(pool), coverAmount_);

        vm.expectEmit(true, true, true, true);
        emit CoverLiquidated(coverAmount_);

        poolConfigurator.triggerDefault(1);

        assertEq(poolConfigurator.poolCover(), defaults.COVER_AMOUNT());
    }
}

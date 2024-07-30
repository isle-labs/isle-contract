// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract RequestRedeem_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    uint256 _redeemShares;

    function setUp() public override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();
        _redeemShares = defaults.REDEEM_SHARES();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ProtocolPaused() external {
        pauseProtoco();
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ContractPaused() external {
        pauseContract();
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_PoolConfiguratorPaused_FunctionPaused() external {
        pauseFunction(bytes4(keccak256("requestRedeem(uint256,address,address)")));
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_InvalidCaller() external whenFunctionNotPause {
        changePrank(users.receiver);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidCaller.selector, users.receiver, pool));
        poolConfigurator.requestRedeem(_redeemShares, users.receiver, users.receiver);
    }

    function test_RevertWhen_NoAllowance() external whenFunctionNotPause whenCallerPool {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.PoolConfigurator_NoAllowance.selector, users.receiver, users.caller)
        );
        poolConfigurator.requestRedeem(0, users.receiver, users.caller);
    }

    function test_RequestRedeem() external whenFunctionNotPause whenCallerPool whenAllowance {
        changePrank({ msgSender: users.receiver });
        pool.transfer({ to: address(poolConfigurator), amount: _redeemShares });

        changePrank({ msgSender: address(pool) });
        vm.expectEmit(true, true, true, true);
        emit RedeemRequested(users.receiver, _redeemShares);
        poolConfigurator.requestRedeem({ shares_: _redeemShares, owner_: users.receiver, sender_: users.receiver });
    }

    function expectPoolConfiguratorPauseRevert() private {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_Paused.selector));
        poolConfigurator.requestRedeem(_redeemShares, users.receiver, users.receiver);
    }
}

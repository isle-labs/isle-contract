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
        poolConfigurator.requestRedeem(_redeemShares, users.receiver);
    }

    function test_RevertWhen_PoolConfiguratorPaused_ContractPaused() external {
        pauseContract();
        poolConfigurator.requestRedeem(_redeemShares, users.receiver);
    }

    function test_RevertWhen_PoolConfiguratorPaused_FunctionPaused() external {
        pauseFunction(bytes4(keccak256("requestRedeem(uint256,address)")));
        poolConfigurator.requestRedeem(_redeemShares, users.receiver);
    }

    function test_RevertWhen_InvalidCaller() external whenFunctionNotPause {
        changePrank(users.receiver);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidCaller.selector, users.receiver, pool));
        poolConfigurator.requestRedeem(_redeemShares, users.receiver);
    }

    function test_RequestRedeem() external whenFunctionNotPause whenCallerPool {
        changePrank({ msgSender: users.receiver });
        pool.transfer({ to: address(poolConfigurator), amount: _redeemShares });

        changePrank({ msgSender: address(pool) });
        vm.expectEmit(true, true, true, true);
        emit RedeemRequested(users.receiver, _redeemShares);
        poolConfigurator.requestRedeem({ shares_: _redeemShares, owner_: users.receiver });
    }
}

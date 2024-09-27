// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract ProcessRedeem_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    uint256 private _redeemShares;

    modifier whenCallerHasAllowance() {
        _;
    }

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();
        _redeemShares = defaults.REDEEM_SHARES();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ProtocolPaused() external {
        pauseProtoco();
        poolConfigurator.processRedeem(_redeemShares, users.receiver, users.receiver);
    }

    function test_RevertWhen_PoolConfiguratorPaused_ContractPaused() external {
        pauseContract();
        poolConfigurator.processRedeem(_redeemShares, users.receiver, users.receiver);
    }

    function test_RevertWhen_PoolConfiguratorPaused_FunctionPaused() external {
        pauseFunction(bytes4(keccak256("processRedeem(uint256,address,address)")));
        poolConfigurator.processRedeem(_redeemShares, users.receiver, users.receiver);
    }

    function test_RevertWhen_CallerNotPool() external whenFunctionNotPause {
        changePrank(users.receiver);
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidCaller.selector, users.receiver, pool));
        poolConfigurator.processRedeem(_redeemShares, users.receiver, users.receiver);
    }

    function test_RevertWhen_CallerNoAllowance() external whenFunctionNotPause whenCallerPool {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.PoolConfigurator_NoAllowance.selector, users.receiver, users.caller)
        );
        poolConfigurator.processRedeem(_redeemShares, users.receiver, users.caller);
    }

    function test_ProcessRedeem() external whenFunctionNotPause whenCallerPool whenCallerHasAllowance {
        uint256 expectedResultingAssets_ = defaults.REDEEM_SHARES() * defaults.POOL_ASSETS() / defaults.POOL_SHARES();
        uint256 expectedRedeemableShares_ = defaults.REDEEM_SHARES();

        requestDefaultRedeem();

        vm.warp({ timestamp: defaults.WINDOW_3() });

        vm.expectEmit(address(poolConfigurator));
        emit RedeemProcessed({
            owner_: users.receiver,
            redeemableShares_: expectedRedeemableShares_,
            resultingAssets_: expectedResultingAssets_
        });
        (uint256 actualRedeemableShares_, uint256 actualResultingAssets_) = poolConfigurator.processRedeem({
            owner_: users.receiver,
            shares_: defaults.REDEEM_SHARES(),
            sender_: users.receiver
        });

        assertEq(actualResultingAssets_, expectedResultingAssets_);
        assertEq(actualRedeemableShares_, expectedRedeemableShares_);
    }
}

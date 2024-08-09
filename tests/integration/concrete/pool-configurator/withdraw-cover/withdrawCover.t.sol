// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract WithdrawCover_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    uint256 private _withdrawAmount;
    uint256 private _coverAmount;

    modifier whenPoolCoverIsSufficient() {
        _;
    }

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        _withdrawAmount = defaults.WITHDRAW_COVER_AMOUNT();
        _coverAmount = defaults.COVER_AMOUNT();

        changePrank(users.poolAdmin);
        poolConfigurator.depositCover(_coverAmount);
    }

    function test_RevertWhen_PoolConfiguratorPaused_ProtocolPaused() external {
        pauseProtoco();
        poolConfigurator.withdrawCover({ amount_: _withdrawAmount, recipient_: users.poolAdmin });
    }

    function test_RevertWhen_PoolConfiguratorPaused_ContractPaused() external {
        pauseContract();
        poolConfigurator.withdrawCover({ amount_: _withdrawAmount, recipient_: users.poolAdmin });
    }

    function test_RevertWhen_PoolConfiguratorPaused_FunctionPaused() external {
        pauseFunction(bytes4(keccak256("withdrawCover(uint256,address)")));
        poolConfigurator.withdrawCover({ amount_: _withdrawAmount, recipient_: users.poolAdmin });
    }

    function test_RevertWhen_CallerNotPoolAdmin() external whenFunctionNotPause {
        changePrank(users.eve);
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_CallerNotPoolAdmin.selector, users.eve));
        poolConfigurator.withdrawCover({ amount_: _withdrawAmount, recipient_: users.poolAdmin });
    }

    function test_RevertWhen_PoolCoverInsufficient() external whenFunctionNotPause whenCallerPoolAdmin {
        changePrank(users.governor);
        poolConfigurator.setMinCover(0);

        changePrank(users.poolAdmin);
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InsufficientCover.selector));
        poolConfigurator.withdrawCover({ amount_: _withdrawAmount, recipient_: users.poolAdmin });
    }

    function test_WithdrawCover() external whenFunctionNotPause whenCallerPoolAdmin whenPoolCoverIsSufficient {
        expectCallToTransfer({ to: users.poolAdmin, amount: _withdrawAmount });
        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit CoverWithdrawn(_withdrawAmount);
        poolConfigurator.withdrawCover({ amount_: _withdrawAmount, recipient_: users.poolAdmin });

        assertEq(poolConfigurator.poolCover(), _coverAmount - _withdrawAmount);
    }
}

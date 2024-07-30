// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract RequestFunds_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    uint256 private _principal;

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        _principal = defaults.PRINCIPAL_REQUESTED();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ProtocolPaused() external {
        changePrank(users.governor);
        isleGlobals.setProtocolPaused(true);
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ContractPaused() external {
        changePrank(users.governor);
        isleGlobals.setContractPaused(address(poolConfigurator), true);
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_PoolConfiguratorPaused_FunctionPaused() external {
        changePrank(users.governor);
        isleGlobals.setContractPaused(address(poolConfigurator), true);
        isleGlobals.setFunctionUnpaused(address(poolConfigurator), bytes4(keccak256("requestFunds(uint256)")), false);
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_CallerNotLoanManager() external whenFunctionNotPause {
        changePrank(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.PoolConfigurator_CallerNotLoanManager.selector, address(loanManager), users.eve
            )
        );
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_RevertWhen_InsufficientCover() external whenFunctionNotPause whenCallerLoanManager {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InsufficientCover.selector));
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_requestFunds() external whenCoverIsSufficient whenFunctionNotPause whenCallerLoanManager {
        expectCallToTransferFrom({ from: address(pool), to: address(loanManager), amount: _principal });
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function expectPoolConfiguratorPauseRevert() private {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_Paused.selector));
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    modifier whenCoverIsSufficient() {
        changePrank(users.poolAdmin);
        poolConfigurator.depositCover(defaults.COVER_AMOUNT());
        _;
    }
}

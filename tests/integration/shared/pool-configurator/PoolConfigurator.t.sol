// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Errors } from "contracts/libraries/Errors.sol";

import { Integration_Test } from "../../Integration.t.sol";

abstract contract PoolConfigurator_Integration_Shared_Test is Integration_Test {
    struct Params {
        uint256 redeemShares;
        uint256 removeShares;
    }

    Params private _params;

    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        _params.redeemShares = defaults.REDEEM_SHARES();
        _params.removeShares = defaults.REMOVE_SHARES();

        initializePool();

        changePrank(users.poolAdmin);
    }

    modifier whenCallerPoolAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.poolAdmin });
        _;
    }

    modifier whenCallerGovernor() {
        changePrank({ msgSender: users.governor });
        _;
    }

    modifier whenCallerPool() {
        changePrank({ msgSender: address(pool) });
        _;
    }

    modifier whenCallerReceiver() {
        changePrank({ msgSender: users.receiver });
        _;
    }

    modifier whenCallerLoanManager() {
        changePrank({ msgSender: address(loanManager) });
        _;
    }

    modifier whenFunctionNotPause() {
        _;
    }

    modifier expectPoolConfiguratorPauseRevert() {
        _;
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_Paused.selector));
    }

    function requestDefaultRedeem() internal {
        changePrank({ msgSender: users.receiver });
        pool.transfer({ to: address(poolConfigurator), amount: _params.redeemShares });
        changePrank({ msgSender: address(pool) });
        poolConfigurator.requestRedeem({ shares_: _params.redeemShares, owner_: users.receiver });
    }

    function removeDefaultShares() internal returns (uint256 sharesRemoved_) {
        sharesRemoved_ = poolConfigurator.removeShares({ shares_: _params.removeShares, owner_: users.receiver });
    }

    function pauseProtoco() internal expectPoolConfiguratorPauseRevert {
        changePrank(users.governor);
        isleGlobals.setProtocolPaused(true);
    }

    function pauseContract() internal expectPoolConfiguratorPauseRevert {
        changePrank(users.governor);
        isleGlobals.setContractPaused(address(poolConfigurator), true);
    }

    function pauseFunction(bytes4 sig_) internal expectPoolConfiguratorPauseRevert {
        changePrank(users.governor);
        isleGlobals.setContractPaused(address(poolConfigurator), true);
        isleGlobals.setFunctionUnpaused(address(poolConfigurator), sig_, false);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

abstract contract WithdrawalManager_Integration_Shared_Test is Integration_Test {
    using SafeCast for uint256;

    struct Params {
        uint256 addShares;
        uint256 removeShares;
        uint256 newWindowDuration;
        uint256 newCycleDuration;
    }

    Params private _params;

    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        _params.addShares = defaults.ADD_SHARES();
        _params.removeShares = defaults.REMOVE_SHARES();
        _params.newCycleDuration = defaults.NEW_CYCLE_DURATION();
        _params.newWindowDuration = defaults.NEW_WINDOW_DURATION();

        // Initialize pool with assets and shares
        initializePool();

        // Transfer shares to {PoolConfigurator}
        changePrank(users.receiver);
        pool.transfer({ to: address(poolConfigurator), amount: defaults.ADD_SHARES() });

        // Approve {WithdrawalManager} to use all shares of the {PoolConfigurator}.
        changePrank(address(poolConfigurator));
        pool.approve({ spender: address(withdrawalManager), amount: type(uint256).max });
    }

    modifier whenCallerPoolConfigurator() {
        // Make the Pool Configurator the caller in the rest of this test suite.
        changePrank({ msgSender: address(poolConfigurator) });
        _;
    }

    modifier whenCallerPoolAdmin() {
        changePrank({ msgSender: users.poolAdmin });
        _;
    }

    modifier notWithdrawalPending() {
        _;
    }

    modifier validRequestShares() {
        _;
    }

    modifier inTheWindow() {
        _;
    }

    function addDefaultShares() internal {
        withdrawalManager.addShares({ shares_: _params.addShares, owner_: users.receiver });
    }

    function removeDefaultShares() internal returns (uint256 sharesRemoved_) {
        sharesRemoved_ = withdrawalManager.removeShares({ shares_: _params.removeShares, owner_: users.receiver });
    }

    function setDefaultNewExitConfig() internal {
        withdrawalManager.setExitConfig({
            cycleDuration_: _params.newCycleDuration,
            windowDuration_: _params.newWindowDuration
        });
    }
}

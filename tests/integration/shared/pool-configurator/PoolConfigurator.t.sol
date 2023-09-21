// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

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

    modifier whenCallerPool() {
        changePrank({ msgSender: address(pool) });
        _;
    }

    modifier whenCallerReceiver() {
        changePrank({ msgSender: users.receiver });
        _;
    }

    function requestDefaultRedeem() internal {
        changePrank({ msgSender: users.receiver });
        pool.transfer({ to: address(poolConfigurator), amount: _params.redeemShares });
        changePrank({ msgSender: address(pool) });
        poolConfigurator.requestRedeem({ shares_: _params.redeemShares, owner_: users.receiver, sender_: users.receiver });
    }

    function removeDefaultShares() internal returns (uint256 sharesRemoved_) {
        sharesRemoved_ = poolConfigurator.removeShares({ shares_: _params.removeShares, owner_: users.receiver });
    }
}

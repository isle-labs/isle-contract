// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Integration_Test } from "../../Integration.t.sol";

abstract contract Pool_Integration_Shared_Test is Integration_Test {
    struct Params {
        uint256 redeemShares;
        uint256 removeShares;
    }

    Params private _params;

    function setUp() public virtual override(Integration_Test) {
        Integration_Test.setUp();

        _params.redeemShares = defaults.REDEEM_SHARES();
        _params.removeShares = defaults.REMOVE_SHARES();

        initializePool(); // initialized pool state for testing

        changePrank(users.poolAdmin);
        poolConfigurator.depositCover(defaults.COVER_AMOUNT());
    }

    function defaultRedeem() internal returns (uint256 assets_) {
        changePrank(users.receiver);
        assets_ = pool.redeem({ shares: _params.redeemShares, receiver: users.receiver, owner: users.receiver });
    }

    function requestDefaultRedeem() internal {
        changePrank(users.receiver);
        pool.requestRedeem({ owner_: users.receiver, shares_: _params.redeemShares });
    }

    function removeDefaultShares() internal returns (uint256 sharesReturned_) {
        changePrank(users.receiver);
        sharesReturned_ = pool.removeShares({ owner_: users.receiver, shares_: _params.removeShares });
    }
}

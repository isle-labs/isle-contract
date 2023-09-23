// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "../../../Base.t.sol";

import { Receivable } from "contracts/libraries/types/DataTypes.sol";

abstract contract Receivable_Unit_Shared_Test is Base_Test {
    struct Params {
        Receivable.Create createReceivable;
        Receivable.Info receivableInfo;
    }

    Params private _params;

    function setUp() public virtual override {
        Base_Test.setUp();

        _params.createReceivable = defaults.createReceivable();

        deployAndLabelContract();
    }

    function deployAndLabelContract() internal {
        changePrank(users.governor);
        receivable = deployReceivable();
    }

    modifier whenCallerPoolAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.poolAdmin });
        _;
    }

    function createDefaultReceivable() internal returns (uint256 tokenId_) {
        tokenId_ = receivable.createReceivable(_params.createReceivable);
    }
}

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
        deployAndLabelContract();
    }

    function deployAndLabelContract() internal {
        changePrank(users.governor);
        isleGlobals = deployGlobals();
        receivable = deployReceivable(isleGlobals);
    }

    modifier whenCallerPoolAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.poolAdmin });
        _;
    }

    function createDefaultReceivableWithFaceAmount(uint256 faceAmount_) internal returns (uint256 tokenId_) {
        Receivable.Create memory params_ = defaults.createReceivable();
        params_.faceAmount = faceAmount_;
        tokenId_ = receivable.createReceivable(params_);
    }
}

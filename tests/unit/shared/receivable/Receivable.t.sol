// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "../../../Base.t.sol";

import { Receivable } from "contracts/Receivable.sol";

abstract contract Receivable_Unit_Shared_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();

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
}

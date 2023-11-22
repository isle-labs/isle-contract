// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool_Integration_Shared_Test } from "./Pool.t.sol";

abstract contract Deposit_Integration_Shared_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override {
        changePrank(users.caller);
    }

    modifier whenDepositNotGreaterThanMax() {
        _;
    }

    modifier whenRecipientNotZeroAddress() {
        _;
    }
}

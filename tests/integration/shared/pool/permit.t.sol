// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool_Integration_Shared_Test } from "./Pool.t.sol";

abstract contract Permit_Integration_Shared_Test is Pool_Integration_Shared_Test {
    uint256 internal nonce = 0;

    function setUp() public virtual override {
        changePrank(users.staker.addr);
    }

    modifier whenNonceIsNotBad() {
        _;
    }

    modifier whenStakerIsCorrect() {
        _;
    }

    modifier whenNotPastDeadline() {
        _;
    }

    modifier whenPermitIsSufficient() {
        _;
    }
}

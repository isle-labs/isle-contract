// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool_Integration_Shared_Test } from "./Pool.t.sol";

abstract contract Mint_Integration_Shared_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override { }

    modifier whenMintNotGreaterThanMax() {
        _;
    }

    modifier whenRecipientNotZeroAddress() {
        _;
    }
}

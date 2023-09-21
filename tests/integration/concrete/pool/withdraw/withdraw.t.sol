// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract Withdraw_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_Withdraw() external {
        vm.expectRevert(Errors.Pool_WithdrawalNotImplemented.selector);
        pool.withdraw({ owner: users.receiver, assets: 10, receiver: users.receiver });
    }
}

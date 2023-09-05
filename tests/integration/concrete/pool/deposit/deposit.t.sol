// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Errors } from "contracts/libraries/Errors.sol";

import { Deposit_Integration_Shared_Test } from "../../../shared/pool/deposit.t.sol";
import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract Deposit_Integration_Concrete_Test is Pool_Integration_Shared_Test, Deposit_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test, Deposit_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
        Deposit_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DepositGreaterThanMax() external {
        uint256 maxAssets_ = pool.maxDeposit(users.receiver);
        uint256 assets_ = maxAssets_ + 1;

        vm.expectRevert(abi.encodeWithSelector(Errors.Pool_DepositGreaterThanMax.selector, assets_, maxAssets_));
        pool.deposit({ assets: assets_, receiver: users.receiver });
    }

    function test_RevertWhen_RecipientZeroAddress() external whenDepositNotGreaterThanMax {
        uint256 assets_ = defaults.DEPOSIT_AMOUNT();
        vm.expectRevert(Errors.Pool_RecipientZeroAddress.selector);
        pool.deposit({ assets: assets_, receiver: address(0) });
    }

    function test_Deposit() external whenDepositNotGreaterThanMax whenRecipientNotZeroAddress {
        uint256 assets_ = defaults.DEPOSIT_AMOUNT();

        // Expects the funds to be transferred from the funder to {Pool}
        expectCallToTransferFrom({ from: users.caller, to: address(pool), amount: assets_ });

        uint256 shares_ = pool.previewDeposit(assets_);

        // Expects the pool to emit a {Deposit} event
        vm.expectEmit({ emitter: address(pool) });
        emit Deposit({ sender: users.caller, owner: users.receiver, assets: assets_, shares: shares_ });

        // Checks that the receiver has the correct amount of {shares}
        pool.deposit({ assets: assets_, receiver: users.receiver });
    }
}

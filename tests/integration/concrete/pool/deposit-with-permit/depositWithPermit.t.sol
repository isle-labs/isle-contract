// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Errors } from "contracts/libraries/Errors.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";
import { Deposit_Integration_Shared_Test } from "../../../shared/pool/deposit.t.sol";
import { Permit_Integration_Shared_Test } from "../../../shared/pool/permit.t.sol";

contract DepositWithPermit_Pool_Integration_Concrete_Test is
    Pool_Integration_Shared_Test,
    Deposit_Integration_Shared_Test,
    Permit_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(Pool_Integration_Shared_Test, Deposit_Integration_Shared_Test, Permit_Integration_Shared_Test)
    {
        Pool_Integration_Shared_Test.setUp();
        Deposit_Integration_Shared_Test.setUp();
        Permit_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DepositGreaterThanMax() external {
        uint256 maxAssets_ = pool.maxDeposit(users.receiver);
        uint256 assets_ = maxAssets_ + 1;
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.Pool_DepositGreaterThanMax.selector, assets_, maxAssets_));
        pool.depositWithPermit(assets_, users.receiver, deadline_, v_, r_, s_);
    }

    function test_RevertWhen_RecipientZeroAddress() external whenDepositNotGreaterThanMax {
        uint256 assets_ = defaults.DEPOSIT_AMOUNT();
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        vm.expectRevert(Errors.Pool_RecipientZeroAddress.selector);
        pool.depositWithPermit(assets_, address(0), deadline_, v_, r_, s_);
    }

    function test_RevertWhen_NonceIsBad() external whenDepositNotGreaterThanMax whenRecipientNotZeroAddress {
        uint256 assets_ = defaults.DEPOSIT_AMOUNT();
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce + 1, deadline_, users.staker.key
        );

        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        pool.depositWithPermit(assets_, users.receiver, deadline_, v_, r_, s_);
    }

    function test_RevertWhen_StakerIsNotCorrect()
        external
        whenDepositNotGreaterThanMax
        whenRecipientNotZeroAddress
        whenNonceIsNotBad
    {
        uint256 assets_ = defaults.DEPOSIT_AMOUNT();
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.notStaker.key
        );

        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        pool.depositWithPermit(assets_, users.receiver, deadline_, v_, r_, s_);
    }

    function test_RevertWhen_PastDeadline()
        external
        whenDepositNotGreaterThanMax
        whenRecipientNotZeroAddress
        whenNonceIsNotBad
        whenStakerIsCorrect
    {
        uint256 assets_ = defaults.DEPOSIT_AMOUNT();
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        vm.warp(deadline_ + 1);

        vm.expectRevert("ERC20:P:EXPIRED");
        pool.depositWithPermit(assets_, users.receiver, deadline_, v_, r_, s_);
    }

    function test_DepositWithPermit()
        external
        whenDepositNotGreaterThanMax
        whenRecipientNotZeroAddress
        whenNonceIsNotBad
        whenStakerIsCorrect
        whenNotPastDeadline
    {
        uint256 assets_ = defaults.DEPOSIT_AMOUNT();
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        // Expects the funds to be transferred from the funder to {Pool}
        expectCallToTransferFrom({ from: users.staker.addr, to: address(pool), amount: assets_ });

        // Expects the pool to emit a {Deposit} event
        uint256 shares_ = pool.previewDeposit(assets_);
        vm.expectEmit({ emitter: address(pool) });
        emit Deposit({ sender: users.staker.addr, owner: users.receiver, assets: assets_, shares: shares_ });

        // Checks that the receiver has the correct amount of {shares}
        pool.depositWithPermit(assets_, users.receiver, deadline_, v_, r_, s_);
    }
}

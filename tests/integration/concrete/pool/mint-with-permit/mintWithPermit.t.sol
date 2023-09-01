// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Errors } from "contracts/libraries/Errors.sol";

import { Mint_Integration_Shared_Test } from "../../../shared/pool/mint.t.sol";
import { Permit_Integration_Shared_Test } from "../../../shared/pool/permit.t.sol";
import { Pool_Integration_Concrete_Test } from "../Pool.t.sol";

contract MintWithPermit_Integration_Concrete_Test is
    Pool_Integration_Concrete_Test,
    Mint_Integration_Shared_Test,
    Permit_Integration_Shared_Test
{
    using Math for uint256;

    function setUp()
        public
        virtual
        override(Pool_Integration_Concrete_Test, Mint_Integration_Shared_Test, Permit_Integration_Shared_Test)
    {
        Pool_Integration_Concrete_Test.setUp();
        Mint_Integration_Shared_Test.setUp();
        Permit_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_MintGreaterThanMax() external {
        uint256 maxShares_ = pool.maxMint(users.receiver);

        uint256 shares_ = maxShares_ + 1;
        uint256 assets_ = pool.previewMint(shares_);

        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.Pool_MintGreaterThanMax.selector, shares_, maxShares_));
        pool.mintWithPermit(shares_, users.receiver, assets_, deadline_, v_, r_, s_);
    }

    function test_RevertWhen_RecipientZeroAddress() external whenMintNotGreaterThanMax {
        uint256 shares_ = defaults.MINT_AMOUNT();
        uint256 assets_ = pool.previewMint(shares_);
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        vm.expectRevert(Errors.Pool_RecipientZeroAddress.selector);
        pool.mintWithPermit(assets_, address(0), assets_, deadline_, v_, r_, s_);
    }

    function test_RevertWhen_PermitIsInsufficient() external whenMintNotGreaterThanMax whenRecipientNotZeroAddress {
        uint256 shares_ = defaults.MINT_AMOUNT();
        uint256 assets_ = pool.previewMint(shares_);

        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.Pool_InsufficientPermit.selector, assets_, assets_ - 1));
        pool.mintWithPermit(shares_, users.receiver, assets_ - 1, deadline_, v_, r_, s_);
    }

    function test_RevertWhen_NonceIsBad()
        external
        whenMintNotGreaterThanMax
        whenRecipientNotZeroAddress
        whenPermitIsSufficient
    {
        uint256 shares_ = defaults.MINT_AMOUNT();
        uint256 assets_ = pool.previewMint(shares_);
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce + 1, deadline_, users.staker.key
        );

        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        pool.mintWithPermit(shares_, users.receiver, assets_, deadline_, v_, r_, s_);
    }

    function test_RevertWhen_StakerIsNotCorrect()
        external
        whenMintNotGreaterThanMax
        whenRecipientNotZeroAddress
        whenPermitIsSufficient
        whenNonceIsNotBad
    {
        uint256 shares_ = defaults.MINT_AMOUNT();
        uint256 assets_ = pool.previewMint(shares_);
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.notStaker.key
        );

        vm.expectRevert("ERC20:P:INVALID_SIGNATURE");
        pool.depositWithPermit(assets_, users.receiver, deadline_, v_, r_, s_);
    }

    function test_RevertWhen_PastDeadline()
        external
        whenMintNotGreaterThanMax
        whenRecipientNotZeroAddress
        whenPermitIsSufficient
        whenNonceIsNotBad
        whenStakerIsCorrect
    {
        uint256 shares_ = defaults.MINT_AMOUNT();
        uint256 assets_ = pool.previewMint(shares_);
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        vm.warp(deadline_ + 1);

        vm.expectRevert("ERC20:P:EXPIRED");
        pool.depositWithPermit(assets_, users.receiver, deadline_, v_, r_, s_);
    }

    function test_MintWithPermit()
        external
        whenMintNotGreaterThanMax
        whenRecipientNotZeroAddress
        whenPermitIsSufficient
        whenNonceIsNotBad
        whenStakerIsCorrect
        whenNotPastDeadline
    {
        uint256 shares_ = defaults.MINT_AMOUNT();
        uint256 assets_ = pool.previewMint(shares_);
        uint256 deadline_ = defaults.DEADLINE();

        (uint8 v_, bytes32 r_, bytes32 s_) = getValidPermitSignature(
            address(usdc), users.staker.addr, address(pool), assets_, nonce, deadline_, users.staker.key
        );

        // Expects the funds to be transferred from the funder to {Pool}
        expectCallToTransferFrom({ from: users.staker.addr, to: address(pool), amount: assets_ });

        // Expects the pool to emit a {Mint} event
        vm.expectEmit({ emitter: address(pool) });
        emit Deposit({ sender: users.staker.addr, owner: users.receiver, assets: assets_, shares: shares_ });

        // Checks that the receiver has the correct amount of {shares}
        pool.mintWithPermit(shares_, users.receiver, assets_, deadline_, v_, r_, s_);
        assertEq(shares_, pool.balanceOf(users.receiver));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Errors } from "contracts/libraries/Errors.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";
import { Mint_Integration_Shared_Test } from "../../../shared/pool/mint.t.sol";

contract Mint_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test, Mint_Integration_Shared_Test {
    using Math for uint256;

    function setUp() public virtual override(Pool_Integration_Shared_Test, Mint_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
        Mint_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_MintGreaterThanMax() external {
        uint256 maxShares_ = pool.maxMint(users.receiver);
        uint256 shares_ = maxShares_ + 1;

        vm.expectRevert(abi.encodeWithSelector(Errors.Pool_MintGreaterThanMax.selector, shares_, maxShares_));
        pool.mint({ shares: shares_, receiver: users.receiver });
    }

    function test_RevertWhen_RecipientZeroAddress() external whenMintNotGreaterThanMax {
        uint256 shares_ = defaults.MINT_AMOUNT();

        vm.expectRevert(Errors.Pool_RecipientZeroAddress.selector);
        pool.mint({ shares: shares_, receiver: address(0) });
    }

    function test_Mint() external whenMintNotGreaterThanMax whenRecipientNotZeroAddress {
        uint256 shares_ = defaults.MINT_AMOUNT();
        uint256 assets_ = pool.previewMint(shares_);

        // Expects the funds to be transferred from the funder to {Pool}
        expectCallToTransferFrom({ from: users.caller, to: address(pool), amount: assets_ });

        // Expects the pool to emit a {Deposit} event
        vm.expectEmit({ emitter: address(pool) });
        emit Deposit({ sender: users.caller, owner: users.receiver, assets: assets_, shares: shares_ });

        // Checks that the receiver has the correct amount of {shares}
        pool.mint({ shares: shares_, receiver: users.receiver });
    }
}

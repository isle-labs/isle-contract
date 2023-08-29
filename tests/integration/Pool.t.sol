// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";

import { IERC20 } from "../../contracts/interfaces/IERC20.sol";

import { IntegrationTest } from "./Integration.t.sol";

contract PoolTest is IntegrationTest {
    uint256 internal _delta_ = 1e6;

    address internal _owner;
    address internal _spender;

    uint256 internal _skOwner = 1;
    uint256 internal _nonce = 0;

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();

        // Derive owner address from specified private key
        _owner = vm.addr(_skOwner);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_deposit() public {
        assertEq(pool.maxDeposit(users.receiver), 1_000_000e6); // Pool liquidity cap was set to this number

        uint256 oldCallerAsset = usdc.balanceOf(users.caller);
        uint256 oldReceiverShare = pool.balanceOf(users.receiver);

        vm.prank(users.caller);
        pool.deposit({ assets: 1000e6, receiver: users.receiver });

        uint256 newCallerAsset = usdc.balanceOf(users.caller);
        uint256 newReceiverShare = pool.balanceOf(users.receiver);

        assertAlmostEq(newCallerAsset, oldCallerAsset - 1000e6, _delta_, "caller asset");
        assertAlmostEq(newReceiverShare, oldReceiverShare + 1000e6, _delta_, "receiver share");
    }

    function test_depositWithPermit() public {
        assertEq(pool.maxDeposit(users.receiver), 1_000_000e6);

        deal({ token: address(usdc), to: _owner, give: 1_000_000e6 });

        uint256 oldCallerAsset = usdc.balanceOf(_owner);
        uint256 oldReceiverShare = pool.balanceOf(users.receiver);

        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(usdc), _owner, address(pool), 1000e6, _nonce, block.timestamp + 1 days, _skOwner
        );

        vm.prank(_owner);
        pool.depositWithPermit(1000e6, users.receiver, block.timestamp + 1 days, v, r, s);

        uint256 newCallerAsset = usdc.balanceOf(_owner);
        uint256 newReceiverShare = pool.balanceOf(users.receiver);
        uint256 newAllowance = usdc.allowance(_owner, address(pool));

        assertAlmostEq(newCallerAsset, oldCallerAsset - 1000e6, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare + 1000e6, _delta_);
        assertAlmostEq(newAllowance, 0, _delta_);
    }

    function test_mint() public {
        assertEq(pool.maxMint(users.receiver), 1_000_000e6);

        uint256 oldCallerAsset = usdc.balanceOf(users.caller);
        uint256 oldReceiverShare = pool.balanceOf(users.receiver);

        vm.prank(users.caller);
        pool.mint({ shares: 1000e6, receiver: users.receiver });

        uint256 newCallerAsset = usdc.balanceOf(users.caller);
        uint256 newReceiverShare = pool.balanceOf(users.receiver);

        assertAlmostEq(newCallerAsset, oldCallerAsset - 1000e6, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare + 1000e6, _delta_);
    }

    function test_mintWithPermit() public {
        assertEq(pool.maxMint(users.receiver), 1_000_000e6);

        deal({ token: address(usdc), to: _owner, give: 1_000_000e6 });

        uint256 oldCallerAsset = usdc.balanceOf(_owner);
        uint256 oldReceiverShare = pool.balanceOf(users.receiver);

        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(usdc), _owner, address(pool), 1000e6, _nonce, block.timestamp + 1 days, _skOwner
        );

        vm.prank(_owner);
        pool.mintWithPermit(1000e6, users.receiver, 1000e6, block.timestamp + 1 days, v, r, s);

        uint256 newCallerAsset = usdc.balanceOf(_owner);
        uint256 newReceiverShare = pool.balanceOf(users.receiver);
        uint256 newAllowance = usdc.allowance(_owner, address(pool));

        assertAlmostEq(newCallerAsset, oldCallerAsset - 1000e6, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare + 1000e6, _delta_);
        assertAlmostEq(newAllowance, 0, _delta_);
    }

    function test_withdraw() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1000e6);

        // we didn't implement withdraw function
        vm.expectRevert(abi.encodeWithSelector(Errors.Pool_WithdrawMoreThanMax.selector, 1000e6, 0));
        // notice that we are withdrawing usdcs from users.receiver, not users.caller
        vm.startPrank(users.receiver);
        pool.withdraw({ assets: 1000e6, receiver: users.caller, owner: users.receiver });
    }

    // TODO: complete this test after implementing WithdrawalManager
    function test_redeem() public {
        // uint256 shares = _callerDepositToReceiver(users.caller, users.receiver, 1000);

        // uint256 oldCallerAsset = usdc.balanceOf(users.caller);
        // uint256 oldReceiverShare = pool.balanceOf(users.receiver);

        // // notice that we are redeeming shares from users.receiver
        // vm.prank(users.receiver);
        // uint256 usdcs = pool.redeem(shares, users.caller, users.receiver);

        // uint256 newCallerAsset = usdc.balanceOf(users.caller);
        // uint256 newReceiverShare = pool.balanceOf(users.receiver);

        // assertAlmostEq(newCallerAsset, oldCallerAsset + usdcs, _delta_);
        // assertAlmostEq(newReceiverShare, oldReceiverShare - usdcs, _delta_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Withdrawal Request Functions
    //////////////////////////////////////////////////////////////////////////*/

    // TODO: complete these tests after implementing WithdrawalManager
    function test_removeShares() public { }

    function requestRedeem() public { }

    function requestWithdraw() public { }

    /*//////////////////////////////////////////////////////////////////////////
                                Public View Functions
    //////////////////////////////////////////////////////////////////////////*/

    function test_balanceOfAssets() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1000e6);
        uint256 receiverAssetBalances = pool.balanceOfAssets(users.receiver);
        assertAlmostEq(receiverAssetBalances, 1000e6, _delta_);
    }

    function test_maxDeposit() public {
        assertEq(pool.maxDeposit(users.receiver), 1_000_000e6);

        _airdropToPool(333e6); // for change exchange rate

        assertEq(pool.maxDeposit(users.receiver), 1_000_000e6 - 333e6);
        _callerDepositToReceiver(users.caller, users.receiver, 10_000e6);
        assertEq(pool.maxDeposit(users.receiver), 1_000_000e6 - 333e6 - 10_000e6);
    }

    function test_maxMint() public {
        assertEq(pool.maxMint(users.receiver), 1_000_000e6);

        _airdropToPool(333e6);

        uint256 shares = pool.previewDeposit(1_000_000e6 - 333e6);
        assertEq(pool.maxMint(users.receiver), shares);

        _callerMintToReceiver(users.caller, users.receiver, shares - 3);
        assertEq(pool.maxMint(users.receiver), 3);
    }

    // TODO: complete this test after implementing WithdrawalManager
    function test_maxRedeem() public { }

    function test_maxWithdraw() public {
        assertEq(pool.maxWithdraw(users.receiver), 0);

        _callerDepositToReceiver(users.caller, users.receiver, 1000e6);

        // always returns 0 as withdraw is not implemented
        assertEq(pool.maxWithdraw(users.receiver), 0);
    }

    // TODO: complete this test after implementing WithdrawalManager
    function test_previewWithdraw() public { }

    // TODO: complete this test after implementing WithdrawalManager
    function test_previewRedeem() public { }

    function test_convertToShares() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 shares = pool.convertToShares(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 + 1));
        assertAlmostEq(shares, result.intoUint256(), _delta_);
    }

    function test_convertToExitShares_zeroUnrealizedLosses() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 shares = pool.convertToExitShares(1000e6);
        // in exit case, we need to consider the unrealizedLosses
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 - 0e6 + 1));
        assertAlmostEq(shares, result.intoUint256(), _delta_);
    }

    // TODO: integrate with triggerDefault()
    function test_convertToExitShares_withUnrealizedLosses() public { }

    function test_convertToAssets() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 usdcs = pool.convertToAssets(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_050_000e6 + 1)).div(ud(1_000_000e6 + 1));
        assertAlmostEq(usdcs, result.intoUint256(), _delta_);
    }

    function test_convertToExitAssets_zeroUnrealizedLosses() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 usdcs = pool.convertToExitAssets(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_050_000e6 - 0e6 + 1)).div(ud(1_000_000e6 + 1));
        assertAlmostEq(usdcs, result.intoUint256(), _delta_);
    }

    // TODO: integrate with triggerDefault()
    function test_convertToExitAssets_withUnrealizedLosses() public { }

    function test_unrealizedLosses_zeroUnrealizedLosses() public {
        assertEq(pool.unrealizedLosses(), 0e6);
    }

    // TODO: integrate with triggerDefault()
    function test_unrealizedLosses_withUnrealizedLosses() public { }

    function test_previewDeposit() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 shares = pool.previewDeposit(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 + 1));
        assertAlmostEq(shares, result.intoUint256(), _delta_);
    }

    function test_previewMint() public {
        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 usdcs = pool.previewMint(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_050_000e6 + 1)).div(ud(1_000_000e6 + 1));
        assertAlmostEq(usdcs, result.intoUint256(), _delta_);
    }

    function test_decimals() public {
        assertEq(pool.decimals(), 18);
    }

    function test_asset() public {
        assertEq(pool.asset(), address(usdc));
    }

    function test_totalAssets() public {
        assertEq(pool.totalAssets(), 0);

        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        assertEq(pool.totalAssets(), 1_000_000e6);

        _airdropToPool(50_000e6);
        assertEq(pool.totalAssets(), 1_050_000e6);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    // Returns a valid `permit` signature signed by this contract's `owner` address
    function _getValidPermitSignature(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_,
        uint256 ownerSk_
    )
        internal
        view
        returns (uint8 v_, bytes32 r_, bytes32 s_)
    {
        return vm.sign(ownerSk_, _getDigest(token_, owner_, spender_, amount_, nonce_, deadline_));
    }

    // Returns an ERC-2612 `permit` digest for the `owner` to sign
    function _getDigest(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_
    )
        internal
        view
        returns (bytes32 digest_)
    {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                IERC20(token_).DOMAIN_SEPARATOR(),
                keccak256(abi.encode(IERC20(token_).PERMIT_TYPEHASH(), owner_, spender_, amount_, nonce_, deadline_))
            )
        );
    }
}

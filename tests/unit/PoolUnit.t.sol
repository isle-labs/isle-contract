// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./PoolBase.t.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

// Notice: we use MockPoolConfigurator instead of real PoolConfigurator in this test
// In MockPoolConfigurator, we override the functions associated with WithdrawManager
contract PoolUnitTest is PoolBase {
    uint256 internal _delta_ = 1e6;

    function setUp() public override {
        super.setUp();
        asset.mint(caller, 1000e6);
    }

    function test_deposit() public {
        vm.prank(caller);
        asset.approve(address(pool), 1000);

        uint256 oldCallerAsset = asset.balanceOf(caller);
        uint256 oldReceiverShare = pool.balanceOf(receiver);
        uint256 oldAllowance = asset.allowance(caller, address(pool));

        vm.prank(caller);
        pool.deposit(1000, receiver);

        uint256 newCallerAsset = asset.balanceOf(caller);
        uint256 newReceiverShare = pool.balanceOf(receiver);
        uint256 newAllowance = asset.allowance(caller, address(pool));

        assertAlmostEq(newCallerAsset, oldCallerAsset - 1000, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare + 1000, _delta_);

        if (oldAllowance != type(uint256).max) {
            assertAlmostEq(newAllowance, oldAllowance - 1000, _delta_, "allowance");
        }
    }

    function test_depositWithPermit() public {
        uint256 oldCallerAsset = asset.balanceOf(caller);
        uint256 oldReceiverShare = pool.balanceOf(receiver);

        uint256 callerPrivateKey = PRIVATE_KEYS[8];
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(asset), caller, address(pool), 1000, 0, block.timestamp + 1 days, callerPrivateKey
        );

        vm.prank(caller);
        pool.depositWithPermit(1000, receiver, block.timestamp + 1 days, v, r, s);

        uint256 newCallerAsset = asset.balanceOf(caller);
        uint256 newReceiverShare = pool.balanceOf(receiver);
        uint256 newAllowance = asset.allowance(caller, address(pool));

        assertAlmostEq(newCallerAsset, oldCallerAsset - 1000, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare + 1000, _delta_);
        assertAlmostEq(newAllowance, 0, _delta_);
    }

    function test_mint() public {
        vm.prank(caller);
        asset.approve(address(pool), 1000);

        uint256 oldCallerAsset = asset.balanceOf(caller);
        uint256 oldReceiverShare = pool.balanceOf(receiver);
        uint256 oldAllowance = asset.allowance(caller, address(pool));

        vm.prank(caller);
        pool.mint(1000, receiver);

        uint256 newCallerAsset = asset.balanceOf(caller);
        uint256 newReceiverShare = pool.balanceOf(receiver);
        uint256 newAllowance = asset.allowance(caller, address(pool));

        assertAlmostEq(newCallerAsset, oldCallerAsset - 1000, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare + 1000, _delta_);

        if (oldAllowance != type(uint256).max) {
            assertAlmostEq(newAllowance, oldAllowance - 1000, _delta_, "allowance");
        }
    }

    function test_mintWithPermit() public {
        uint256 oldCallerAsset = asset.balanceOf(caller);
        uint256 oldReceiverShare = pool.balanceOf(receiver);

        uint256 callerPrivateKey = PRIVATE_KEYS[8];
        (uint8 v, bytes32 r, bytes32 s) = _getValidPermitSignature(
            address(asset), caller, address(pool), 1000, 0, block.timestamp + 1 days, callerPrivateKey
        );

        vm.prank(caller);
        pool.mintWithPermit(1000, receiver, 1000, block.timestamp + 1 days, v, r, s);

        uint256 newCallerAsset = asset.balanceOf(caller);
        uint256 newReceiverShare = pool.balanceOf(receiver);
        uint256 newAllowance = asset.allowance(caller, address(pool));

        assertAlmostEq(newCallerAsset, oldCallerAsset - 1000, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare + 1000, _delta_);
        assertAlmostEq(newAllowance, 0, _delta_);
    }

    function test_withdraw() public {
        _callerDepositToReceiver(caller, receiver, 1000);

        uint256 oldCallerAsset = asset.balanceOf(caller);
        uint256 oldReceiverShare = pool.balanceOf(receiver);

        // notice that we are withdrawing assets from receiver, not caller
        vm.prank(receiver);
        uint256 shares = pool.withdraw(1000, caller, receiver);

        uint256 newCallerAsset = asset.balanceOf(caller);
        uint256 newReceiverShare = pool.balanceOf(receiver);

        assertAlmostEq(newCallerAsset, oldCallerAsset + shares, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare - shares, _delta_);
    }

    function test_redeem() public {
        uint256 shares = _callerDepositToReceiver(caller, receiver, 1000);

        uint256 oldCallerAsset = asset.balanceOf(caller);
        uint256 oldReceiverShare = pool.balanceOf(receiver);

        // notice that we are redeeming shares from receiver
        vm.prank(receiver);
        uint256 assets = pool.redeem(shares, caller, receiver);

        uint256 newCallerAsset = asset.balanceOf(caller);
        uint256 newReceiverShare = pool.balanceOf(receiver);

        assertAlmostEq(newCallerAsset, oldCallerAsset + assets, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare - assets, _delta_);
    }

    /* ========== Public View Functions ========== */

    function test_balanceOfAssets() public {
        _callerDepositToReceiver(caller, receiver, 1000);
        uint256 receiverAssetBalances = pool.balanceOfAssets(receiver);
        assertAlmostEq(receiverAssetBalances, 1000, _delta_);
    }

    function test_maxDeposit() public {
        uint256 maxDeposit = pool.maxDeposit(caller);
        assertAlmostEq(maxDeposit, type(uint256).max, _delta_);
    }

    
    function test_maxMint() public {
        uint256 maxMint = pool.maxMint(caller);
        assertAlmostEq(maxMint, type(uint256).max, _delta_);
    }

    function test_maxWithdraw() public {
        uint256 maxWithdraw = pool.maxWithdraw(caller);
        assertAlmostEq(maxWithdraw, type(uint256).max, _delta_);
    }

    function test_maxRedeem() public {
        uint256 maxRedeem = pool.maxRedeem(caller);
        assertAlmostEq(maxRedeem, type(uint256).max, _delta_);
    }

    function test_previewWithdraw() public {
        uint256 assets = pool.previewRedeem(1000e6);
        assertAlmostEq(assets, 1000e6, _delta_);
    }

    function test_previewRedeem() public {
        uint256 assets = pool.previewRedeem(1000e6);
        assertAlmostEq(assets, 1000e6, _delta_);
    }

    function test_convertToShares() public {
        asset.mint(caller, 1_000_000e6);
        _callerDepositToReceiver(caller, receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 shares = pool.convertToShares(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 + 1));
        assertAlmostEq(shares, result.intoUint256(), _delta_);
    }

    function test_convertToExitShares() public {
        asset.mint(caller, 1_000_000e6);
        _callerDepositToReceiver(caller, receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 shares = pool.convertToExitShares(1000e6);
        // in exit case, we need to consider the unrealizedLosses
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 - 5000e6 + 1));
        assertAlmostEq(shares, result.intoUint256(), _delta_);
    }

    function test_convertToAssets() public {
        asset.mint(caller, 1_000_000e6);
        _callerDepositToReceiver(caller, receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 assets = pool.convertToAssets(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_050_000e6 + 1)).div(ud(1_000_000e6 + 1));
        assertAlmostEq(assets, result.intoUint256(), _delta_);
    }

    function test_convertToExitAssets() public {
        asset.mint(caller, 1_000_000e6);
        _callerDepositToReceiver(caller, receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 assets = pool.convertToExitAssets(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_050_000e6 - 5000e6 + 1)).div(ud(1_000_000e6 + 1));
        assertAlmostEq(assets, result.intoUint256(), _delta_);
    }

    function test_unrealizedLosses() public {
        assertEq(pool.unrealizedLosses(), 5000e6);
    }

    function test_previewDeposit() public {
        asset.mint(caller, 1_000_000e6);
        _callerDepositToReceiver(caller, receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 shares = pool.previewDeposit(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 + 1));
        assertAlmostEq(shares, result.intoUint256(), _delta_);
    }

    function test_previewMint() public {
        asset.mint(caller, 1_000_000e6);
        _callerDepositToReceiver(caller, receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        uint256 assets = pool.previewMint(1000e6);
        UD60x18 result = ud(1000e6).mul(ud(1_050_000e6 + 1)).div(ud(1_000_000e6 + 1));
        assertAlmostEq(assets, result.intoUint256(), _delta_);
    }

    function test_decimals() public {
        assertEq(pool.decimals(), 18);
    }

    function test_asset() public {
        assertEq(pool.asset(), address(asset));
    }

    function test_totalAssets() public {
        assertEq(pool.totalAssets(), 0);
        asset.mint(caller, 1_000_000e6);
        _callerDepositToReceiver(caller, receiver, 1_000_000e6);
        assertEq(pool.totalAssets(), 1_000_000e6);
        _airdropToPool(50_000e6);
        assertEq(pool.totalAssets(), 1_050_000e6);
    }

    /* ========== Helper Functions ========== */

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

    function _callerDepositToReceiver(
        address caller_,
        address receiver_,
        uint256 assets_
    )
        internal
        returns (uint256 shares_)
    {
        vm.startPrank(caller_);
        asset.approve(address(pool), assets_);
        shares_ = pool.deposit(assets_, receiver_);
        vm.stopPrank();
    }

    function _airdropToPool(uint256 amount) internal {
        asset.mint(address(pool), amount);
    }
}

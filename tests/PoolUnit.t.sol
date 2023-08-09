// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./PoolBase.t.sol";

// notice that we use MockPoolConfigurator instead of real PoolConfigurator in this test
contract PoolUnitTest is PoolBase {
    uint256 internal _delta_;

    function setUp() public override {
        super.setUp();
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
    
    //TODO: add a test that caller of withdraw() is not the owner of the assets
    function test_withdraw() public {
        vm.startPrank(caller);
        asset.approve(address(pool), 1000);
        pool.deposit(1000, receiver);
        vm.stopPrank();

        uint256 oldCallerAsset = asset.balanceOf(caller);
        uint256 oldReceiverShare = pool.balanceOf(receiver);
        uint256 oldAllowance = asset.allowance(caller, address(pool));

        // notice that we are withdrawing assets from receiver, not caller
        vm.prank(receiver);
        uint256 assets = pool.withdraw(1000, caller, receiver);

        uint256 newCallerAsset = asset.balanceOf(caller);
        uint256 newReceiverShare = pool.balanceOf(receiver);
        uint256 newAllowance = asset.allowance(caller, address(pool));

        assertAlmostEq(newCallerAsset, oldCallerAsset + assets, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare - assets, _delta_);
    }

    // TODO: add a test that caller of redeem() is not the owner of the shares
    function test_redeem() public {
        vm.startPrank(caller);
        asset.approve(address(pool), 1000);
        uint256 shares = pool.deposit(1000, receiver);
        vm.stopPrank();

        uint256 oldCallerAsset = asset.balanceOf(caller);
        uint256 oldReceiverShare = pool.balanceOf(receiver);
        uint256 oldAllowance = pool.allowance(caller, address(pool));

        // notice that we are redeeming shares from receiver
        vm.prank(receiver);
        uint256 assets = pool.redeem(shares, caller, receiver);

        uint256 newCallerAsset = asset.balanceOf(caller);
        uint256 newReceiverShare = pool.balanceOf(receiver);
        uint256 newAllowance = pool.allowance(caller, address(pool));

        assertAlmostEq(newCallerAsset, oldCallerAsset + assets, _delta_);
        assertAlmostEq(newReceiverShare, oldReceiverShare - assets, _delta_);
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
}

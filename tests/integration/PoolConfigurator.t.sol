// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";

import { IPoolConfiguratorEvents } from "../../contracts/interfaces/pool/IPoolConfiguratorEvents.sol";
import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";

import { PoolConfigurator } from "../../contracts/PoolConfigurator.sol";
import { Integration_Test } from "./Integration.t.sol";

contract PoolConfiguratorTest is Integration_Test, IPoolConfiguratorEvents {
    uint256 internal _delta_ = 1e6;

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        Integration_Test.setUp();

        changePrank(users.poolAdmin);
        _setupPoolConfigurator();

        changePrank(users.caller);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_hasSufficientCover_True() public {
        assertTrue(poolConfigurator.hasSufficientCover());
    }

    function test_hasSufficientCover_False() public {
        changePrank(users.governor);
        lopoGlobals.setMinCoverAmount(address(poolConfigurator), 10_000e6);

        assertFalse(poolConfigurator.hasSufficientCover());
    }

    // TODO: try to integrate with LoanManager
    function test_totalAssets() public {
        uint256 totalAssets = poolConfigurator.totalAssets();
        assertEq(totalAssets, 0);

        callerDepositToReceiver(users.caller, users.receiver, 1000e6);
        totalAssets = poolConfigurator.totalAssets();
        assertEq(totalAssets, 1000e6);
    }

    function test_convertToExitShares() public {
        uint256 exitShares = poolConfigurator.convertToExitShares(1000e6);
        assertEq(exitShares, 1000e6);

        callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        airdropTo(address(pool), 50_000e6);
        exitShares = pool.convertToExitShares(1000e6);
        // in exit case, we need to consider the unrealizedLosses
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 - 0e6 + 1));
        assertAlmostEq(exitShares, result.intoUint256(), _delta_);
    }

    function test_getEscrowParams() public {
        (uint256 escrowShares_, address destination_) = poolConfigurator.getEscrowParams(users.receiver, 1000e6);

        assertEq(escrowShares_, 1000e6);
        assertEq(destination_, address(poolConfigurator));
    }

    function test_maxDepoist() public {
        assertEq(poolConfigurator.maxDeposit(users.receiver), 1_000_000e6);

        callerDepositToReceiver(users.caller, users.receiver, 1500e6);

        // if receiver is a valid lender or the pool is openToPublic
        assertEq(poolConfigurator.maxDeposit(users.receiver), 1_000_000e6 - 1500e6);

        uint256 maxDeposit = poolConfigurator.maxDeposit(users.receiver);
        assertEq(maxDeposit, 1_000_000e6 - 1500e6);
    }

    function test_maxMint() public {
        assertEq(poolConfigurator.maxMint(users.receiver), 1_000_000e6);

        // if receiver is a valid lender
        airdropTo(address(pool), 333e6);

        uint256 shares = pool.previewDeposit(1_000_000e6 - 333e6);
        assertEq(pool.maxMint(users.receiver), shares);

        callerMintToReceiver(users.caller, users.receiver, shares - 3);
        assertEq(pool.maxMint(users.receiver), 3);

        uint256 maxMint = poolConfigurator.maxMint(users.receiver);
        assertEq(maxMint, 3);
    }

    // TODO: complete this test after implementing withdrawalManager
    function test_maxRedeem() public { }

    function test_maxWithdraw() public {
        // it'll always return 0
        assertEq(poolConfigurator.maxWithdraw(users.receiver), 0);
    }

    // TODO: complete this test after implementing withdrawalManager
    function test_previewRedeem() public { }

    // TODO: complete this test after implementing withdrawalManager
    function test_previewWithdraw() public { }

    // TODO: complete this test after implementing loanManager
    function test_unrealizedLosses() public { }

    function test_setPendingPoolAdmin() public {
        vm.expectEmit(true, true, true, true);
        emit PendingPoolAdminSet(address(users.poolAdmin), address(users.caller));

        changePrank(users.poolAdmin);
        poolConfigurator.setPendingPoolAdmin(address(users.caller));

        assertEq(poolConfigurator.pendingPoolAdmin(), address(users.caller));
    }

    function test_acceptPoolAdmin() public {
        changePrank(users.poolAdmin);
        poolConfigurator.setPendingPoolAdmin(address(users.receiver));
        assertEq(poolConfigurator.pendingPoolAdmin(), address(users.receiver));

        // transfer admin to an invalid pool admin
        changePrank(users.receiver);
        vm.expectRevert();
        poolConfigurator.acceptPoolAdmin();

        // transfer admin to a valid pool admin
        changePrank(users.governor);
        lopoGlobals.setValidPoolAdmin(address(users.receiver), true);

        vm.expectEmit(true, true, true, true);
        emit PendingPoolAdminAccepted(address(users.poolAdmin), address(users.receiver));

        changePrank(users.receiver);
        poolConfigurator.acceptPoolAdmin();

        assertEq(poolConfigurator.poolAdmin(), address(users.receiver));
    }

    function test_setValidLender() public {
        assertTrue(poolConfigurator.isLender(address(users.receiver)));

        vm.expectEmit(true, true, true, true);
        emit ValidLenderSet(address(users.receiver), false);

        changePrank(users.poolAdmin);
        poolConfigurator.setValidLender(address(users.receiver), false);

        assertFalse(poolConfigurator.isLender(address(users.receiver)));
    }

    function test_setLiquidityCap() public {
        assertEq(poolConfigurator.liquidityCap(), 1_000_000e6);

        vm.expectEmit(true, true, true, true);
        emit LiquidityCapSet(1_500_000e6);

        changePrank(users.poolAdmin);
        poolConfigurator.setLiquidityCap(1_500_000e6);

        assertEq(poolConfigurator.liquidityCap(), 1_500_000e6);
    }

    function test_setOpenToPublic() public {
        changePrank(users.poolAdmin);
        poolConfigurator.setOpenToPublic(false);

        assertFalse(poolConfigurator.openToPublic());

        vm.expectEmit(true, true, true, true);
        emit OpenToPublic(true);

        poolConfigurator.setOpenToPublic(true);

        assertTrue(poolConfigurator.openToPublic());
    }

    // TODO: complete this test after implementing withdrawalManager
    function test_requestFunds() public { }

    // TODO: complete this test after implementing loanManager
    function test_triggerDefault() public { }

    // TODO: complete this test after implementing withdrawalManager
    function test_processRedeem() public { }

    function test_processWithdraw() public {
        // withdraw is not implemented, it'll always revert
        vm.expectRevert(Errors.PoolConfigurator_WithdrawalNotImplemented.selector);

        changePrank(address(pool));
        poolConfigurator.processWithdraw(1000e6, address(users.receiver), address(users.caller));
    }

    // TODO: complete this test after implementing withdrawalManager
    function test_removeShares() public { }

    //TODO: complete this test after implementing withdrawalManager
    function test_requestRedeem() public { }

    function test_requestWithdraw() public {
        // withdraw is not implemented, it'll always revert
        vm.expectRevert(Errors.PoolConfigurator_WithdrawalNotImplemented.selector);

        changePrank(address(pool));
        poolConfigurator.requestWithdraw(1000e6, 1000e6, address(users.receiver), address(users.caller));
    }

    function test_depositCover() public {
        changePrank(users.poolAdmin);
        usdc.approve(address(poolConfigurator), 1000e6);

        vm.expectEmit();
        emit CoverDeposited(1000e6);

        poolConfigurator.depositCover(1000e6);

        assertEq(poolConfigurator.totalAssets(), 0);
        assertEq(poolConfigurator.poolCover(), 1000e6);

        airdropTo(address(pool), 500e6);
        assertEq(poolConfigurator.totalAssets(), 500e6);
    }

    function test_withdrawCover_SufficientCover() public {
        _depositCover(1000e6);
        assertEq(poolConfigurator.poolCover(), 1000e6);

        changePrank(users.poolAdmin);

        vm.expectEmit();
        emit CoverWithdrawn(1000e6);

        poolConfigurator.withdrawCover(1000e6, address(users.caller));

        assertEq(poolConfigurator.poolCover(), 0);
    }

    function test_withdrawCover_InsufficientCover() public {
        _depositCover(1000e6);
        assertEq(poolConfigurator.poolCover(), 1000e6);

        // set minCoverAmount to 2000e6
        changePrank(users.governor);
        lopoGlobals.setMinCoverAmount(address(poolConfigurator), 2000e6);

        changePrank(users.poolAdmin);
        vm.expectRevert(Errors.PoolConfigurator_InsufficientCover.selector);

        poolConfigurator.withdrawCover(1000e6, address(users.caller));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _setupPoolConfigurator() internal {
        poolConfigurator.setOpenToPublic(true);
        poolConfigurator.setLiquidityCap(defaults.POOL_LIMIT());
        poolConfigurator.setValidLender(users.receiver, true);
        poolConfigurator.setValidLender(users.caller, true);

        poolConfigurator.setValidBuyer(users.buyer, true);
        poolConfigurator.setValidSeller(users.seller, true);
    }

    function _depositCover(uint256 amount) internal {
        changePrank(users.poolAdmin);
        usdc.approve(address(poolConfigurator), amount);
        poolConfigurator.depositCover(amount);
    }
}

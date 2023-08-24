// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Integration.t.sol";
import { IPoolConfiguratorEvents } from "../../contracts/interfaces/pool/IPoolConfiguratorEvents.sol";

contract PoolConfiguratorTest is IntegrationTest, IPoolConfiguratorEvents {
    uint256 internal _delta_ = 1e6;

    PoolConfiguratorHarness internal poolConfiguratorHarness;
    IPool internal poolHarness;

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
        _setUpPoolConfiguratorHarness();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_hasSufficientCover_True() public {
        assertTrue(wrappedPoolConfiguratorProxy.hasSufficientCover());
    }

    function test_hasSufficientCover_False() public {
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setMinCoverAmount(address(wrappedPoolConfiguratorProxy), 10_000e6);

        assertFalse(wrappedPoolConfiguratorProxy.hasSufficientCover());
    }

    // TODO: try to integrate with LoanManager
    function test_totalAssets() public {
        uint256 totalAssets = wrappedPoolConfiguratorProxy.totalAssets();
        assertEq(totalAssets, 0);

        _callerDepositToReceiver(users.caller, users.receiver, 1000e6);
        totalAssets = wrappedPoolConfiguratorProxy.totalAssets();
        assertEq(totalAssets, 1000e6);
    }

    function test_convertToExitShares() public {
        uint256 exitShares = wrappedPoolConfiguratorProxy.convertToExitShares(1000e6);
        assertEq(exitShares, 1000e6);

        _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
        _airdropToPool(50_000e6);
        exitShares = pool.convertToExitShares(1000e6);
        // in exit case, we need to consider the unrealizedLosses
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 - 0e6 + 1));
        assertAlmostEq(exitShares, result.intoUint256(), _delta_);
    }

    // TODO: complete this test after implementing loanManager
    function test_getEscrowParams() public { }

    function test_maxDepoist() public {
        assertEq(wrappedPoolConfiguratorProxy.maxDeposit(users.receiver), 1_000_000e6);

        _callerDepositToReceiver(users.caller, users.receiver, 1500e6);

        // if receiver is a valid lender
        assertEq(wrappedPoolConfiguratorProxy.maxDeposit(users.receiver), 1_000_000e6 - 1500e6);

        // if receiver is not a valid lender, and the pool is not openToPublic
        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setValidLender(users.receiver, false);

        uint256 maxDeposit = wrappedPoolConfiguratorProxy.maxDeposit(users.receiver);
        assertEq(maxDeposit, 0);

        // if receiver is not a valid lender, but the pool is openToPublic
        _setOpenToPublicTrue();
        maxDeposit = wrappedPoolConfiguratorProxy.maxDeposit(users.receiver);
        assertEq(maxDeposit, 1_000_000e6 - 1500e6);
    }

    function test_maxMint() public {
        assertEq(wrappedPoolConfiguratorProxy.maxMint(users.receiver), 1_000_000e6);

        // if receiver is a valid lender
        _airdropToPool(333e6);

        uint256 shares = pool.previewDeposit(1_000_000e6 - 333e6);
        assertEq(pool.maxMint(users.receiver), shares);

        _callerMintToReceiver(users.caller, users.receiver, shares - 3);
        assertEq(pool.maxMint(users.receiver), 3);

        // if receiver is not a valid lender, and the pool is not openToPublic
        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setValidLender(users.receiver, false);

        uint256 maxMint = wrappedPoolConfiguratorProxy.maxMint(users.receiver);
        assertEq(maxMint, 0);

        // if receiver is not a valid lender, but the pool is openToPublic
        _setOpenToPublicTrue();
        maxMint = wrappedPoolConfiguratorProxy.maxMint(users.receiver);
        assertEq(maxMint, 3);
    }

    // TODO: complete this test after implementing withdrawalManager
    function test_maxRedeem() public { }

    function test_maxWithdraw() public {
        // it'll always return 0
        assertEq(wrappedPoolConfiguratorProxy.maxWithdraw(users.receiver), 0);
    }

    // TODO: complete this test after implementing withdrawalManager
    function test_previewRedeem() public { }

    // TODO: complete this test after implementing withdrawalManager
    function test_previewWithdraw() public { }

    // TODO: complete this test after implementing loanManager
    function test_unrealizedLosses() public { }

    function test_getPool() public {
        assertEq(wrappedPoolConfiguratorProxy.getPool(), address(pool));
    }

    function test_setPendingPoolAdmin() public {
        vm.expectEmit(true, true, true, true);
        emit PendingPoolAdminSet(address(users.pool_admin), address(users.caller));

        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setPendingPoolAdmin(address(users.caller));

        assertEq(wrappedPoolConfiguratorProxy.pendingPoolAdmin(), address(users.caller));
    }

    function test_acceptPoolAdmin() public {
        vm.startPrank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setPendingPoolAdmin(address(users.receiver));
        assertEq(wrappedPoolConfiguratorProxy.pendingPoolAdmin(), address(users.receiver));

        // transfer admin to an invalid pool admin
        changePrank(users.receiver);
        vm.expectRevert();
        wrappedPoolConfiguratorProxy.acceptPoolAdmin();
        vm.stopPrank();

        // transfer admin to a valid pool admin
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setValidPoolAdmin(address(users.receiver), true);

        vm.expectEmit(true, true, true, true);
        emit PendingPoolAdminAccepted(address(users.pool_admin), address(users.receiver));

        vm.prank(users.receiver);
        wrappedPoolConfiguratorProxy.acceptPoolAdmin();

        assertEq(wrappedPoolConfiguratorProxy.poolAdmin(), address(users.receiver));
    }

    function test_setValidBorrower() public {
        assertTrue(wrappedPoolConfiguratorProxy.isBorrower(address(users.seller)));

        vm.expectEmit(true, true, true, true);
        emit ValidBorrowerSet(address(users.seller), false);

        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setValidBorrower(address(users.seller), false);

        assertFalse(wrappedPoolConfiguratorProxy.isBorrower(address(users.seller)));
    }

    function test_setValidLender() public {
        assertTrue(wrappedPoolConfiguratorProxy.isLender(address(users.receiver)));

        vm.expectEmit(true, true, true, true);
        emit ValidLenderSet(address(users.receiver), false);

        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setValidLender(address(users.receiver), false);

        assertFalse(wrappedPoolConfiguratorProxy.isLender(address(users.receiver)));
    }

    function test_setLiquidityCap() public {
        assertEq(wrappedPoolConfiguratorProxy.liquidityCap(), 1_000_000e6);

        vm.expectEmit(true, true, true, true);
        emit LiquidityCapSet(1_500_000e6);

        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setLiquidityCap(1_500_000e6);

        assertEq(wrappedPoolConfiguratorProxy.liquidityCap(), 1_500_000e6);
    }

    function test_setOpenToPublic() public {
        assertFalse(wrappedPoolConfiguratorProxy.openToPublic());

        vm.expectEmit(true, true, true, true);
        emit OpenToPublic(true);

        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setOpenToPublic(true);

        assertTrue(wrappedPoolConfiguratorProxy.openToPublic());
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

        vm.prank(address(pool));
        wrappedPoolConfiguratorProxy.processWithdraw(1000e6, address(users.receiver), address(users.caller));
    }

    // TODO: complete this test after implementing withdrawalManager
    function test_removeShares() public { }

    //TODO: complete this test after implementing withdrawalManager
    function test_requestRedeem() public { }

    function test_requestWithdraw() public {
        // withdraw is not implemented, it'll always revert
        vm.expectRevert(Errors.PoolConfigurator_WithdrawalNotImplemented.selector);

        vm.prank(address(pool));
        wrappedPoolConfiguratorProxy.requestWithdraw(1000e6, 1000e6, address(users.receiver), address(users.caller));
    }

    function test_depositCover() public {
        vm.startPrank(users.pool_admin);
        usdc.approve(address(wrappedPoolConfiguratorProxy), 1000e6);

        vm.expectEmit();
        emit CoverDeposited(1000e6);

        wrappedPoolConfiguratorProxy.depositCover(1000e6);
        vm.stopPrank();

        assertEq(wrappedPoolConfiguratorProxy.totalAssets(), 1000e6);
        assertEq(wrappedPoolConfiguratorProxy.poolCover(), 1000e6);

        _airdropToPool(500e6);
        assertEq(wrappedPoolConfiguratorProxy.totalAssets(), 1500e6);
    }

    function test_withdrawCover_SufficientCover() public {
        _depositCover(1000e6);
        assertEq(wrappedPoolConfiguratorProxy.totalAssets(), 1000e6);
        assertEq(wrappedPoolConfiguratorProxy.poolCover(), 1000e6);

        vm.startPrank(users.pool_admin);

        vm.expectEmit();
        emit CoverWithdrawn(1000e6);

        wrappedPoolConfiguratorProxy.withdrawCover(1000e6, address(users.caller));
        vm.stopPrank();

        assertEq(wrappedPoolConfiguratorProxy.totalAssets(), 0);
        assertEq(wrappedPoolConfiguratorProxy.poolCover(), 0);
    }

    function test_withdrawCover_InsufficientCover() public {
        _depositCover(1000e6);
        assertEq(wrappedPoolConfiguratorProxy.totalAssets(), 1000e6);
        assertEq(wrappedPoolConfiguratorProxy.poolCover(), 1000e6);

        // set minCoverAmount to 2000e6
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setMinCoverAmount(address(wrappedPoolConfiguratorProxy), 2000e6);

        vm.startPrank(users.pool_admin);
        vm.expectRevert(Errors.PoolConfigurator_InsufficientCover.selector);

        wrappedPoolConfiguratorProxy.withdrawCover(1000e6, address(users.caller));
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_exposed_withdrawalManager() public {
        assertEq(poolConfiguratorHarness.exposed_withdrawalManager(), address(wrappedWithdrawalManagerProxy));
    }

    function test_exposed_globals() public {
        assertEq(poolConfiguratorHarness.exposed_globals(), address(wrappedLopoGlobalsProxy));
    }

    function test_exposed_loanManager() public {
        assertEq(poolConfiguratorHarness.exposed_loanManager(), address(wrappedLoanManagerProxy));
    }

    function test_exposed_governor() public {
        assertEq(poolConfiguratorHarness.exposed_governor(), address(users.governor));
    }

    // since _revertIfPaused use msg.sig to get the function selector
    // we can't test it directly. Instead, we'll call the function which will
    // trigger the modifier whenNotPaused to test it.
    function test_revertIfPaused() public {
        // case1: protocol paused
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setProtocolPause(true);

        vm.expectRevert(Errors.PoolConfigurator_Paused.selector);

        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setOpenToPublic(true);

        // case2: protocol not paused, but contract paused
        vm.startPrank(users.governor);
        wrappedLopoGlobalsProxy.setProtocolPause(false);
        wrappedLopoGlobalsProxy.setContractPause(address(wrappedPoolConfiguratorProxy), true);
        vm.stopPrank();

        vm.expectRevert(Errors.PoolConfigurator_Paused.selector);

        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setOpenToPublic(true);

        // case3: protocol or contract paused, but function unpaused
        vm.startPrank(users.governor);
        wrappedLopoGlobalsProxy.setProtocolPause(true);
        wrappedLopoGlobalsProxy.setContractPause(address(wrappedPoolConfiguratorProxy), true);
        wrappedLopoGlobalsProxy.setFunctionUnpause(
            address(wrappedPoolConfiguratorProxy), wrappedPoolConfiguratorProxy.setOpenToPublic.selector, true
        );

        vm.expectEmit();
        emit OpenToPublic(true);

        changePrank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setOpenToPublic(true);
    }

    function test_revertIfNotPoolAdmin() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidCaller.selector, users.caller, users.pool_admin));

        vm.prank(users.caller);
        wrappedPoolConfiguratorProxy.setPendingPoolAdmin(address(users.caller));
    }

    function test_revertIfNotPoolAdminOrGovernor() public {
        // not pool admin & not governor -> revert

        vm.expectRevert(Errors.PoolConfigurator_NotPoolAdminOrGovernor.selector);
        vm.prank(users.caller);
        wrappedPoolConfiguratorProxy.triggerDefault(0);
    }

    function test_revertIfNotPool() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidCaller.selector, users.caller, address(pool)));

        vm.prank(users.caller);
        wrappedPoolConfiguratorProxy.processRedeem(1000e6, address(users.receiver), address(users.caller));
    }

    function test_exposed_hasSufficientCover() public {
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setMinCoverAmount(address(poolConfiguratorHarness), 10_000e6);

        assertFalse(poolConfiguratorHarness.exposed_hasSufficientCover(address(wrappedLopoGlobalsProxy)));
    }

    function test_exposed_handleCover() public {
        // case1: available cover > losses -> coverAmount = losses = 300e6
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setMaxCoverLiquidationPercent(address(poolConfiguratorHarness), 0.5e6);

        // in poolConfiguratorHarness, the pool admin is users.caller
        _depositCoverHarness(1000e6);
        assertEq(poolConfiguratorHarness.poolCover(), 1000e6);

        vm.expectEmit();
        emit CoverLiquidated(300e6);

        vm.prank(users.caller);
        poolConfiguratorHarness.exposed_handleCover(300e6);

        assertEq(poolConfiguratorHarness.totalAssets(), 1000e6);
        assertEq(poolConfiguratorHarness.poolCover(), 1000e6 - 300e6);

        // case2: available cover < losses -> coverAmount = availableCover = 350e6
        vm.expectEmit();
        emit CoverLiquidated(350e6);

        vm.prank(users.caller);
        poolConfiguratorHarness.exposed_handleCover(500e6);

        assertEq(poolConfiguratorHarness.totalAssets(), 1000e6);
        assertEq(poolConfiguratorHarness.poolCover(), 1000e6 - 300e6 - 350e6);
    }

    function test_exposed_min() public {
        assertEq(poolConfiguratorHarness.exposed_min(1000e6, 2000e6), 1000e6);
        assertEq(poolConfiguratorHarness.exposed_min(2000e6, 1000e6), 1000e6);
    }

    function test_exposed_getMaxAssets() public {
        // onboard users.receiver to the poolConfiguratorHarness as a lender
        vm.prank(users.caller);
        poolConfiguratorHarness.setValidLender(address(users.receiver), true);
        assertTrue(poolConfiguratorHarness.isLender(address(users.receiver)));

        vm.prank(users.caller);
        poolConfiguratorHarness.setLiquidityCap(1000e6);

        // case1: liquidityCap > totalAssets -> maxAssets = liquidityCap - totalAssets
        uint256 totalAssets = poolConfiguratorHarness.totalAssets();
        assertEq(poolConfiguratorHarness.exposed_getMaxAssets(address(users.receiver), totalAssets), 1000e6);

        // deposit 600e6 asset to the pool, and setLiquidityCap to 300e6
        _airdropToPoolHarness(600e6);
        assertEq(totalAssets = poolConfiguratorHarness.totalAssets(), 600e6);
        assertEq(poolConfiguratorHarness.exposed_getMaxAssets(address(users.receiver), totalAssets), 1000e6 - 600e6);

        vm.prank(users.caller);
        poolConfiguratorHarness.setLiquidityCap(300e6);

        // case2: liquidityCap < totalAssets -> maxAssets = 0

        assertEq(poolConfiguratorHarness.exposed_getMaxAssets(address(users.receiver), totalAssets), 0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _setOpenToPublicTrue() internal {
        vm.prank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setOpenToPublic(true);
    }

    function _depositCover(uint256 amount) internal {
        vm.startPrank(users.pool_admin);
        usdc.approve(address(wrappedPoolConfiguratorProxy), amount);
        wrappedPoolConfiguratorProxy.depositCover(amount);
        vm.stopPrank();
    }

    function _depositCoverHarness(uint256 amount) internal {
        vm.startPrank(users.caller);
        usdc.approve(address(poolConfiguratorHarness), amount);
        poolConfiguratorHarness.depositCover(amount);
        vm.stopPrank();
    }

    function _airdropToPoolHarness(uint256 amount) internal {
        usdc.mint(address(poolHarness), amount);
    }

    function _setUpPoolConfiguratorHarness() internal {
        vm.startPrank(users.governor);
        wrappedLopoGlobalsProxy.setValidPoolAdmin(address(users.caller), true);

        poolConfiguratorHarness = new PoolConfiguratorHarness(poolAddressesProvider);
        poolConfiguratorHarness.initialize(
            IPoolAddressesProvider(address(poolAddressesProvider)),
            address(usdc),
            users.caller,
            "BSOS Green Share",
            "BGS"
        );
        poolHarness = IPool(poolConfiguratorHarness.getPool());
        vm.stopPrank();
    }
}

/*//////////////////////////////////////////////////////////////////////////
                                HARNESS CONTRACT
//////////////////////////////////////////////////////////////////////////*/

contract PoolConfiguratorHarness is PoolConfigurator {
    IPool public poolHarness;

    constructor(IPoolAddressesProvider provider_) PoolConfigurator(IPoolAddressesProvider(provider_)) { }

    function exposed_withdrawalManager() external view returns (address withdrawalManager_) {
        return super._withdrawalManager();
    }

    function exposed_globals() external view returns (address globals_) {
        return super._globals();
    }

    function exposed_loanManager() external view returns (address loanManager_) {
        return super._loanManager();
    }

    function exposed_governor() external view returns (address governor_) {
        return super._governor();
    }

    function exposed_hasSufficientCover(address globals_) external view returns (bool hasSufficientCover_) {
        return super._hasSufficientCover(globals_);
    }

    function exposed_handleCover(uint256 losses_) external {
        super._handleCover(losses_);
    }

    function exposed_min(uint256 a, uint256 b) external pure returns (uint256 min_) {
        return super._min(a, b);
    }

    function exposed_getMaxAssets(address receiver_, uint256 totalAssets_) external view returns (uint256 maxAssets_) {
        return super._getMaxAssets(receiver_, totalAssets_);
    }
}

// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.19;

// import { console } from "@forge-std/console.sol";
// import { UD60x18, ud } from "@prb/math/UD60x18.sol";

// import { Errors } from "contracts/libraries/Errors.sol";

// import { IPoolAddressesProvider } from "contracts/interfaces/IPoolAddressesProvider.sol";
// import { IPoolConfiguratorEvents } from "contracts/interfaces/pool/IPoolConfiguratorEvents.sol";
// import { IPool } from "contracts/interfaces/IPool.sol";

// import { PoolConfigurator } from "contracts/PoolConfigurator.sol";
// import { Integration_Test } from "../../Integration.t.sol";

// contract PoolConfiguratorTest is Integration_Test, IPoolConfiguratorEvents {
//     uint256 internal _delta_ = 1e6;

//     PoolConfiguratorHarness internal poolConfiguratorHarness;
//     IPool internal poolHarness;

//     /*//////////////////////////////////////////////////////////////////////////
//                                 SET-UP FUNCTION
//     //////////////////////////////////////////////////////////////////////////*/

//     function setUp() public override(Integration_Test) {
//         Integration_Test.setUp();
//         _setUpPoolConfiguratorHarness();
//     }

//     /*//////////////////////////////////////////////////////////////////////////
//                                 TEST FUNCTIONS
//     //////////////////////////////////////////////////////////////////////////*/

//     function test_hasSufficientCover_True() public {
//         assertTrue(poolConfigurator.hasSufficientCover());
//     }

//     function test_hasSufficientCover_False() public {
//         vm.prank(users.governor);
//         lopoGlobals.setMinCoverAmount(address(poolConfigurator), 10_000e6);

//         assertFalse(poolConfigurator.hasSufficientCover());
//     }

//     // TODO: try to integrate with LoanManager
//     function test_totalAssets() public {
//         uint256 totalAssets = poolConfigurator.totalAssets();
//         assertEq(totalAssets, 0);

//         _callerDepositToReceiver(users.caller, users.receiver, 1000e6);
//         totalAssets = poolConfigurator.totalAssets();
//         assertEq(totalAssets, 1000e6);
//     }

//     function test_convertToExitShares() public {
//         uint256 exitShares = poolConfigurator.convertToExitShares(1000e6);
//         assertEq(exitShares, 1000e6);

//         _callerDepositToReceiver(users.caller, users.receiver, 1_000_000e6);
//         _airdropToPool(50_000e6);
//         exitShares = pool.convertToExitShares(1000e6);
//         // in exit case, we need to consider the unrealizedLosses
//         UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 - 0e6 + 1));
//         assertAlmostEq(exitShares, result.intoUint256(), _delta_);
//     }

//     // TODO: complete this test after implementing loanManager
//     function test_getEscrowParams() public { }

//     // TODO: complete this test after implementing loanManager
//     function test_unrealizedLosses() public { }

//     function test_setPendingPoolAdmin() public {
//         vm.expectEmit(true, true, true, true);
//         emit PendingPoolAdminSet(address(users.poolAdmin), address(users.caller));

//         vm.prank(users.poolAdmin);
//         poolConfigurator.setPendingPoolAdmin(address(users.caller));

//         assertEq(poolConfigurator.pendingPoolAdmin(), address(users.caller));
//     }

//     function test_acceptPoolAdmin() public {
//         vm.startPrank(users.poolAdmin);
//         poolConfigurator.setPendingPoolAdmin(address(users.receiver));
//         assertEq(poolConfigurator.pendingPoolAdmin(), address(users.receiver));

//         // transfer admin to an invalid pool admin
//         vm.startPrank(users.receiver);
//         vm.expectRevert();
//         poolConfigurator.acceptPoolAdmin();
//         vm.stopPrank();

//         // transfer admin to a valid pool admin
//         vm.prank(users.governor);
//         lopoGlobals.setValidPoolAdmin(address(users.receiver), true);

//         vm.expectEmit(true, true, true, true);
//         emit PendingPoolAdminAccepted(address(users.poolAdmin), address(users.receiver));

//         vm.prank(users.receiver);
//         poolConfigurator.acceptPoolAdmin();

//         assertEq(poolConfigurator.poolAdmin(), address(users.receiver));
//     }

//     function test_setValidBuyer() public {
//         assertTrue(poolConfigurator.isBuyer(address(users.buyer)));

//         vm.expectEmit(true, true, true, true);
//         emit ValidBuyerSet(address(users.buyer), false);

//         vm.prank(users.poolAdmin);
//         poolConfigurator.setValidBuyer(address(users.buyer), false);

//         assertFalse(poolConfigurator.isBuyer(address(users.buyer)));
//     }

//     function test_setValidLender() public {
//         assertTrue(poolConfigurator.isLender(address(users.receiver)));

//         vm.expectEmit(true, true, true, true);
//         emit ValidLenderSet(address(users.receiver), false);

//         vm.prank(users.poolAdmin);
//         poolConfigurator.setValidLender(address(users.receiver), false);

//         assertFalse(poolConfigurator.isLender(address(users.receiver)));
//     }

//     function test_setLiquidityCap() public {
//         assertEq(poolConfigurator.liquidityCap(), 1_000_000e6);

//         vm.expectEmit(true, true, true, true);
//         emit LiquidityCapSet(1_500_000e6);

//         vm.prank(users.poolAdmin);
//         poolConfigurator.setLiquidityCap(1_500_000e6);

//         assertEq(poolConfigurator.liquidityCap(), 1_500_000e6);
//     }

//     function test_setOpenToPublic() public {
//         assertFalse(poolConfigurator.openToPublic());

//         vm.expectEmit(true, true, true, true);
//         emit OpenToPublic(true);

//         vm.prank(users.poolAdmin);
//         poolConfigurator.setOpenToPublic(true);

//         assertTrue(poolConfigurator.openToPublic());
//     }

//     // TODO: complete this test after implementing withdrawalManager
//     function test_requestFunds() public { }

//     // TODO: complete this test after implementing loanManager
//     function test_triggerDefault() public { }

//     // TODO: complete this test after implementing withdrawalManager
//     function test_processRedeem() public { }

//     function test_processWithdraw() public {
//         // withdraw is not implemented, it'll always revert
//         vm.expectRevert(Errors.PoolConfigurator_WithdrawalNotImplemented.selector);

//         vm.prank(address(pool));
//         poolConfigurator.processWithdraw(1000e6, address(users.receiver), address(users.caller));
//     }

//     // TODO: complete this test after implementing withdrawalManager
//     function test_removeShares() public { }

//     //TODO: complete this test after implementing withdrawalManager
//     function test_requestRedeem() public { }

//     function test_requestWithdraw() public {
//         // withdraw is not implemented, it'll always revert
//         vm.expectRevert(Errors.PoolConfigurator_WithdrawalNotImplemented.selector);

//         vm.prank(address(pool));
//         poolConfigurator.requestWithdraw(1000e6, 1000e6, address(users.receiver), address(users.caller));
//     }

//     function test_depositCover() public {
//         vm.startPrank(users.poolAdmin);
//         usdc.approve(address(poolConfigurator), 1000e6);

//         vm.expectEmit();
//         emit CoverDeposited(1000e6);

//         poolConfigurator.depositCover(1000e6);
//         vm.stopPrank();

//         assertEq(poolConfigurator.totalAssets(), 0);
//         assertEq(poolConfigurator.poolCover(), 1000e6);

//         _airdropToPool(500e6);
//         assertEq(poolConfigurator.totalAssets(), 500e6);
//     }

//     function test_withdrawCover_SufficientCover() public {
//         _depositCover(1000e6);
//         assertEq(poolConfigurator.poolCover(), 1000e6);

//         vm.startPrank(users.poolAdmin);

//         vm.expectEmit();
//         emit CoverWithdrawn(1000e6);

//         poolConfigurator.withdrawCover(1000e6, address(users.caller));
//         vm.stopPrank();

//         assertEq(poolConfigurator.poolCover(), 0);
//     }

//     function test_withdrawCover_InsufficientCover() public {
//         _depositCover(1000e6);
//         assertEq(poolConfigurator.poolCover(), 1000e6);

//         // set minCoverAmount to 2000e6
//         vm.prank(users.governor);
//         lopoGlobals.setMinCoverAmount(address(poolConfigurator), 2000e6);

//         vm.startPrank(users.poolAdmin);
//         vm.expectRevert(Errors.PoolConfigurator_InsufficientCover.selector);

//         poolConfigurator.withdrawCover(1000e6, address(users.caller));
//         vm.stopPrank();
//     }

//     /*//////////////////////////////////////////////////////////////////////////
//                                 INTERNAL FUNCTIONS
//     //////////////////////////////////////////////////////////////////////////*/

//     function test_exposed_withdrawalManager() public {
//         assertEq(poolConfiguratorHarness.exposed_withdrawalManager(), address(withdrawalManager));
//     }

//     function test_exposed_globals() public {
//         assertEq(poolConfiguratorHarness.exposed_globals(), address(lopoGlobals));
//     }

//     function test_exposed_loanManager() public {
//         assertEq(poolConfiguratorHarness.exposed_loanManager(), address(loanManager));
//     }

//     function test_exposed_governor() public {
//         assertEq(poolConfiguratorHarness.exposed_governor(), address(users.governor));
//     }

//     // since _revertIfPaused use msg.sig to get the function selector
//     // we can't test it directly. Instead, we'll call the function which will
//     // trigger the modifier whenNotPaused to test it.
//     function test_revertIfPaused() public {
//         // case1: protocol paused
//         vm.prank(users.governor);
//         lopoGlobals.setProtocolPause(true);

//         vm.expectRevert(Errors.PoolConfigurator_Paused.selector);

//         vm.prank(users.poolAdmin);
//         poolConfigurator.setOpenToPublic(true);

//         // case2: protocol not paused, but contract paused
//         vm.startPrank(users.governor);
//         lopoGlobals.setProtocolPause(false);
//         lopoGlobals.setContractPause(address(poolConfigurator), true);
//         vm.stopPrank();

//         vm.expectRevert(Errors.PoolConfigurator_Paused.selector);

//         vm.prank(users.poolAdmin);
//         poolConfigurator.setOpenToPublic(true);

//         // case3: protocol or contract paused, but function unpaused
//         vm.startPrank(users.governor);
//         lopoGlobals.setProtocolPause(true);
//         lopoGlobals.setContractPause(address(poolConfigurator), true);
//         lopoGlobals.setFunctionUnpause(
//             address(poolConfigurator), poolConfigurator.setOpenToPublic.selector, true
//         );

//         vm.expectEmit();
//         emit OpenToPublic(true);

//         vm.startPrank(users.poolAdmin);
//         poolConfigurator.setOpenToPublic(true);
//     }

//     function test_revertIfNotPoolAdmin() public {
//         vm.expectRevert(abi.encodeWithSelector(Errors.InvalidCaller.selector, users.caller, users.poolAdmin));

//         vm.prank(users.caller);
//         poolConfigurator.setPendingPoolAdmin(address(users.caller));
//     }

//     function test_revertIfNotPoolAdminOrGovernor() public {
//         // not pool admin & not governor -> revert

//         vm.expectRevert(Errors.PoolConfigurator_NotPoolAdminOrGovernor.selector);
//         vm.prank(users.caller);
//         poolConfigurator.triggerDefault(0);
//     }

//     function test_revertIfNotPool() public {
//         vm.expectRevert(abi.encodeWithSelector(Errors.InvalidCaller.selector, users.caller, address(pool)));

//         vm.prank(users.caller);
//         poolConfigurator.processRedeem(1000e6, address(users.receiver), address(users.caller));
//     }

//     function test_exposed_hasSufficientCover() public {
//         vm.prank(users.governor);
//         lopoGlobals.setMinCoverAmount(address(poolConfiguratorHarness), 10_000e6);

//         assertFalse(poolConfiguratorHarness.exposed_hasSufficientCover(address(lopoGlobals)));
//     }

//     function test_exposed_handleCover() public {
//         // case1: available cover > losses -> coverAmount = losses = 300e6
//         vm.prank(users.governor);
//         lopoGlobals.setMaxCoverLiquidationPercent(address(poolConfiguratorHarness), 0.5e6);

//         // in poolConfiguratorHarness, the pool admin is users.caller
//         _depositCoverHarness(1000e6);
//         assertEq(poolConfiguratorHarness.poolCover(), 1000e6);

//         vm.expectEmit();
//         emit CoverLiquidated(300e6);

//         vm.prank(users.caller);
//         poolConfiguratorHarness.exposed_handleCover(300e6);

//         assertEq(poolConfiguratorHarness.poolCover(), 1000e6 - 300e6);

//         // case2: available cover < losses -> coverAmount = availableCover = 350e6
//         vm.expectEmit();
//         emit CoverLiquidated(350e6);

//         vm.prank(users.caller);
//         poolConfiguratorHarness.exposed_handleCover(500e6);

//         assertEq(poolConfiguratorHarness.totalAssets(), 300e6 + 350e6);
//         assertEq(poolConfiguratorHarness.poolCover(), 1000e6 - 300e6 - 350e6);
//     }

//     function test_exposed_min() public {
//         assertEq(poolConfiguratorHarness.exposed_min(1000e6, 2000e6), 1000e6);
//         assertEq(poolConfiguratorHarness.exposed_min(2000e6, 1000e6), 1000e6);
//     }

//     function test_exposed_getMaxAssets() public {
//         // onboard users.receiver to the poolConfiguratorHarness as a lender
//         vm.prank(users.caller);
//         poolConfiguratorHarness.setValidLender(address(users.receiver), true);
//         assertTrue(poolConfiguratorHarness.isLender(address(users.receiver)));

//         vm.prank(users.caller);
//         poolConfiguratorHarness.setLiquidityCap(1000e6);

//         // case1: liquidityCap > totalAssets -> maxAssets = liquidityCap - totalAssets
//         uint256 totalAssets = poolConfiguratorHarness.totalAssets();
//         assertEq(poolConfiguratorHarness.exposed_getMaxAssets(address(users.receiver), totalAssets), 1000e6);

//         // deposit 600e6 asset to the pool, and setLiquidityCap to 300e6
//         _airdropToPoolHarness(600e6);
//         assertEq(totalAssets = poolConfiguratorHarness.totalAssets(), 600e6);
//         assertEq(poolConfiguratorHarness.exposed_getMaxAssets(address(users.receiver), totalAssets), 1000e6 - 600e6);

//         vm.prank(users.caller);
//         poolConfiguratorHarness.setLiquidityCap(300e6);

//         // case2: liquidityCap < totalAssets -> maxAssets = 0

//         assertEq(poolConfiguratorHarness.exposed_getMaxAssets(address(users.receiver), totalAssets), 0);
//     }

//     /*//////////////////////////////////////////////////////////////////////////
//                                 HELPER FUNCTIONS
//     //////////////////////////////////////////////////////////////////////////*/

//     function _setOpenToPublicTrue() internal {
//         vm.prank(users.poolAdmin);
//         poolConfigurator.setOpenToPublic(true);
//     }

//     function _depositCover(uint256 amount) internal {
//         vm.startPrank(users.poolAdmin);
//         usdc.approve(address(poolConfigurator), amount);
//         poolConfigurator.depositCover(amount);
//         vm.stopPrank();
//     }

//     function _depositCoverHarness(uint256 amount) internal {
//         vm.startPrank(users.caller);
//         usdc.approve(address(poolConfiguratorHarness), amount);
//         poolConfiguratorHarness.depositCover(amount);
//         vm.stopPrank();
//     }

//     function _airdropToPoolHarness(uint256 amount) internal {
//         deal({ token: address(usdc), give: amount, to: address(poolHarness), adjust: true });
//     }

//     function _airdropToPool(uint256 amount_) internal {
//         airdropTo(address(pool), amount_);
//     }

//     function _setUpPoolConfiguratorHarness() internal {
//         vm.startPrank(users.governor);
//         lopoGlobals.setValidPoolAdmin(address(users.caller), true);

//         poolConfiguratorHarness = new PoolConfiguratorHarness(poolAddressesProvider);
//         poolConfiguratorHarness.initialize(
//             IPoolAddressesProvider(address(poolAddressesProvider)),
//             address(usdc),
//             users.caller,
//             "BSOS Green Share",
//             "BGS"
//         );
//         poolHarness = IPool(poolConfiguratorHarness.pool());
//         vm.stopPrank();
//     }
// }

// /*//////////////////////////////////////////////////////////////////////////
//                                 HARNESS CONTRACT
// //////////////////////////////////////////////////////////////////////////*/

// contract PoolConfiguratorHarness is PoolConfigurator {
//     IPool public poolHarness;

//     constructor(IPoolAddressesProvider provider_) PoolConfigurator(IPoolAddressesProvider(provider_)) { }

//     function exposed_withdrawalManager() external view returns (address withdrawalManager_) {
//         return super._withdrawalManager();
//     }

//     function exposed_globals() external view returns (address globals_) {
//         return super._globals();
//     }

//     function exposed_loanManager() external view returns (address loanManager_) {
//         return super._loanManager();
//     }

//     function exposed_governor() external view returns (address governor_) {
//         return super._governor();
//     }

//     function exposed_hasSufficientCover(address globals_) external view returns (bool hasSufficientCover_) {
//         return super._hasSufficientCover(globals_);
//     }

//     function exposed_handleCover(uint256 losses_) external {
//         super._handleCover(losses_);
//     }

//     function exposed_min(uint256 a, uint256 b) external pure returns (uint256 min_) {
//         return super._min(a, b);
//     }

//     function exposed_getMaxAssets(address receiver_, uint256 totalAssets_) external view returns (uint256 maxAssets_)
// {
//         return super._getMaxAssets(receiver_, totalAssets_);
//     }
// }

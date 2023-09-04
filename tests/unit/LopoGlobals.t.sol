// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";

import { ILopoGlobalsEvents } from "../../contracts/interfaces/ILopoGlobalsEvents.sol";
import { MockLopoGlobalsV2 } from "../mocks/MockLopoGlobalsV2.sol";
import { Address } from "../accounts/Address.sol";

import { Base_Test } from "../Base.t.sol";

contract LopoGlobalsTest is Base_Test, ILopoGlobalsEvents {
//     uint256 public constant HUNDRED_PERCENT = 1_000_000; // 100.0000%

//     uint256 internal constant PROTOCOL_FEE = 5 * HUNDRED_PERCENT / 1000; // 0.5%
//     address internal governorV2;

//     function setUp() public override {
//         super.setUp();
//         governorV2 = createUser("GovernorV2");
//     }

//     function test_canUpgrade() public {
//         MockLopoGlobalsV2 globalsV2 = new MockLopoGlobalsV2();

//         /**
//          * only the governor can call upgradeTo()
//          * upgradeTo() has a onlyProxy mpdifier, and calls _authorizeUpgrade()
//          * _authorizeUpgrade() has a onlyGovernor modifier, which implements in LopoGlobals
//          */

//         changePrank(users.governor);
//         lopoGlobals.upgradeTo(address(globalsV2));

//         // re-wrap the proxy to the new implementation
//         MockLopoGlobalsV2 lopoGlobalsV2 = MockLopoGlobalsV2(address(lopoGlobals));

//         assertEq(lopoGlobalsV2.governor(), users.governor);

//         // @notice: in our mock, we inherit from LopoGlobals
//         // which means the REVISON still = 0x1
//         // so we cannot do lopoGlobalsV2.initialize(governorV2)
//         vm.expectEmit(true, true, true, true);
//         emit PendingGovernorSet(governorV2);
//         changePrank(users.governor);
//         lopoGlobals.setPendingLopoGovernor(governorV2);

//         assertEq(lopoGlobals.pendingLopoGovernor(), governorV2);

//         vm.expectEmit(true, true, true, true);
//         emit GovernorshipAccepted(users.governor, governorV2);
//         changePrank(governorV2);
//         lopoGlobals.acceptLopoGovernor();
//         assertEq(lopoGlobals.governor(), governorV2);

//         // new function in mockV2
//         string memory text = lopoGlobalsV2.upgradeV2Test();
//         assertEq(text, "Hello World V2");
//     }

//     function test_setPendingLopoGovernor_acceptLopoGovernor() public {
//         vm.expectEmit(true, true, true, true);
//         emit PendingGovernorSet(governorV2);
//         changePrank(users.governor);
//         lopoGlobals.setPendingLopoGovernor(governorV2);

//         assertEq(lopoGlobals.pendingLopoGovernor(), governorV2);

//         vm.expectEmit(true, true, true, true);
//         emit GovernorshipAccepted(users.governor, governorV2);
//         changePrank(governorV2);
//         lopoGlobals.acceptLopoGovernor();
//         assertEq(lopoGlobals.governor(), governorV2);
//     }

//     function test_Revert_IfZeroAddress_setLopoVault() public {
//         vm.expectRevert(abi.encodeWithSelector(Errors.Globals_InvalidVault.selector, address(0)));
//         changePrank(users.governor);
//         lopoGlobals.setLopoVault(address(0));
//     }

//     function test_setProtocolPause() public {
//         vm.expectEmit(true, true, true, true);
//         emit ProtocolPauseSet(users.governor, true);
//         changePrank(users.governor);
//         lopoGlobals.setProtocolPause(true);
//         assertTrue(lopoGlobals.protocolPaused());
//     }

//     function test_setValidPoolAdmin_setPoolConfigurator_transferOwnedPoolConfigurator() public {
//         address mockPoolAdmin = address(new Address());
//         address mockNextPoolAdmin = address(new Address());
//         address mockPoolConfigurator = address(new Address());

//         // onboard the pool admin
//         vm.expectEmit(true, true, true, true);
//         emit ValidPoolAdminSet(mockPoolAdmin, true);
//         changePrank(users.governor);
//         lopoGlobals.setValidPoolAdmin(mockPoolAdmin, true);
//         assertEq(lopoGlobals.ownedPoolConfigurator(mockPoolAdmin), address(0));
//         assertEq(lopoGlobals.isPoolAdmin(mockPoolAdmin), true);

//         // set the pool configurator to the pool admin
//         vm.expectEmit(true, true, true, true);
//         emit PoolConfiguratorSet(mockPoolAdmin, mockPoolConfigurator);
//         changePrank(users.governor);
//         lopoGlobals.setPoolConfigurator(mockPoolAdmin, mockPoolConfigurator);
//         assertEq(lopoGlobals.ownedPoolConfigurator(mockPoolAdmin), mockPoolConfigurator);

//         // before onboard the next pool admin
//         assertTrue(!lopoGlobals.isPoolAdmin(mockNextPoolAdmin));
//         assertEq(lopoGlobals.ownedPoolConfigurator(mockNextPoolAdmin), address(0));
//         // onboard the next pool admin
//         changePrank(users.governor);
//         lopoGlobals.setValidPoolAdmin(mockNextPoolAdmin, true);
//         assertTrue(lopoGlobals.isPoolAdmin(mockNextPoolAdmin));

//         // transfer the pool configurator from the pool admin to the next pool admin
//         vm.expectEmit(true, true, true, true);
//         emit PoolConfiguratorOwnershipTransferred(mockPoolAdmin, mockNextPoolAdmin, mockPoolConfigurator);
//         changePrank(mockPoolConfigurator);
//         lopoGlobals.transferOwnedPoolConfigurator(mockPoolAdmin, mockNextPoolAdmin);
//         assertEq(lopoGlobals.ownedPoolConfigurator(mockPoolAdmin), address(0));
//         assertEq(lopoGlobals.ownedPoolConfigurator(mockNextPoolAdmin), mockPoolConfigurator);
//         assertTrue(lopoGlobals.isPoolAdmin(mockPoolAdmin));
//         assertTrue(lopoGlobals.isPoolAdmin(mockNextPoolAdmin));
//     }

//     function test_setValidCollateralAsset() public {
//         address mockCollateralAsset = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit ValidCollateralAssetSet(mockCollateralAsset, true);
//         changePrank(users.governor);
//         lopoGlobals.setValidCollateralAsset(mockCollateralAsset, true);
//         assertTrue(lopoGlobals.isCollateralAsset(mockCollateralAsset));
//         assertFalse(lopoGlobals.isCollateralAsset(users.seller));
//     }

//     function test_setValidPoolAsset() public {
//         address mockPoolAsset = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit ValidPoolAssetSet(mockPoolAsset, true);
//         changePrank(users.governor);
//         lopoGlobals.setValidPoolAsset(mockPoolAsset, true);
//         assertTrue(lopoGlobals.isPoolAsset(mockPoolAsset));
//         assertFalse(lopoGlobals.isPoolAsset(users.seller));
//     }

//     function test_setRiskFreeRate() public {
//         uint256 newRiskFreeRate_ = 5 * HUNDRED_PERCENT;
//         vm.expectEmit(true, true, true, true);

//         emit RiskFreeRateSet(newRiskFreeRate_);
//         changePrank(users.governor);
//         lopoGlobals.setRiskFreeRate(newRiskFreeRate_);
//         assertEq(lopoGlobals.riskFreeRate(), newRiskFreeRate_);
//     }

//     function test_setMinPoolLiquidityRatio() public {
//         vm.expectEmit(true, true, true, true);
//         emit MinPoolLiquidityRatioSet(0.05e18);
//         changePrank(users.governor);
//         lopoGlobals.setMinPoolLiquidityRatio(ud(0.05e18));
//         assertEq(lopoGlobals.minPoolLiquidityRatio().intoUint256(), 0.05e18);
//     }

//     function test_setProtocolFeeRate() public {
//         address POOL_ADDRESS = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit ProtocolFeeRateSet(POOL_ADDRESS, PROTOCOL_FEE);
//         changePrank(users.governor);
//         lopoGlobals.setProtocolFeeRate(POOL_ADDRESS, PROTOCOL_FEE);
//         assertEq(lopoGlobals.protocolFeeRate(POOL_ADDRESS), PROTOCOL_FEE);
//     }

//     function test_setMinDepositLimit() public {
//         address mockPoolConfigurator = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit MinDepositLimitSet(mockPoolConfigurator, 100e18);
//         changePrank(users.governor);
//         lopoGlobals.setMinDepositLimit(mockPoolConfigurator, ud(100e18));
//         assertEq(lopoGlobals.minDepositLimit(mockPoolConfigurator).intoUint256(), 100e18);
//     }

//     function test_setWithdrawalDurationInDays() public {
//         address mockPoolConfigurator = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit WithdrawalDurationInDaysSet(mockPoolConfigurator, 30);
//         changePrank(users.governor);
//         lopoGlobals.setWithdrawalDurationInDays(mockPoolConfigurator, 30);
//         assertEq(lopoGlobals.withdrawalDurationInDays(mockPoolConfigurator), 30);
//     }
}

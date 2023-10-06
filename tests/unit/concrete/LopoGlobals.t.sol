// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import { UD60x18, ud } from "@prb/math/UD60x18.sol";
// import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

// import { Errors } from "../../../contracts/libraries/Errors.sol";

// import { IIsleGlobalsEvents } from "../../../contracts/interfaces/IIsleGlobalsEvents.sol";

// import { MockIsleGlobalsV2 } from "../../mocks/MockIsleGlobalsV2.sol";

// import { Address } from "../../accounts/Address.sol";

// import { Base_Test } from "../../Base.t.sol";

// contract IsleGlobals_Unit_Concrete_Test is Base_Test, IIsleGlobalsEvents {
//     uint256 public constant HUNDRED_PERCENT = 1_000_000; // 100.0000%

//     uint256 internal constant PROTOCOL_FEE = 5 * HUNDRED_PERCENT / 1000; // 0.5%
//     address internal governorV2;

//     function setUp() public virtual override(Base_Test) {
//         Base_Test.setUp();

//         changePrank(users.governor);
//         deployGlobals();

//         governorV2 = createUser("GovernorV2");
//     }

//     function test_canUpgrade() public {
//         /**
//          * only the governor can call upgradeTo()
//          * upgradeTo() has a onlyProxy mpdifier, and calls _authorizeUpgrade()
//          * _authorizeUpgrade() has a onlyGovernor modifier, which is implemented in IsleGlobals
//          */

//         MockIsleGlobalsV2 globalsImplV2 = new MockIsleGlobalsV2();
//         UUPSUpgradeable(address(isleGlobals)).upgradeTo(address(globalsImplV2));

//         // re-wrap the proxy to the new implementation
//         MockIsleGlobalsV2 isleGlobalsV2 = MockIsleGlobalsV2(address(isleGlobals));

//         assertEq(isleGlobalsV2.governor(), users.governor);

//         // @notice: in our mock, we inherit from IsleGlobals
//         // which means the REVISON still = 0x1
//         // so we cannot do isleGlobalsV2.initialize(governorV2)
//         vm.expectEmit(true, true, true, true);
//         emit PendingGovernorSet(governorV2);
//         isleGlobals.setPendingIsleGovernor(governorV2);

//         assertEq(isleGlobals.pendingIsleGovernor(), governorV2);

//         vm.expectEmit(true, true, true, true);
//         emit GovernorshipAccepted(users.governor, governorV2);

//         changePrank(governorV2);
//         isleGlobals.acceptIsleGovernor();

//         assertEq(isleGlobals.governor(), governorV2);

//         // new function in mockV2
//         string memory text = isleGlobalsV2.upgradeV2Test();
//         assertEq(text, "Hello World V2");
//     }

//     function test_setPendingIsleGovernor_acceptIsleGovernor() public {
//         vm.expectEmit(true, true, true, true);
//         emit PendingGovernorSet(governorV2);
//         isleGlobals.setPendingIsleGovernor(governorV2);

//         assertEq(isleGlobals.pendingIsleGovernor(), governorV2);

//         vm.expectEmit(true, true, true, true);
//         emit GovernorshipAccepted(users.governor, governorV2);

//         changePrank(governorV2);
//         isleGlobals.acceptIsleGovernor();
//         assertEq(isleGlobals.governor(), governorV2);
//     }

//     function test_Revert_IfZeroAddress_setIsleVault() public {
//         vm.expectRevert(abi.encodeWithSelector(Errors.Globals_InvalidVault.selector, address(0)));
//         isleGlobals.setIsleVault(address(0));
//     }

//     function test_setProtocolPause() public {
//         vm.expectEmit(true, true, true, true);
//         emit ProtocolPauseSet(users.governor, true);
//         isleGlobals.setProtocolPause(true);
//         assertTrue(isleGlobals.protocolPaused());
//     }

//     function test_setValidPoolAdmin_setPoolConfigurator_transferOwnedPoolConfigurator() public {
//         address mockPoolAdmin = address(new Address());
//         address mockNextPoolAdmin = address(new Address());
//         address mockPoolConfigurator = address(new Address());

//         // onboard the pool admin
//         vm.expectEmit(true, true, true, true);
//         emit ValidPoolAdminSet(mockPoolAdmin, true);
//         isleGlobals.setValidPoolAdmin(mockPoolAdmin, true);
//         assertEq(isleGlobals.ownedPoolConfigurator(mockPoolAdmin), address(0));
//         assertEq(isleGlobals.isPoolAdmin(mockPoolAdmin), true);

//         // set the pool configurator to the pool admin
//         vm.expectEmit(true, true, true, true);
//         emit PoolConfiguratorSet(mockPoolAdmin, mockPoolConfigurator);
//         isleGlobals.setPoolConfigurator(mockPoolAdmin, mockPoolConfigurator);
//         assertEq(isleGlobals.ownedPoolConfigurator(mockPoolAdmin), mockPoolConfigurator);

//         // before onboard the next pool admin
//         assertTrue(!isleGlobals.isPoolAdmin(mockNextPoolAdmin));
//         assertEq(isleGlobals.ownedPoolConfigurator(mockNextPoolAdmin), address(0));
//         // onboard the next pool admin
//         isleGlobals.setValidPoolAdmin(mockNextPoolAdmin, true);
//         assertTrue(isleGlobals.isPoolAdmin(mockNextPoolAdmin));

//         // transfer the pool configurator from the pool admin to the next pool admin
//         vm.expectEmit(true, true, true, true);
//         emit PoolConfiguratorOwnershipTransferred(mockPoolAdmin, mockNextPoolAdmin, mockPoolConfigurator);
//         changePrank(mockPoolConfigurator);
//         isleGlobals.transferOwnedPoolConfigurator(mockPoolAdmin, mockNextPoolAdmin);
//         assertEq(isleGlobals.ownedPoolConfigurator(mockPoolAdmin), address(0));
//         assertEq(isleGlobals.ownedPoolConfigurator(mockNextPoolAdmin), mockPoolConfigurator);
//         assertTrue(isleGlobals.isPoolAdmin(mockPoolAdmin));
//         assertTrue(isleGlobals.isPoolAdmin(mockNextPoolAdmin));
//     }

//     function test_setValidCollateralAsset() public {
//         address mockCollateralAsset = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit ValidCollateralAssetSet(mockCollateralAsset, true);
//         isleGlobals.setValidCollateralAsset(mockCollateralAsset, true);
//         assertTrue(isleGlobals.isCollateralAsset(mockCollateralAsset));
//         assertFalse(isleGlobals.isCollateralAsset(users.seller));
//     }

//     function test_setValidPoolAsset() public {
//         address mockPoolAsset = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit ValidPoolAssetSet(mockPoolAsset, true);
//         isleGlobals.setValidPoolAsset(mockPoolAsset, true);
//         assertTrue(isleGlobals.isPoolAsset(mockPoolAsset));
//         assertFalse(isleGlobals.isPoolAsset(users.seller));
//     }

//     function test_setRiskFreeRate() public {
//         uint256 newRiskFreeRate_ = 5 * HUNDRED_PERCENT;
//         vm.expectEmit(true, true, true, true);

//         emit RiskFreeRateSet(newRiskFreeRate_);
//         isleGlobals.setRiskFreeRate(newRiskFreeRate_);
//         assertEq(isleGlobals.riskFreeRate(), newRiskFreeRate_);
//     }

//     function test_setMinPoolLiquidityRatio() public {
//         vm.expectEmit(true, true, true, true);
//         emit MinPoolLiquidityRatioSet(0.05e18);
//         isleGlobals.setMinPoolLiquidityRatio(ud(0.05e18));
//         assertEq(isleGlobals.minPoolLiquidityRatio().intoUint256(), 0.05e18);
//     }

//     function test_setProtocolFeeRate() public {
//         address POOL_ADDRESS = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit ProtocolFeeRateSet(POOL_ADDRESS, PROTOCOL_FEE);
//         isleGlobals.setProtocolFeeRate(POOL_ADDRESS, PROTOCOL_FEE);
//         assertEq(isleGlobals.protocolFeeRate(POOL_ADDRESS), PROTOCOL_FEE);
//     }

//     function test_setMinDepositLimit() public {
//         address mockPoolConfigurator = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit MinDepositLimitSet(mockPoolConfigurator, 100e18);
//         isleGlobals.setMinDepositLimit(mockPoolConfigurator, ud(100e18));
//         assertEq(isleGlobals.minDepositLimit(mockPoolConfigurator).intoUint256(), 100e18);
//     }

//     function test_setWithdrawalDurationInDays() public {
//         address mockPoolConfigurator = address(new Address());
//         vm.expectEmit(true, true, true, true);
//         emit WithdrawalDurationInDaysSet(mockPoolConfigurator, 30);
//         isleGlobals.setWithdrawalDurationInDays(mockPoolConfigurator, 30);
//         assertEq(isleGlobals.withdrawalDurationInDays(mockPoolConfigurator), 30);
//     }
// }

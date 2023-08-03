// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "../contracts/libraries/Errors.sol";
import { MockLopoGlobalsV2 } from "./mocks/MockLopoGlobalsV2.sol";
import { ILopoGlobalsEvents } from "./utils/ILopoGlobalsEvents.sol";
import "./BaseTest.t.sol";

contract LopoGlobalsTest is BaseTest, ILopoGlobalsEvents {
    MockLopoGlobalsV2 globalsV2;
    MockLopoGlobalsV2 wrappedLopoProxyV2;

    address GOVERNORV2;

    function setUp() public override {
        super.setUp();

        GOVERNORV2 = ACCOUNTS[3];

        vm.prank(DEFAULT_GOVERNOR);
        wrappedLopoProxyV1.setValidBuyer(DEFAULT_BUYER, true);
    }

    function test_canUpgrade() public {
        globalsV2 = new MockLopoGlobalsV2();

        /**
         * only the governor can call upgradeTo()
         * upgradeTo() has a onlyProxy mpdifier, and calls _authorizeUpgrade()
         * _authorizeUpgrade() has a onlyGovernor modifier, which implements in LopoGlobals
         */

        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.upgradeTo(address(globalsV2));

        // re-wrap the proxy to the new implementation
        wrappedLopoProxyV2 = MockLopoGlobalsV2(address(LopoProxy));

        assertEq(wrappedLopoProxyV2.governor(), DEFAULT_GOVERNOR);

        wrappedLopoProxyV2.initialize(GOVERNORV2);

        assertEq(wrappedLopoProxyV2.governor(), GOVERNORV2);

        assertTrue(wrappedLopoProxyV2.isBuyer(DEFAULT_BUYER));

        vm.prank(GOVERNORV2);
        assertFalse(wrappedLopoProxyV2.isBuyer(DEFAULT_SELLER));

        // new function in V2
        string memory text = wrappedLopoProxyV2.upgradeV2Test();
        assertEq(text, "Hello World V2");

        // change existing function in V2, let the logic of setValidBuyer() be reversed
        // if we set an adress to true, it will be false
        vm.prank(GOVERNORV2);
        wrappedLopoProxyV2.setValidBuyer(DEFAULT_BUYER, true);
        assertFalse(wrappedLopoProxyV2.isBuyer(DEFAULT_BUYER));
        vm.prank(GOVERNORV2);
        wrappedLopoProxyV2.setValidBuyer(DEFAULT_BUYER, false);
        assertTrue(wrappedLopoProxyV2.isBuyer(DEFAULT_BUYER));
    }

    function test_setPendingLopoGovernor_acceptLopoGovernor() public {
        vm.expectEmit(true, true, true, true);
        emit PendingGovernorSet(GOVERNORV2);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setPendingLopoGovernor(GOVERNORV2);

        assertEq(wrappedLopoProxyV1.pendingLopoGovernor(), GOVERNORV2);

        vm.expectEmit(true, true, true, true);
        emit GovernorshipAccepted(GOVERNOR, GOVERNORV2);
        vm.prank(GOVERNORV2);
        wrappedLopoProxyV1.acceptLopoGovernor();
        assertEq(wrappedLopoProxyV1.governor(), GOVERNORV2);
    }

    function test_Revert_IfZeroAddress_setLopoVault() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_InvalidVault.selector, address(0)));
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setLopoVault(address(0));
    }

    function test_setProtocolPause() public {
        vm.expectEmit(true, true, true, true);
        emit ProtocolPauseSet(GOVERNOR, true);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setProtocolPause(true);
        assertTrue(wrappedLopoProxyV1.protocolPaused());
    }

    function test_setValidPoolAdmin_setPoolConfigurator_transferOwnedPoolConfigurator() public {
        address mockPoolAdmin = ACCOUNTS[7];
        address mockNextPoolAdmin = ACCOUNTS[8];
        address mockPoolConfigurator = ACCOUNTS[9];

        // onboard the pool admin
        vm.expectEmit(true, true, true, true);
        emit ValidPoolAdminSet(mockPoolAdmin, true);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidPoolAdmin(mockPoolAdmin, true);
        assertEq(wrappedLopoProxyV1.ownedPoolConfigurator(mockPoolAdmin), address(0));
        assertEq(wrappedLopoProxyV1.isPoolAdmin(mockPoolAdmin), true);

        // set the pool configurator to the pool admin
        vm.expectEmit(true, true, true, true);
        emit PoolConfiguratorSet(mockPoolAdmin, mockPoolConfigurator);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setPoolConfigurator(mockPoolAdmin, mockPoolConfigurator);
        assertEq(wrappedLopoProxyV1.ownedPoolConfigurator(mockPoolAdmin), mockPoolConfigurator);

        // before onboard the next pool admin
        assertTrue(!wrappedLopoProxyV1.isPoolAdmin(mockNextPoolAdmin));
        assertEq(wrappedLopoProxyV1.ownedPoolConfigurator(mockNextPoolAdmin), address(0));
        // onboard the next pool admin
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidPoolAdmin(mockNextPoolAdmin, true);
        assertTrue(wrappedLopoProxyV1.isPoolAdmin(mockNextPoolAdmin));

        // transfer the pool configurator from the pool admin to the next pool admin
        vm.expectEmit(true, true, true, true);
        emit PoolConfiguratorOwnershipTransferred(mockPoolAdmin, mockNextPoolAdmin, mockPoolConfigurator);
        vm.prank(mockPoolConfigurator);
        wrappedLopoProxyV1.transferOwnedPoolConfigurator(mockPoolAdmin, mockNextPoolAdmin);
        assertEq(wrappedLopoProxyV1.ownedPoolConfigurator(mockPoolAdmin), address(0));
        assertEq(wrappedLopoProxyV1.ownedPoolConfigurator(mockNextPoolAdmin), mockPoolConfigurator);
        assertTrue(wrappedLopoProxyV1.isPoolAdmin(mockPoolAdmin));
        assertTrue(wrappedLopoProxyV1.isPoolAdmin(mockNextPoolAdmin));
    }

    function test_setValidReceivable() public {
        address mockReceivable = ACCOUNTS[9];
        vm.expectEmit(true, true, true, true);
        emit ValidReceivableSet(mockReceivable, true);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidReceivable(mockReceivable, true);
        assertTrue(wrappedLopoProxyV1.isReceivable(mockReceivable));
    }

    function test_setValidBorrower() public {
        address mockBorrower = ACCOUNTS[9];
        vm.expectEmit(true, true, true, true);
        emit ValidBorrowerSet(mockBorrower, true);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidBorrower(mockBorrower, true);
        assertTrue(wrappedLopoProxyV1.isBorrower(mockBorrower));
        assertFalse(wrappedLopoProxyV1.isBorrower(DEFAULT_BUYER));
    }

    function test_setValidBuyer() public {
        address mockBuyer = ACCOUNTS[9];
        vm.expectEmit(true, true, true, true);
        emit ValidBuyerSet(mockBuyer, true);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidBuyer(mockBuyer, true);
        assertTrue(wrappedLopoProxyV1.isBuyer(mockBuyer));
        assertFalse(wrappedLopoProxyV1.isBuyer(DEFAULT_SELLER));
    }

    function test_setValidCollateralAsset() public {
        address mockCollateralAsset = ACCOUNTS[9];
        vm.expectEmit(true, true, true, true);
        emit ValidCollateralAssetSet(mockCollateralAsset, true);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidCollateralAsset(mockCollateralAsset, true);
        assertTrue(wrappedLopoProxyV1.isCollateralAsset(mockCollateralAsset));
        assertFalse(wrappedLopoProxyV1.isCollateralAsset(DEFAULT_SELLER));
    }

    function test_setValidPoolAsset() public {
        address mockPoolAsset = ACCOUNTS[9];
        vm.expectEmit(true, true, true, true);
        emit ValidPoolAssetSet(mockPoolAsset, true);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidPoolAsset(mockPoolAsset, true);
        assertTrue(wrappedLopoProxyV1.isPoolAsset(mockPoolAsset));
        assertFalse(wrappedLopoProxyV1.isPoolAsset(DEFAULT_SELLER));
    }

    // notice: input of the function is UD60x18, but the event emits uint256
    function test_setRiskFreeRate() public {
        vm.expectEmit(true, true, true, true);
        emit RiskFreeRateSet(0.05e18);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setRiskFreeRate(ud(0.05e18));
        assertEq(wrappedLopoProxyV1.riskFreeRate().intoUint256(), 0.05e18);
    }

    function test_setMinPoolLiquidityRatio() public {
        vm.expectEmit(true, true, true, true);
        emit MinPoolLiquidityRatioSet(0.05e18);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setMinPoolLiquidityRatio(ud(0.05e18));
        assertEq(wrappedLopoProxyV1.minPoolLiquidityRatio().intoUint256(), 0.05e18);
    }

    function test_setProtocolFeeRate() public {
        vm.expectEmit(true, true, true, true);
        emit ProtocolFeeRateSet(0.005e18);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setProtocolFeeRate(ud(0.005e18));
        assertEq(wrappedLopoProxyV1.protocolFeeRate().intoUint256(), 0.005e18);
    }

    function test_setMinDepositLimit() public {
        address mockPoolConfigurator = ACCOUNTS[9];
        vm.expectEmit(true, true, true, true);
        emit MinDepositLimitSet(mockPoolConfigurator, 100e18);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setMinDepositLimit(mockPoolConfigurator, ud(100e18));
        assertEq(wrappedLopoProxyV1.minDepositLimit(mockPoolConfigurator).intoUint256(), 100e18);
    }

    function test_setWithdrawalDurationInDays() public {
        address mockPoolConfigurator = ACCOUNTS[9];
        vm.expectEmit(true, true, true, true);
        emit WithdrawalDurationInDaysSet(mockPoolConfigurator, 30);
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setWithdrawalDurationInDays(mockPoolConfigurator, 30);
        assertEq(wrappedLopoProxyV1.withdrawalDurationInDays(mockPoolConfigurator), 30);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "../../contracts/libraries/Errors.sol";
import { MockLopoGlobalsV2 } from "../mocks/MockLopoGlobalsV2.sol";
import { ILopoGlobalsEvents } from "../../contracts/interfaces/ILopoGlobalsEvents.sol";
import { Address } from "../accounts/Address.sol";

import "../BaseTest.t.sol";

contract LopoGlobalsTest is BaseTest, ILopoGlobalsEvents {
    uint256 public constant HUNDRED_PERCENT = 1_000_000; // 100.0000%

    uint256 internal constant PROTOCOL_FEE = 5 * HUNDRED_PERCENT / 1000; // 0.5%
    address internal governorV2;

    function setUp() public override {
        super.setUp();
        governorV2 = _createUser("GovernorV2");
    }

    function test_canUpgrade() public {
        MockLopoGlobalsV2 globalsV2 = new MockLopoGlobalsV2();

        /**
         * only the governor can call upgradeTo()
         * upgradeTo() has a onlyProxy mpdifier, and calls _authorizeUpgrade()
         * _authorizeUpgrade() has a onlyGovernor modifier, which implements in LopoGlobals
         */

        vm.prank(users.governor);
        wrappedLopoProxy.upgradeTo(address(globalsV2));

        // re-wrap the proxy to the new implementation
        MockLopoGlobalsV2 wrappedLopoProxyV2 = MockLopoGlobalsV2(address(LopoProxy));

        assertEq(wrappedLopoProxyV2.governor(), users.governor);

        // @notice: in our mock, we inherit from LopoGlobals
        // which means the REVISON still = 0x1
        // so we cannot do wrappedLopoProxyV2.initialize(governorV2)
        vm.expectEmit(true, true, true, true);
        emit PendingGovernorSet(governorV2);
        vm.prank(users.governor);
        wrappedLopoProxy.setPendingLopoGovernor(governorV2);

        assertEq(wrappedLopoProxy.pendingLopoGovernor(), governorV2);

        vm.expectEmit(true, true, true, true);
        emit GovernorshipAccepted(users.governor, governorV2);
        vm.prank(governorV2);
        wrappedLopoProxy.acceptLopoGovernor();
        assertEq(wrappedLopoProxy.governor(), governorV2);

        assertTrue(wrappedLopoProxyV2.isBuyer(users.buyer));

        vm.prank(governorV2);
        assertFalse(wrappedLopoProxyV2.isBuyer(users.seller));

        // new function in mockV2
        string memory text = wrappedLopoProxyV2.upgradeV2Test();
        assertEq(text, "Hello World V2");
    }

    function test_setPendingLopoGovernor_acceptLopoGovernor() public {
        vm.expectEmit(true, true, true, true);
        emit PendingGovernorSet(governorV2);
        vm.prank(users.governor);
        wrappedLopoProxy.setPendingLopoGovernor(governorV2);

        assertEq(wrappedLopoProxy.pendingLopoGovernor(), governorV2);

        vm.expectEmit(true, true, true, true);
        emit GovernorshipAccepted(users.governor, governorV2);
        vm.prank(governorV2);
        wrappedLopoProxy.acceptLopoGovernor();
        assertEq(wrappedLopoProxy.governor(), governorV2);
    }

    function test_Revert_IfZeroAddress_setLopoVault() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_InvalidVault.selector, address(0)));
        vm.prank(users.governor);
        wrappedLopoProxy.setLopoVault(address(0));
    }

    function test_setProtocolPause() public {
        vm.expectEmit(true, true, true, true);
        emit ProtocolPauseSet(users.governor, true);
        vm.prank(users.governor);
        wrappedLopoProxy.setProtocolPause(true);
        assertTrue(wrappedLopoProxy.protocolPaused());
    }

    function test_setValidPoolAdmin_setPoolConfigurator_transferOwnedPoolConfigurator() public {
        address mockPoolAdmin = address(new Address());
        address mockNextPoolAdmin = address(new Address());
        address mockPoolConfigurator = address(new Address());

        // onboard the pool admin
        vm.expectEmit(true, true, true, true);
        emit ValidPoolAdminSet(mockPoolAdmin, true);
        vm.prank(users.governor);
        wrappedLopoProxy.setValidPoolAdmin(mockPoolAdmin, true);
        assertEq(wrappedLopoProxy.ownedPoolConfigurator(mockPoolAdmin), address(0));
        assertEq(wrappedLopoProxy.isPoolAdmin(mockPoolAdmin), true);

        // set the pool configurator to the pool admin
        vm.expectEmit(true, true, true, true);
        emit PoolConfiguratorSet(mockPoolAdmin, mockPoolConfigurator);
        vm.prank(users.governor);
        wrappedLopoProxy.setPoolConfigurator(mockPoolAdmin, mockPoolConfigurator);
        assertEq(wrappedLopoProxy.ownedPoolConfigurator(mockPoolAdmin), mockPoolConfigurator);

        // before onboard the next pool admin
        assertTrue(!wrappedLopoProxy.isPoolAdmin(mockNextPoolAdmin));
        assertEq(wrappedLopoProxy.ownedPoolConfigurator(mockNextPoolAdmin), address(0));
        // onboard the next pool admin
        vm.prank(users.governor);
        wrappedLopoProxy.setValidPoolAdmin(mockNextPoolAdmin, true);
        assertTrue(wrappedLopoProxy.isPoolAdmin(mockNextPoolAdmin));

        // transfer the pool configurator from the pool admin to the next pool admin
        vm.expectEmit(true, true, true, true);
        emit PoolConfiguratorOwnershipTransferred(mockPoolAdmin, mockNextPoolAdmin, mockPoolConfigurator);
        vm.prank(mockPoolConfigurator);
        wrappedLopoProxy.transferOwnedPoolConfigurator(mockPoolAdmin, mockNextPoolAdmin);
        assertEq(wrappedLopoProxy.ownedPoolConfigurator(mockPoolAdmin), address(0));
        assertEq(wrappedLopoProxy.ownedPoolConfigurator(mockNextPoolAdmin), mockPoolConfigurator);
        assertTrue(wrappedLopoProxy.isPoolAdmin(mockPoolAdmin));
        assertTrue(wrappedLopoProxy.isPoolAdmin(mockNextPoolAdmin));
    }

    function test_setValidReceivable() public {
        address mockReceivable = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ValidReceivableSet(mockReceivable, true);
        vm.prank(users.governor);
        wrappedLopoProxy.setValidReceivable(mockReceivable, true);
        assertTrue(wrappedLopoProxy.isReceivable(mockReceivable));
    }

    function test_setValidBuyer() public {
        address mockBuyer = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ValidBuyerSet(mockBuyer, true);
        vm.prank(users.governor);
        wrappedLopoProxy.setValidBuyer(mockBuyer, true);
        assertTrue(wrappedLopoProxy.isBuyer(mockBuyer));
    }

    function test_setValidCollateralAsset() public {
        address mockCollateralAsset = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ValidCollateralAssetSet(mockCollateralAsset, true);
        vm.prank(users.governor);
        wrappedLopoProxy.setValidCollateralAsset(mockCollateralAsset, true);
        assertTrue(wrappedLopoProxy.isCollateralAsset(mockCollateralAsset));
        assertFalse(wrappedLopoProxy.isCollateralAsset(users.seller));
    }

    function test_setValidPoolAsset() public {
        address mockPoolAsset = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ValidPoolAssetSet(mockPoolAsset, true);
        vm.prank(users.governor);
        wrappedLopoProxy.setValidPoolAsset(mockPoolAsset, true);
        assertTrue(wrappedLopoProxy.isPoolAsset(mockPoolAsset));
        assertFalse(wrappedLopoProxy.isPoolAsset(users.seller));
    }

    function test_setRiskFreeRate() public {
        uint256 newRiskFreeRate_ = 5 * HUNDRED_PERCENT;
        vm.expectEmit(true, true, true, true);

        emit RiskFreeRateSet(newRiskFreeRate_);
        vm.prank(users.governor);
        wrappedLopoProxy.setRiskFreeRate(newRiskFreeRate_);
        assertEq(wrappedLopoProxy.riskFreeRate(), newRiskFreeRate_);
    }

    function test_setMinPoolLiquidityRatio() public {
        vm.expectEmit(true, true, true, true);
        emit MinPoolLiquidityRatioSet(0.05e18);
        vm.prank(users.governor);
        wrappedLopoProxy.setMinPoolLiquidityRatio(ud(0.05e18));
        assertEq(wrappedLopoProxy.minPoolLiquidityRatio().intoUint256(), 0.05e18);
    }

    function test_setProtocolFeeRate() public {
        address POOL_ADDRESS = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ProtocolFeeRateSet(POOL_ADDRESS, PROTOCOL_FEE);
        vm.prank(users.governor);
        wrappedLopoProxy.setProtocolFeeRate(POOL_ADDRESS, PROTOCOL_FEE);
        assertEq(wrappedLopoProxy.protocolFeeRate(POOL_ADDRESS), PROTOCOL_FEE);
    }

    function test_setMinDepositLimit() public {
        address mockPoolConfigurator = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit MinDepositLimitSet(mockPoolConfigurator, 100e18);
        vm.prank(users.governor);
        wrappedLopoProxy.setMinDepositLimit(mockPoolConfigurator, ud(100e18));
        assertEq(wrappedLopoProxy.minDepositLimit(mockPoolConfigurator).intoUint256(), 100e18);
    }

    function test_setWithdrawalDurationInDays() public {
        address mockPoolConfigurator = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit WithdrawalDurationInDaysSet(mockPoolConfigurator, 30);
        vm.prank(users.governor);
        wrappedLopoProxy.setWithdrawalDurationInDays(mockPoolConfigurator, 30);
        assertEq(wrappedLopoProxy.withdrawalDurationInDays(mockPoolConfigurator), 30);
    }
}
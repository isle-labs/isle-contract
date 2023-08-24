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
        wrappedLopoGlobalsProxy.upgradeTo(address(globalsV2));

        // re-wrap the proxy to the new implementation
        MockLopoGlobalsV2 wrappedLopoGlobalsProxyV2 = MockLopoGlobalsV2(address(LopoGlobalsProxy));

        assertEq(wrappedLopoGlobalsProxyV2.governor(), users.governor);

        // @notice: in our mock, we inherit from LopoGlobals
        // which means the REVISON still = 0x1
        // so we cannot do wrappedLopoGlobalsProxyV2.initialize(governorV2)
        vm.expectEmit(true, true, true, true);
        emit PendingGovernorSet(governorV2);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setPendingLopoGovernor(governorV2);

        assertEq(wrappedLopoGlobalsProxy.pendingLopoGovernor(), governorV2);

        vm.expectEmit(true, true, true, true);
        emit GovernorshipAccepted(users.governor, governorV2);
        vm.prank(governorV2);
        wrappedLopoGlobalsProxy.acceptLopoGovernor();
        assertEq(wrappedLopoGlobalsProxy.governor(), governorV2);

        assertTrue(wrappedLopoGlobalsProxyV2.isBuyer(users.buyer));

        vm.prank(governorV2);
        assertFalse(wrappedLopoGlobalsProxyV2.isBuyer(users.seller));

        // new function in mockV2
        string memory text = wrappedLopoGlobalsProxyV2.upgradeV2Test();
        assertEq(text, "Hello World V2");
    }

    function test_setPendingLopoGovernor_acceptLopoGovernor() public {
        vm.expectEmit(true, true, true, true);
        emit PendingGovernorSet(governorV2);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setPendingLopoGovernor(governorV2);

        assertEq(wrappedLopoGlobalsProxy.pendingLopoGovernor(), governorV2);

        vm.expectEmit(true, true, true, true);
        emit GovernorshipAccepted(users.governor, governorV2);
        vm.prank(governorV2);
        wrappedLopoGlobalsProxy.acceptLopoGovernor();
        assertEq(wrappedLopoGlobalsProxy.governor(), governorV2);
    }

    function test_Revert_IfZeroAddress_setLopoVault() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.Globals_InvalidVault.selector, address(0)));
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setLopoVault(address(0));
    }

    function test_setProtocolPause() public {
        vm.expectEmit(true, true, true, true);
        emit ProtocolPauseSet(users.governor, true);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setProtocolPause(true);
        assertTrue(wrappedLopoGlobalsProxy.protocolPaused());
    }

    function test_setValidPoolAdmin_setPoolConfigurator_transferOwnedPoolConfigurator() public {
        address mockPoolAdmin = address(new Address());
        address mockNextPoolAdmin = address(new Address());
        address mockPoolConfigurator = address(new Address());

        // onboard the pool admin
        vm.expectEmit(true, true, true, true);
        emit ValidPoolAdminSet(mockPoolAdmin, true);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setValidPoolAdmin(mockPoolAdmin, true);
        assertEq(wrappedLopoGlobalsProxy.ownedPoolConfigurator(mockPoolAdmin), address(0));
        assertEq(wrappedLopoGlobalsProxy.isPoolAdmin(mockPoolAdmin), true);

        // set the pool configurator to the pool admin
        vm.expectEmit(true, true, true, true);
        emit PoolConfiguratorSet(mockPoolAdmin, mockPoolConfigurator);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setPoolConfigurator(mockPoolAdmin, mockPoolConfigurator);
        assertEq(wrappedLopoGlobalsProxy.ownedPoolConfigurator(mockPoolAdmin), mockPoolConfigurator);

        // before onboard the next pool admin
        assertTrue(!wrappedLopoGlobalsProxy.isPoolAdmin(mockNextPoolAdmin));
        assertEq(wrappedLopoGlobalsProxy.ownedPoolConfigurator(mockNextPoolAdmin), address(0));
        // onboard the next pool admin
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setValidPoolAdmin(mockNextPoolAdmin, true);
        assertTrue(wrappedLopoGlobalsProxy.isPoolAdmin(mockNextPoolAdmin));

        // transfer the pool configurator from the pool admin to the next pool admin
        vm.expectEmit(true, true, true, true);
        emit PoolConfiguratorOwnershipTransferred(mockPoolAdmin, mockNextPoolAdmin, mockPoolConfigurator);
        vm.prank(mockPoolConfigurator);
        wrappedLopoGlobalsProxy.transferOwnedPoolConfigurator(mockPoolAdmin, mockNextPoolAdmin);
        assertEq(wrappedLopoGlobalsProxy.ownedPoolConfigurator(mockPoolAdmin), address(0));
        assertEq(wrappedLopoGlobalsProxy.ownedPoolConfigurator(mockNextPoolAdmin), mockPoolConfigurator);
        assertTrue(wrappedLopoGlobalsProxy.isPoolAdmin(mockPoolAdmin));
        assertTrue(wrappedLopoGlobalsProxy.isPoolAdmin(mockNextPoolAdmin));
    }

    function test_setValidReceivable() public {
        address mockReceivable = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ValidReceivableSet(mockReceivable, true);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setValidReceivable(mockReceivable, true);
        assertTrue(wrappedLopoGlobalsProxy.isReceivable(mockReceivable));
    }

    function test_setValidBuyer() public {
        address mockBuyer = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ValidBuyerSet(mockBuyer, true);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setValidBuyer(mockBuyer, true);
        assertTrue(wrappedLopoGlobalsProxy.isBuyer(mockBuyer));
    }

    function test_setValidCollateralAsset() public {
        address mockCollateralAsset = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ValidCollateralAssetSet(mockCollateralAsset, true);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setValidCollateralAsset(mockCollateralAsset, true);
        assertTrue(wrappedLopoGlobalsProxy.isCollateralAsset(mockCollateralAsset));
        assertFalse(wrappedLopoGlobalsProxy.isCollateralAsset(users.seller));
    }

    function test_setValidPoolAsset() public {
        address mockPoolAsset = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ValidPoolAssetSet(mockPoolAsset, true);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setValidPoolAsset(mockPoolAsset, true);
        assertTrue(wrappedLopoGlobalsProxy.isPoolAsset(mockPoolAsset));
        assertFalse(wrappedLopoGlobalsProxy.isPoolAsset(users.seller));
    }

    function test_setRiskFreeRate() public {
        uint256 newRiskFreeRate_ = 5 * HUNDRED_PERCENT;
        vm.expectEmit(true, true, true, true);

        emit RiskFreeRateSet(newRiskFreeRate_);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setRiskFreeRate(newRiskFreeRate_);
        assertEq(wrappedLopoGlobalsProxy.riskFreeRate(), newRiskFreeRate_);
    }

    function test_setMinPoolLiquidityRatio() public {
        vm.expectEmit(true, true, true, true);
        emit MinPoolLiquidityRatioSet(0.05e18);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setMinPoolLiquidityRatio(ud(0.05e18));
        assertEq(wrappedLopoGlobalsProxy.minPoolLiquidityRatio().intoUint256(), 0.05e18);
    }

    function test_setProtocolFeeRate() public {
        address POOL_ADDRESS = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit ProtocolFeeRateSet(POOL_ADDRESS, PROTOCOL_FEE);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setProtocolFeeRate(POOL_ADDRESS, PROTOCOL_FEE);
        assertEq(wrappedLopoGlobalsProxy.protocolFeeRate(POOL_ADDRESS), PROTOCOL_FEE);
    }

    function test_setMinDepositLimit() public {
        address mockPoolConfigurator = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit MinDepositLimitSet(mockPoolConfigurator, 100e18);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setMinDepositLimit(mockPoolConfigurator, ud(100e18));
        assertEq(wrappedLopoGlobalsProxy.minDepositLimit(mockPoolConfigurator).intoUint256(), 100e18);
    }

    function test_setWithdrawalDurationInDays() public {
        address mockPoolConfigurator = address(new Address());
        vm.expectEmit(true, true, true, true);
        emit WithdrawalDurationInDaysSet(mockPoolConfigurator, 30);
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setWithdrawalDurationInDays(mockPoolConfigurator, 30);
        assertEq(wrappedLopoGlobalsProxy.withdrawalDurationInDays(mockPoolConfigurator), 30);
    }
}

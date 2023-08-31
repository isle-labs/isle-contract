// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";
import { UUPSProxy } from "../../contracts/libraries/upgradability/UUPSProxy.sol";

import { Receivable } from "../../contracts/Receivable.sol";
import { PoolAddressesProvider } from "../../contracts/PoolAddressesProvider.sol";
import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";
import { PoolConfigurator } from "../../contracts/PoolConfigurator.sol";
import { LoanManager } from "../../contracts/LoanManager.sol";
import { WithdrawalManager } from "../../contracts/WithdrawalManager.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";

import { BaseTest } from "../BaseTest.t.sol";

contract IntegrationTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    Receivable internal receivableV1;
    UUPSProxy internal ReceivableProxy;
    Receivable internal wrappedReceivableProxy;

    PoolAddressesProvider internal poolAddressesProvider; // Proxy Admin of below contracts

    PoolConfigurator internal poolConfiguratorV1;
    LoanManager internal loanManagerV1;
    WithdrawalManager internal withdrawalManagerV1;

    ITransparentUpgradeableProxy internal poolConfiguratorProxy;
    ITransparentUpgradeableProxy internal loanManagerProxy;
    ITransparentUpgradeableProxy internal withdrawalManagerProxy;

    PoolConfigurator internal wrappedPoolConfiguratorProxy;
    LoanManager internal wrappedLoanManagerProxy;
    WithdrawalManager internal wrappedWithdrawalManagerProxy;

    IPool internal pool;

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        // set up test contracts
        _setUpReceivable();
        _setUpPoolSide();

        // label the integration test contracts
        _labelIntegrationContracts();

        // record that the pool admin owns specific pool configuarator
        vm.prank(users.governor);
        wrappedLopoGlobalsProxy.setPoolConfigurator(users.pool_admin, address(wrappedPoolConfiguratorProxy));

        pool = IPool(wrappedPoolConfiguratorProxy.pool());

        _approveToProtocol();

        _onboardUsersToConfigurator();

        _setPoolLiquidityCap(1_000_000e6);
    }

    function test_setUpStateIntegration() public {
        // check that the pool admin owns the pool configurator
        assertEq(wrappedLopoGlobalsProxy.ownedPoolConfigurator(users.pool_admin), address(wrappedPoolConfiguratorProxy));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _setUpReceivable() internal {
        receivableV1 = new Receivable();
        ReceivableProxy = new UUPSProxy(address(receivableV1), "");
        wrappedReceivableProxy = Receivable(address(ReceivableProxy));
        wrappedReceivableProxy.initialize(address(wrappedLopoGlobalsProxy));

        // onboard collateral asset on globals
        vm.startPrank(users.governor);
        wrappedLopoGlobalsProxy.setValidCollateralAsset(address(wrappedReceivableProxy), true);
        vm.stopPrank();
    }

    function _setUpPoolAddressesProvider() internal {
        poolAddressesProvider =
            new PoolAddressesProvider("BSOS Green Finance", users.pool_admin, address(wrappedLopoGlobalsProxy));
    }

    function _setUpPoolConfigurator() internal {
        poolConfiguratorV1 = new PoolConfigurator(IPoolAddressesProvider(address(poolAddressesProvider)));

        vm.startPrank(users.pool_admin);
        // set implementation to proxy in poolAddressesProvider
        // if proxyAddress is address(0), create a new proxy
        bytes memory params = abi.encodeWithSignature(
            "initialize(address,address,address,string,string)",
            address(poolAddressesProvider),
            address(usdc),
            users.pool_admin,
            "BSOS Green Share",
            "BGS"
        );
        poolAddressesProvider.setPoolConfiguratorImpl(address(poolConfiguratorV1), params);
        vm.stopPrank();

        poolConfiguratorProxy = ITransparentUpgradeableProxy(poolAddressesProvider.getPoolConfigurator());
        wrappedPoolConfiguratorProxy = PoolConfigurator(address(poolConfiguratorProxy));
    }

    function _setUpWithdrawalManager() internal {
        withdrawalManagerV1 = new WithdrawalManager(IPoolAddressesProvider(address(poolAddressesProvider)));

        vm.startPrank(users.pool_admin);
        // set implementation to proxy in poolAddressesProvider
        // if proxyAddress is address(0), create a new proxy
        poolAddressesProvider.setWithdrawalManagerImpl(address(withdrawalManagerV1));
        vm.stopPrank();

        withdrawalManagerProxy = ITransparentUpgradeableProxy(poolAddressesProvider.getWithdrawalManager());
        wrappedWithdrawalManagerProxy = WithdrawalManager(address(withdrawalManagerProxy));
    }

    function _setUpLoanManager() internal {
        loanManagerV1 = new LoanManager(IPoolAddressesProvider(address(poolAddressesProvider)));

        vm.startPrank(users.pool_admin);
        // set implementation to proxy in poolAddressesProvider
        // if proxyAddress is address(0), create a new proxy
        poolAddressesProvider.setLoanManagerImpl(address(loanManagerV1));
        vm.stopPrank();

        loanManagerProxy = ITransparentUpgradeableProxy(poolAddressesProvider.getLoanManager());
        wrappedLoanManagerProxy = LoanManager(address(loanManagerProxy));
    }

    function _setUpPoolSide() internal {
        // set up test contracts
        _setUpPoolAddressesProvider();
        _setUpPoolConfigurator();
        _setUpLoanManager();
        _setUpWithdrawalManager();
    }

    function _labelIntegrationContracts() internal {
        vm.label(address(poolAddressesProvider), "PoolAddressesProvider");
        vm.label(address(wrappedReceivableProxy), "WrappedReceivableProxy");
        vm.label(address(wrappedPoolConfiguratorProxy), "WrappedPoolConfiguratorProxy");
        vm.label(address(wrappedLoanManagerProxy), "WrappedLoanManagerProxy");
        vm.label(address(wrappedWithdrawalManagerProxy), "WrappedWithdrawalManagerProxy");
    }

    function _approveToProtocol() internal {
        vm.startPrank(users.caller);
        usdc.approve(address(pool), type(uint256).max);

        changePrank(users.receiver);
        usdc.approve(address(pool), type(uint256).max);

        changePrank(users.buyer);
        usdc.approve(address(wrappedLoanManagerProxy), type(uint256).max);

        vm.stopPrank();
    }

    function _onboardUsersToConfigurator() internal {
        vm.startPrank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setValidLender(users.receiver, true);
        wrappedPoolConfiguratorProxy.setValidBuyer(users.buyer, true);
        wrappedPoolConfiguratorProxy.setValidSeller(users.seller, true);
        vm.stopPrank();
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
        shares_ = pool.deposit(assets_, receiver_);
        vm.stopPrank();
    }

    function _callerMintToReceiver(
        address caller_,
        address receiver_,
        uint256 shares_
    )
        internal
        returns (uint256 assets_)
    {
        vm.startPrank(caller_);
        assets_ = pool.mint(shares_, receiver_);
        vm.stopPrank();
    }

    function _airdropToPool(uint256 amount) internal {
        usdc.mint(address(pool), amount);
    }

    function _setPoolLiquidityCap(uint256 liquidityCap_) internal {
        vm.startPrank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setLiquidityCap(liquidityCap_);
        vm.stopPrank();
    }

    function _createReceivable(uint256 faceAmount_) internal returns (uint256 receivablesTokenId_) {
        vm.prank(users.buyer);
        receivablesTokenId_ =
            wrappedReceivableProxy.createReceivable(users.seller, ud(faceAmount_), block.timestamp + 30 days, 804);
    }

    function _approveLoan(uint256 receivablesTokenId_, uint256 principalRequested_) internal returns (uint16 loanId_) {
        address collateralAsset_ = address(wrappedReceivableProxy);
        uint256 gracePeriod_ = 7 days;
        uint256[2] memory rates_ = [uint256(0.12e6), uint256(0.2e6)];
        uint256 fee_ = 0;

        vm.prank(users.pool_admin);
        loanId_ = wrappedLoanManagerProxy.approveLoan(
            collateralAsset_, receivablesTokenId_, gracePeriod_, principalRequested_, rates_, fee_
        );
    }

    function _fundLoan(uint16 loanId_) internal {
        vm.prank(users.pool_admin);
        wrappedLoanManagerProxy.fundLoan(loanId_);
    }
}

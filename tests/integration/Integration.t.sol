// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Receivable } from "../../contracts/Receivable.sol";
import { PoolAddressesProvider } from "../../contracts/PoolAddressesProvider.sol";
import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";
import { PoolConfigurator } from "../../contracts/PoolConfigurator.sol";
import { LoanManager } from "../../contracts/LoanManager.sol";
import { WithdrawalManager } from "../../contracts/WithdrawalManager.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";
import "../BaseTest.t.sol";

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
        wrappedLopoProxy.setPoolConfigurator(users.pool_admin, address(wrappedPoolConfiguratorProxy));

        pool = IPool(wrappedPoolConfiguratorProxy.getPool());
    }

    function test_setUpStateIntegration() public {
        // check that the pool admin owns the pool configurator
        assertEq(wrappedLopoProxy.ownedPoolConfigurator(users.pool_admin), address(wrappedPoolConfiguratorProxy));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _setUpReceivable() internal {
        receivableV1 = new Receivable();
        ReceivableProxy = new UUPSProxy(address(receivableV1), "");
        wrappedReceivableProxy = Receivable(address(ReceivableProxy));
        wrappedReceivableProxy.initialize(address(wrappedLopoProxy));
    }

    function _setUpPoolAddressesProvider() internal {
        poolAddressesProvider =
            new PoolAddressesProvider("BSOS Green Finance", users.pool_admin, address(wrappedLopoProxy));
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
}

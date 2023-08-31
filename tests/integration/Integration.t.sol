// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { StdCheats } from "@forge-std/StdCheats.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";
import { UUPSProxy } from "../../contracts/libraries/upgradability/UUPSProxy.sol";

import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";
import { ILoanManager } from "../../contracts/interfaces/ILoanManager.sol";
import { IWithdrawalManager } from "../../contracts/interfaces/IWithdrawalManager.sol";
import { IPoolConfigurator } from "../../contracts/interfaces/IPoolConfigurator.sol";
import { IReceivable } from "../../contracts/interfaces/IReceivable.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";

import { Receivable } from "../../contracts/Receivable.sol";
import { PoolAddressesProvider } from "../../contracts/PoolAddressesProvider.sol";
import { PoolConfigurator } from "../../contracts/PoolConfigurator.sol";
import { LoanManager } from "../../contracts/LoanManager.sol";
import { WithdrawalManager } from "../../contracts/WithdrawalManager.sol";

import { BaseTest } from "../BaseTest.t.sol";

contract IntegrationTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    IReceivable internal receivableV1;
    IReceivable internal receivableProxy;

    IPoolAddressesProvider internal poolAddressesProvider; // Proxy Admin of the following contracts

    IPoolConfigurator internal poolConfiguratorV1;
    ILoanManager internal loanManagerV1;
    IWithdrawalManager internal withdrawalManagerV1;

    IPoolConfigurator internal poolConfiguratorProxy;
    ILoanManager internal loanManagerProxy;
    IWithdrawalManager internal withdrawalManagerProxy;

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
        lopoGlobalsProxy.setPoolConfigurator(users.poolAdmin, address(poolConfiguratorProxy));

        pool = IPool(poolConfiguratorProxy.pool());

        _approveProtocol();

        _onboardUsersToConfigurator();

        // Set liquidity cap to allow deposits
        _setPoolLiquidityCap(defaults.LIQUIDITY_CAP());
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _setUpReceivable() internal {
        receivableV1 = new Receivable();
        receivableProxy = IReceivable(address(new UUPSProxy(address(receivableV1), "")));
        receivableProxy.initialize(address(lopoGlobalsProxy));
    }

    function _setUpPoolAddressesProvider() internal {
        poolAddressesProvider =
            new PoolAddressesProvider("BSOS Green Finance", users.poolAdmin, address(lopoGlobalsProxy));
    }

    function _setUpPoolConfigurator() internal {
        poolConfiguratorV1 = new PoolConfigurator(poolAddressesProvider);

        vm.startPrank(users.poolAdmin);
        // set implementation to proxy in poolAddressesProvider
        // if proxyAddress is address(0), create a new proxy
        bytes memory params = abi.encodeWithSelector(
            IPoolConfigurator.initialize.selector,
            address(poolAddressesProvider),
            address(usdc),
            users.poolAdmin,
            "BSOS Green Share",
            "BGS"
        );
        poolAddressesProvider.setPoolConfiguratorImpl(address(poolConfiguratorV1), params);
        vm.stopPrank();

        poolConfiguratorProxy = IPoolConfigurator(poolAddressesProvider.getPoolConfigurator());
    }

    function _setUpWithdrawalManager() internal {
        withdrawalManagerV1 = new WithdrawalManager(poolAddressesProvider);

        vm.startPrank(users.poolAdmin);

        bytes memory params = abi.encodeWithSelector(
            IWithdrawalManager.initialize.selector,
            address(poolAddressesProvider),
            7 days, // Cycle duration
            2 days // Window duration
        );

        // set implementation to proxy in poolAddressesProvider
        // if proxyAddress is address(0), create a new proxy
        poolAddressesProvider.setWithdrawalManagerImpl(address(withdrawalManagerV1), params);
        vm.stopPrank();

        withdrawalManagerProxy = IWithdrawalManager(poolAddressesProvider.getWithdrawalManager());
    }

    function _setUpLoanManager() internal {
        loanManagerV1 = new LoanManager(poolAddressesProvider);

        vm.startPrank(users.poolAdmin);
        // set implementation to proxy in poolAddressesProvider
        // if proxyAddress is address(0), create a new proxy
        poolAddressesProvider.setLoanManagerImpl(address(loanManagerV1));
        vm.stopPrank();

        loanManagerProxy = ILoanManager(poolAddressesProvider.getLoanManager());
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
        vm.label(address(receivableProxy), "ReceivableProxy");
        vm.label(address(poolConfiguratorProxy), "PoolConfiguratorProxy");
        vm.label(address(loanManagerProxy), "LoanManagerProxy");
        vm.label(address(withdrawalManagerProxy), "WithdrawalManagerProxy");
    }

    function _approveProtocol() internal {
        vm.startPrank(users.caller);
        usdc.approve(address(pool), type(uint256).max);

        changePrank(users.receiver);
        usdc.approve(address(pool), type(uint256).max);

        vm.stopPrank();
    }

    function _onboardUsersToConfigurator() internal {
        vm.startPrank(users.poolAdmin);
        poolConfiguratorProxy.setValidLender(users.receiver, true);
        poolConfiguratorProxy.setValidBuyer(users.buyer, true);
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

    function _setPoolLiquidityCap(uint256 liquidityCap_) internal {
        vm.startPrank(users.poolAdmin);
        poolConfiguratorProxy.setLiquidityCap(liquidityCap_);
        vm.stopPrank();
    }
}

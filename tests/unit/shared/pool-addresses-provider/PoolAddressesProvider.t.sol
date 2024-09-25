// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Base_Test } from "../../../Base.t.sol";

import { UUPSProxy } from "contracts/libraries/upgradability/UUPSProxy.sol";

import { IWithdrawalManager } from "contracts/interfaces/IWithdrawalManager.sol";
import { IPoolConfigurator } from "contracts/interfaces/IPoolConfigurator.sol";
import { ILoanManager } from "contracts/interfaces/ILoanManager.sol";

import { PoolAddressesProvider } from "contracts/PoolAddressesProvider.sol";
import { LoanManager } from "contracts/LoanManager.sol";
import { WithdrawalManager } from "contracts/WithdrawalManager.sol";
import { PoolConfigurator } from "contracts/PoolConfigurator.sol";
import { IsleGlobals } from "contracts/IsleGlobals.sol";

abstract contract PoolAddressesProvider_Unit_Shared_Test is Base_Test {
    struct Params {
        bytes32 id;
        address newAddress;
        address newImplementationAddress;
        string poolName;
        string poolSymbol;
        address newWithdrawalManager;
        address newLoanManager;
        address newPoolConfigurator;
        address newIsleGlobals;
        uint64 windowDuration;
        uint64 cycleDuration;
        string newMarketId;
    }

    Params internal _params;

    function setUp() public virtual override {
        Base_Test.setUp();

        deployContract();

        _params.id = defaults.ID();
        _params.newAddress = defaults.NEW_ADDRESS();
        _params.newImplementationAddress = defaults.NEW_IMPLEMENTATION();

        _params.poolName = defaults.POOL_NAME();
        _params.poolSymbol = defaults.POOL_SYMBOL();

        _params.windowDuration = defaults.WINDOW_DURATION();
        _params.cycleDuration = defaults.CYCLE_DURATION();

        _params.newMarketId = defaults.NEW_MARKET_ID();

        // Deploy with create2 so we can precompute the deployment address
        changePrank(users.governor);

        _params.newWithdrawalManager =
            address(new WithdrawalManager{ salt: "WithdrawalManager" }(poolAddressesProvider));
        _params.newLoanManager = address(new LoanManager{ salt: "LoanManager" }(poolAddressesProvider));
        _params.newPoolConfigurator = address(new PoolConfigurator{ salt: "PoolConfigurator" }(poolAddressesProvider));
        _params.newIsleGlobals =
            address(new UUPSProxy{ salt: "IsleGlobals" }(address(new IsleGlobals{ salt: "IsleGlobals" }()), ""));
    }

    function deployContract() internal {
        changePrank(users.governor);
        isleGlobals = deployGlobals();

        poolAddressesProvider = deployPoolAddressesProvider(isleGlobals);
    }

    modifier whenCallerGovernor() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.governor });
        _;
    }

    function setDefaultMarketId() internal {
        poolAddressesProvider.setMarketId(_params.newMarketId);
    }

    function setDefaultAddress() internal {
        poolAddressesProvider.setAddress(_params.id, _params.newAddress);
    }

    function setDefaultAddressAsProxy() internal {
        poolAddressesProvider.setAddressAsProxy({
            id: _params.id,
            newImplementationAddress: _params.newImplementationAddress,
            params: ""
        });
    }

    function setDefaultLoanManagerImpl() internal {
        bytes memory params = abi.encodeWithSelector(ILoanManager.initialize.selector, address(usdc));
        poolAddressesProvider.setLoanManagerImpl(_params.newLoanManager, params);
    }

    function setDefaultWithdrawalManagerImpl() internal {
        bytes memory params = abi.encodeWithSelector(
            IWithdrawalManager.initialize.selector,
            address(poolAddressesProvider),
            _params.cycleDuration,
            _params.windowDuration
        );

        poolAddressesProvider.setWithdrawalManagerImpl(_params.newWithdrawalManager, params);
    }

    function setDefaultPoolConfiguratorImpl() internal {
        bytes memory params_ = abi.encodeWithSelector(
            IPoolConfigurator.initialize.selector,
            address(poolAddressesProvider),
            users.poolAdmin,
            address(usdc),
            _params.poolSymbol,
            _params.poolName
        );

        poolAddressesProvider.setPoolConfiguratorImpl(_params.newPoolConfigurator, params_);
    }

    function setDefaultIsleGlobals() internal {
        poolAddressesProvider.setIsleGlobals(_params.newIsleGlobals);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IGovernable } from "contracts/interfaces/IGovernable.sol";
import { IPoolConfigurator } from "contracts/interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "contracts/interfaces/IPoolAddressesProvider.sol";

import { Initialize_Integration_Shared_Test } from "tests/integration/shared/pool-configurator/initialize.t.sol";

contract Initialize_Integration_Concrete_Test is Initialize_Integration_Shared_Test {
    IPoolConfigurator internal originalPoolConfiguratorNotInitialized;
    IPoolAddressesProvider internal originalPoolAddressesProvider;

    function setUp() public virtual override(Initialize_Integration_Shared_Test) {
        Initialize_Integration_Shared_Test.setUp();
    }

    modifier whenNotInitialized() {
        _;
    }

    modifier whenAddressesProviderNotMismatch() {
        _;
    }

    modifier whenPoolAdminIsNotZeroAddressAndIsValid() {
        _;
    }

    modifier whenPoolAdminNotOwnedPoolConfigurator() {
        _;
    }

    modifier whenAssetIsNotZeroAddressAndIsValid() {
        _;
    }

    function test_RevertWhen_AlreadyInitialized() external {
        poolConfiguratorNotInitialized.initialize(
            poolAddressesProvider, users.poolAdmin, address(usdc), "name", "symbol"
        );

        vm.expectRevert(bytes("Contract instance has already been initialized"));
        poolConfiguratorNotInitialized.initialize(
            poolAddressesProvider, users.poolAdmin, address(usdc), "name", "symbol"
        );
    }

    function test_RevertWhen_AddressesProviderMismatch() external whenNotInitialized {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.InvalidAddressesProvider.selector, address(0), address(poolAddressesProvider))
        );
        poolConfiguratorNotInitialized.initialize(
            IPoolAddressesProvider(address(0)), users.poolAdmin, address(usdc), "name", "symbol"
        );
    }

    function test_RevertWhen_PoolAdminIsZeroAddressOrInvalid()
        external
        whenNotInitialized
        whenAddressesProviderNotMismatch
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InvalidPoolAdmin.selector, users.eve));
        poolConfiguratorNotInitialized.initialize(poolAddressesProvider, users.eve, address(usdc), "name", "symbol");

        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InvalidPoolAdmin.selector, address(0)));
        poolConfiguratorNotInitialized.initialize(poolAddressesProvider, address(0), address(usdc), "name", "symbol");
    }

    function test_RevertWhen_AssetIsZeroAddressOrInvalid()
        external
        whenNotInitialized
        whenAddressesProviderNotMismatch
        whenPoolAdminIsNotZeroAddressAndIsValid
        whenPoolAdminNotOwnedPoolConfigurator
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InvalidPoolAsset.selector, address(0)));
        poolConfiguratorNotInitialized.initialize(poolAddressesProvider, users.poolAdmin, address(0), "name", "symbol");

        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InvalidPoolAsset.selector, users.eve));
        poolConfiguratorNotInitialized.initialize(poolAddressesProvider, users.poolAdmin, users.eve, "name", "symbol");
    }

    function test_Initialize()
        external
        whenNotInitialized
        whenAddressesProviderNotMismatch
        whenPoolAdminIsNotZeroAddressAndIsValid
        whenPoolAdminNotOwnedPoolConfigurator
        whenAssetIsNotZeroAddressAndIsValid
    {
        poolConfiguratorNotInitialized.initialize(
            poolAddressesProvider, users.poolAdmin, address(usdc), "name", "symbol"
        );

        assertEq(poolConfiguratorNotInitialized.asset(), address(usdc));
        assertEq(poolConfiguratorNotInitialized.admin(), users.poolAdmin);
    }
}

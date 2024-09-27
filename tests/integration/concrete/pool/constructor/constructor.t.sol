// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { Pool } from "contracts/Pool.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract Constructor_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    string private _name;
    string private _symbol;

    modifier whenAssetNotZeroAddress() {
        _;
    }

    modifier whenPoolConfiguratorNotZeroAddress() {
        _;
    }

    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();

        _name = defaults.POOL_NAME();
        _symbol = defaults.POOL_SYMBOL();
    }

    function test_RevertWhen_AssetIsZeroAddress() external {
        vm.expectRevert(Errors.Pool_ZeroAsset.selector);
        new Pool({ configurator_: address(poolConfigurator), asset_: address(0), name_: _name, symbol_: _symbol });
    }

    function test_RevertWhen_PoolConfiguratorIsZeroAddress() external whenAssetNotZeroAddress {
        vm.expectRevert(Errors.Pool_ZeroConfigurator.selector);
        new Pool({ configurator_: address(0), asset_: address(usdc), name_: _name, symbol_: _symbol });
    }

    function test_Constructor() external whenAssetNotZeroAddress whenPoolConfiguratorNotZeroAddress {
        Pool pool = new Pool({
            configurator_: address(poolConfigurator),
            asset_: address(usdc),
            name_: _name,
            symbol_: _symbol
        });

        assertEq(pool.configurator(), address(poolConfigurator), "configurator");
        assertEq(pool.asset(), address(usdc), "asset");
        assertEq(pool.name(), _name, "name");
        assertEq(pool.symbol(), _symbol, "symbol");
    }
}

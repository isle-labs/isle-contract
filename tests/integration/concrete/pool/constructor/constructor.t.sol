// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool } from "contracts/Pool.sol";

import { Pool_Integration_Shared_Test } from "../../../shared/pool/Pool.t.sol";

contract Constructor_Pool_Integration_Concrete_Test is Pool_Integration_Shared_Test {
    function setUp() public virtual override(Pool_Integration_Shared_Test) {
        Pool_Integration_Shared_Test.setUp();
    }

    function test_constructor() external {
        Pool pool = new Pool({
            configurator_: address(poolConfigurator),
            asset_: address(usdc),
            name_: defaults.POOL_NAME(),
            symbol_: defaults.POOL_SYMBOL()
        });

        assertEq(pool.configurator(), address(poolConfigurator), "configurator");
        assertEq(pool.asset(), address(usdc), "asset");
        assertEq(pool.name(), defaults.POOL_NAME(), "name");
        assertEq(pool.symbol(), defaults.POOL_SYMBOL(), "symbol");
    }
}

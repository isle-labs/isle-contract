// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { PoolAddressesProvider } from "contracts/PoolAddressesProvider.sol";

import { PoolAddressesProvider_Unit_Shared_Test } from
    "../../../shared/pool-addresses-provider/PoolAddressesProvider.t.sol";

contract Constructor_PoolAddressesProvider_Unit_Concrete_Test is PoolAddressesProvider_Unit_Shared_Test {
    function setUp() public virtual override(PoolAddressesProvider_Unit_Shared_Test) {
        PoolAddressesProvider_Unit_Shared_Test.setUp();
    }

    function test_constructor() external {
        changePrank(users.governor);
        PoolAddressesProvider poolAddressesProvider = new PoolAddressesProvider(defaults.MARKET_ID(), isleGlobals);

        assertEq(poolAddressesProvider.getMarketId(), defaults.MARKET_ID(), "marketId");
        assertEq(poolAddressesProvider.getAddress("ISLE_GLOBALS"), address(isleGlobals), "globals");
    }
}

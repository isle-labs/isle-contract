// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolAddressesProvider } from "contracts/PoolAddressesProvider.sol";

import { PoolAddressesProvider_Unit_Shared_Test } from
    "../../../shared/pool-addresses-provider/PoolAddressesProvider.t.sol";

contract Constructor_PoolAddressesProvider_Unit_Concrete_Test is PoolAddressesProvider_Unit_Shared_Test {
    function setUp() public virtual override(PoolAddressesProvider_Unit_Shared_Test) {
        PoolAddressesProvider_Unit_Shared_Test.setUp();
    }

    function test_RevertWhen_InvalidGlobals() external {
        string memory marketId_ = defaults.MARKET_ID();

        isleGlobals.transferGovernor(address(0));

        vm.expectRevert(
            abi.encodeWithSelector(Errors.PoolAddressesProvider_InvalidGlobals.selector, address(isleGlobals))
        );
        new PoolAddressesProvider(marketId_, isleGlobals);
    }

    function test_constructor() external {
        changePrank(users.governor);
        PoolAddressesProvider poolAddressesProvider = new PoolAddressesProvider(defaults.MARKET_ID(), isleGlobals);

        assertEq(poolAddressesProvider.getMarketId(), defaults.MARKET_ID(), "marketId");
        assertEq(poolAddressesProvider.getAddress("ISLE_GLOBALS"), address(isleGlobals), "globals");
    }
}

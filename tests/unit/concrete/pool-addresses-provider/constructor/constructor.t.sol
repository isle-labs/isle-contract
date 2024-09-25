// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolAddressesProvider } from "contracts/PoolAddressesProvider.sol";

import { PoolAddressesProvider_Unit_Shared_Test } from
    "../../../shared/pool-addresses-provider/PoolAddressesProvider.t.sol";

contract Constructor_PoolAddressesProvider_Unit_Concrete_Test is PoolAddressesProvider_Unit_Shared_Test {
    modifier whenGovernorNotZeroAddress() {
        _;
    }

    function setUp() public virtual override(PoolAddressesProvider_Unit_Shared_Test) {
        PoolAddressesProvider_Unit_Shared_Test.setUp();
    }

    function test_RevertWhen_GovernorIsZeroAddress() external {
        string memory marketId_ = defaults.MARKET_ID();

        vm.expectRevert(abi.encodeWithSelector(Errors.GovernorZeroAddress.selector));
        isleGlobals.transferGovernor(address(0));
        new PoolAddressesProvider(marketId_, isleGlobals);
    }

    function test_Constructor() external whenGovernorNotZeroAddress {
        changePrank(users.governor);
        PoolAddressesProvider poolAddressesProvider = new PoolAddressesProvider(defaults.MARKET_ID(), isleGlobals);

        assertEq(poolAddressesProvider.getMarketId(), defaults.MARKET_ID(), "marketId");
        assertEq(poolAddressesProvider.getAddress("ISLE_GLOBALS"), address(isleGlobals), "globals");
    }
}

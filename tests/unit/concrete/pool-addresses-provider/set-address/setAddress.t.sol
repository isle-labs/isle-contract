// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolAddressesProvider_Unit_Shared_Test } from
    "../../../shared/pool-addresses-provider/PoolAddressesProvider.t.sol";

contract SetAddress_PoolAddressesProvider_Unit_Concrete_Test is PoolAddressesProvider_Unit_Shared_Test {
    function setUp() public virtual override(PoolAddressesProvider_Unit_Shared_Test) {
        PoolAddressesProvider_Unit_Shared_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        // Make eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));

        setDefaultAddress();
    }

    function test_SetAddress() external whenCallerGovernor {
        vm.expectEmit({ emitter: address(poolAddressesProvider) });
        emit AddressSet({ id: defaults.ID(), oldAddress: address(0), newAddress: defaults.NEW_ADDRESS() });
        setDefaultAddress();

        assertEq(poolAddressesProvider.getAddress(defaults.ID()), defaults.NEW_ADDRESS());
    }
}

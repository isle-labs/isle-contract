// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { MockImplementation } from "../../../../mocks/MockImplementation.sol";

import { PoolAddressesProvider_Unit_Shared_Test } from
    "../../../shared/pool-addresses-provider/PoolAddressesProvider.t.sol";

contract SetAddressAsProxy_PoolAddressesProvider_Unit_Concrete_Test is PoolAddressesProvider_Unit_Shared_Test {
    function setUp() public virtual override(PoolAddressesProvider_Unit_Shared_Test) {
        PoolAddressesProvider_Unit_Shared_Test.setUp();
    }

    function test_RevertWhen_CallerNotGovernor() external {
        // Make eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotAdmin.selector, users.governor, users.eve));

        setDefaultAddressAsProxy();
    }

    function test_SetAddressAsProxy() external whenCallerGovernor {
        vm.expectEmit({ emitter: address(poolAddressesProvider) });
        emit AddressSetAsProxy({
            id: defaults.ID(),
            proxyAddress: address(0),
            oldImplementationAddress: address(0),
            newImplementationAddress: defaults.NEW_IMPLEMENTATION()
        });

        setDefaultAddressAsProxy();

        assertFalse(MockImplementation(poolAddressesProvider.getAddress(defaults.ID())).initialized());
    }
}

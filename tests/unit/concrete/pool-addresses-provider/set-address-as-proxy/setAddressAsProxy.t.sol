// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

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
        vm.expectRevert(abi.encodeWithSelector(Errors.CallerNotGovernor.selector, users.governor, users.eve));

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

    function test_SetAddressAsProxy_WhenUpgrade() external whenCallerGovernor {
        bytes32 id_ = defaults.ID();
        address initialImplementation_ = address(new MockImplementation());

        // Do first time setting implementation
        poolAddressesProvider.setAddressAsProxy({ id: id_, newImplementationAddress: initialImplementation_, params: "" });

        address proxy_ = poolAddressesProvider.getAddress(id_);
        address upgradeImplementation_ = address(new MockImplementation());

        vm.expectEmit({ emitter: address(poolAddressesProvider) });
        emit AddressSetAsProxy({
            id: id_,
            proxyAddress: proxy_,
            oldImplementationAddress: initialImplementation_,
            newImplementationAddress: upgradeImplementation_
        });
        // Upgrade implementation
        poolAddressesProvider.setAddressAsProxy({ id: id_, newImplementationAddress: upgradeImplementation_, params: "" });
    }
}

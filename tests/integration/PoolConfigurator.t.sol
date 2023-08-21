// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Integration.t.sol";
import { IPoolConfiguratorEvents } from "../../contracts/interfaces/pool/IPoolConfiguratorEvents.sol";

contract PoolConfiguratorTest is IntegrationTest, IPoolConfiguratorEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                TEST FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function test_completeConfiguration() public {
        vm.expectEmit(true, true, true, true);
        emit ConfigurationCompleted();

        wrappedPoolConfiguratorProxy.completeConfiguration();

        assertTrue(wrappedPoolConfiguratorProxy.configured());
    }

    function test_hasSufficientCover_True() public {
        assertTrue(wrappedPoolConfiguratorProxy.hasSufficientCover());
    }

    function test_hasSufficientCover_False() public {
        vm.prank(users.governor);
        wrappedLopoProxy.setMinCoverAmount(address(wrappedPoolConfiguratorProxy), 10_000e6);

        assertFalse(wrappedPoolConfiguratorProxy.hasSufficientCover());
    }
}

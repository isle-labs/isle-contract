// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract DepositCover_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        changePrank(users.poolAdmin);
    }

    function test_depositCover() external {
        uint256 coverAmount_ = defaults.COVER_AMOUNT();

        expectCallToTransferFrom({ from: users.poolAdmin, to: address(poolConfigurator), amount: coverAmount_ });
        vm.expectEmit({ emitter: address(poolConfigurator) });
        emit CoverDeposited(coverAmount_);
        poolConfigurator.depositCover(coverAmount_);

        assertEq(poolConfigurator.poolCover(), coverAmount_);
    }
}

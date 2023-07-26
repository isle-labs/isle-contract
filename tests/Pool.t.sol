// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { TestUtils, Address } from "./utils/TestUtils.sol";
import { PoolConfigurator } from "../contracts/PoolConfigurator.sol";
import { Pool } from "../contracts/Pool.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract PoolBase is TestUtils {
    address POOL_ADMIN = address(new Address());

    MockERC20 asset;
    Pool pool;

    address poolConfigurator;
    address user = address(new Address());

    function setUp() public virtual {
        asset = new MockERC20("Asset", "ASSET");
    }
}

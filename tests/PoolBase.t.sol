// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { console } from "forge-std/console.sol";
import { TestUtils, Address } from "./utils/TestUtils.sol";
import { MockPoolConfigurator } from "./mocks/MockPoolConfigurator.sol";
import { Pool } from "../contracts/Pool.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";
import { IERC20 } from "../contracts/interfaces/IERC20.sol";
import { IPoolAddressesProvider } from "../contracts/interfaces/IPoolAddressesProvider.sol";

contract PoolBase is TestUtils {
    address POOL_ADMIN = address(new Address());

    MockERC20 asset;
    Pool pool;
    MockPoolConfigurator mockPoolConfigurator;

    IPoolAddressesProvider mockPoolAddressProvider;
    address caller;
    address receiver;

    uint256[] PRIVATE_KEYS;
    address[] ACCOUNTS;

    function setUp() public virtual {
        PRIVATE_KEYS = vm.envUint("ANVIL_PRIVATE_KEYS", ",");
        ACCOUNTS = vm.envAddress("ANVIL_ACCOUNTS", ",");
        caller = ACCOUNTS[8];
        receiver = ACCOUNTS[9];

        asset = new MockERC20("Asset", "ASSET", 6);
        mockPoolConfigurator = new MockPoolConfigurator(mockPoolAddressProvider);
        pool = new Pool(address(mockPoolConfigurator), address(asset), "lpToken", "LPT");

        asset.mint(caller, 1e6);
    }

    function test_setUpState() public {
        assertEq(asset.balanceOf(caller), 1e6);
        assertEq(asset.allowance(caller, address(pool)), 0);
    }
}

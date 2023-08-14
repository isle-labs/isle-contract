// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { console } from "forge-std/console.sol";
import { TestUtils, Address } from "../utils/TestUtils.sol";
import { MockPoolConfigurator } from "../mocks/MockPoolConfigurator.sol";
import { Pool, Math } from "../../contracts/Pool.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";
import { IERC20 } from "../../contracts/interfaces/IERC20.sol";
import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";

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
    }
}

// Notice that this contract is for testing internal functions of Pool contract
contract PoolHarness is Pool {
    constructor(
        address poolConfigurator_,
        address asset_,
        string memory lpTokenName_,
        string memory lpTokenSymbol_
    )
        Pool(poolConfigurator_, asset_, lpTokenName_, lpTokenSymbol_)
    { }

    function exposed_convertToShares(
        uint256 assets_,
        Math.Rounding rounding_
    )
        external
        view
        returns (uint256 shares_)
    {
        return _convertToShares(assets_, rounding_);
    }

    function exposed_convertToExitShares(
        uint256 assets_,
        Math.Rounding rounding_
    )
        external
        view
        returns (uint256 shares_)
    {
        return _convertToExitShares(assets_, rounding_);
    }

    function exposed_convertToAssets(
        uint256 shares_,
        Math.Rounding rounding_
    )
        external
        view
        returns (uint256 assets_)
    {
        return _convertToAssets(shares_, rounding_);
    }

    function exposed_convertToExitAssets(
        uint256 shares_,
        Math.Rounding rounding_
    )
        external
        view
        returns (uint256 assets_)
    {
        return _convertToExitAssets(shares_, rounding_);
    }

    function exposed_deposit(address caller, address receiver, uint256 assets, uint256 shares) external {
        _deposit(caller, receiver, assets, shares);
    }

    function exposed_withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    )
        external
    {
        _withdraw(caller, receiver, owner, assets, shares);
    }

    function exposed_decimalsOffset() external pure returns (uint256) {
        return _decimalsOffset();
    }
}

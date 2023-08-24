// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Pool } from "../../contracts/Pool.sol";

import { IntegrationTest } from "./Integration.t.sol";

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

contract PoolHarnessTest is IntegrationTest {
    PoolHarness internal poolHarness;
    uint256 internal _delta_ = 1e6; // in USDC's case

    function setUp() public override {
        super.setUp();
        poolHarness = new PoolHarness(address(wrappedPoolConfiguratorProxy), address(usdc), "lpToken", "LPT");

        vm.startPrank(users.pool_admin);
        wrappedPoolConfiguratorProxy.setLiquidityCap(1_000_000e6);
        wrappedPoolConfiguratorProxy.setValidLender(address(this), true);
        vm.stopPrank();
    }

    function test_exposed_convertToShares() public {
        // ex. USDC decimals = 6
        // there are 1,000,000 USDC in the pool, deposited by other users
        usdc.mint(address(this), 1_000_000e6);
        usdc.approve(address(poolHarness), 1_000_000e6);
        poolHarness.deposit(1_000_000e6, address(this));
        // after 1 year, the pool has 1,050,000 USDC (earns 5% interest)
        _airdropToPoolHarness(50_000e6);
        // now someone wants to deposit 1000 USDC
        // shares = 1000e6 * (1_000_000e6 + 1) / (1_050_000e6 + 1)
        uint256 shares = poolHarness.exposed_convertToShares(1000e6, Math.Rounding.Down);
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 + 1));

        assertAlmostEq(shares, result.intoUint256(), _delta_);
    }

    function test_exposed_covertToExitShares() public {
        // ex. USDC decimals = 6
        // there are 1,000,000 USDC in the pool, deposited by other users
        usdc.mint(address(this), 1_000_000e6);
        usdc.approve(address(poolHarness), 1_000_000e6);
        poolHarness.deposit(1_000_000e6, address(this));
        // after 1 year, the pool has 1,050,000 USDC (earns 5% interest)
        _airdropToPoolHarness(50_000e6);
        // now someone wants to exit 1000 USDC
        // let the unrealizedLosses = 5000e6
        // shares = 1000e6 * (1_000_000e6 + 1) / (1_050_000e6 - 5000e6 + 1)
        uint256 shares = poolHarness.exposed_convertToExitShares(1000e6, Math.Rounding.Down);
        UD60x18 result = ud(1000e6).mul(ud(1_000_000e6 + 1)).div(ud(1_050_000e6 - 0e6 + 1));

        assertAlmostEq(shares, result.intoUint256(), _delta_);
    }

    function test_exposed_convertToAssets() public {
        // ex. USDC decimals = 6
        // there are 1,000,000 USDC in the pool, deposited by other users
        usdc.mint(address(this), 1_000_000e6);
        usdc.approve(address(poolHarness), 1_000_000e6);
        poolHarness.deposit(1_000_000e6, address(this));
        // after 1 year, the pool has 1,050,000 USDC (earns 5% interest)
        _airdropToPoolHarness(50_000e6);
        // now someone wants to mint 1000 shares
        // shares = 1000e6 * (1_050_000e6 + 1) / (1_000_000e6 + 1)
        uint256 assets = poolHarness.exposed_convertToAssets(1000e6, Math.Rounding.Down);
        UD60x18 result = ud(1000e6).mul(ud(1_050_000e6 + 1)).div(ud(1_000_000e6 + 1));

        assertAlmostEq(assets, result.intoUint256(), _delta_);
    }

    function test_exposed_convertToExitAssets() public {
        // ex. USDC decimals = 6
        // there are 1,000,000 USDC in the pool, deposited by other users
        usdc.mint(address(this), 1_000_000e6);
        usdc.approve(address(poolHarness), 1_000_000e6);
        poolHarness.deposit(1_000_000e6, address(this));
        // after 1 year, the pool has 1,050,000 USDC (earns 5% interest)
        _airdropToPoolHarness(50_000e6);
        // now someone wants to exit 1000 shares
        // let the unrealizedLosses = 5000e6
        // shares = 1000e6 * (1_050_000e6 - 5000e6 + 1) / (1_000_000e6 + 1)
        uint256 assets = poolHarness.exposed_convertToExitAssets(1000e6, Math.Rounding.Down);
        UD60x18 result = ud(1000e6).mul(ud(1_050_000e6 - 0e6 + 1)).div(ud(1_000_000e6 + 1));

        assertAlmostEq(assets, result.intoUint256(), _delta_);
    }

    function test_exposed_deposit() public {
        usdc.mint(address(this), 1000e6);
        usdc.approve(address(poolHarness), 1000e6);

        uint256 oldThisAsset = usdc.balanceOf(address(this));
        uint256 oldThisShare = poolHarness.balanceOf(address(this));
        uint256 oldAllowance = usdc.allowance(address(this), address(poolHarness));

        poolHarness.exposed_deposit(address(this), address(this), 500e6, 2000e6);

        uint256 newThisAsset = usdc.balanceOf(address(this));
        uint256 newThisShare = poolHarness.balanceOf(address(this));
        uint256 newAllowance = usdc.allowance(address(this), address(poolHarness));

        assertAlmostEq(newThisAsset, oldThisAsset - 500e6, _delta_, "thisAsset");
        assertAlmostEq(newThisShare, oldThisShare + 2000e6, _delta_, "thisShare");
        assertAlmostEq(newAllowance, oldAllowance - 500e6, _delta_, "allowance");
    }

    function test_exposed_decimalsOffset() public {
        assertEq(poolHarness.exposed_decimalsOffset(), 0);
    }

    /* ========== Helper Functions ========== */
    function _airdropToPoolHarness(uint256 amount) internal {
        usdc.mint(address(poolHarness), amount);
    }
}

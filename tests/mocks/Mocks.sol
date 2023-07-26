// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/*
import { MockERC20 } from "./MockERC20.sol";

import { Pool } from "../../contracts/Pool.sol";
import { PoolConfigurator } from "../../contracts/PoolConfigurator.sol";

import { PoolConfiguratorStorage } from "../../contracts/PoolConfiguratorStorage.sol";

contract MockERC20Pool is Pool {

    constructor(address configurator_, address asset_, string memory name_, string memory symbol_) Pool(configurator_, asset_, address(0), 0, name_, symbol_) {
        MockERC20(asset_).approve(configurator_, type(uint256).max);
    }

    function mint(address recipient_, uint256 amount_) external {
        _mint(recipient_, amount_);
    }

    function burn(address owner_, uint256 amount_) external {
        _burn(owner_, amount_);
    }
}

contract MockPoolConfigurator is PoolConfiguratorStorage {

    bool internal _canCall;

    uint256 internal _previewRedeemAmount;
    uint256 internal _previewWithdrawAmount;
    uint256 internal _redeemableAssets;
    uint256 internal _redeemableShares;

    uint256 public totalAssets;
    uint256 public unrealizedLosses;

    string public errorMessage;

    mapping(address => uint256) public maxDeposit;
    mapping(address => uint256) public maxMint;
    mapping(address => uint256) public maxRedeem;
    mapping(address => uint256) public maxWithdraw;
}
*/

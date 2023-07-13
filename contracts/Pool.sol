// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IPool } from "./interfaces/IPool.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC4626 } from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

contract Pool is IPool, ERC4626 {

    address public configurator; // The address of the pool configurator that manages administrative functionality.

    constructor(
        address configurator_,
        address asset_,
        address destination_,
        uint256 initialSupply_,
        string memory name_,
        string memory symbol_) ERC4626(IERC20(asset_)) ERC20(name_, symbol_) {

        require(asset_ != address(0), "P:C:ZERO_ASSET");
        require((configurator = configurator_) != address(0), "P:C:ZERO_MANAGER");

        if (initialSupply_ != 0) {
            _mint(destination_, initialSupply_);
        }

        require(IERC20(asset_).approve(configurator_, type(uint256).max), "P:C:ASSET_APPROVAL_FAILED");
    }



}

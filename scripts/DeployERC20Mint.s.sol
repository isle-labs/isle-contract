// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { ERC20Mint } from "./contracts/ERC20Mint.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys an ERC20 token that can be minted by everybody (used for testnet)
contract DeployERC20Mint is BaseScript {
    function run() public virtual broadcast(deployer) returns (ERC20 asset_) {
        asset_ = new ERC20Mint("Isle USD", "IUSD");
    }
}

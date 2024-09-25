// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Pool } from "../Pool.sol";

/// @title PoolDeployer
/// @notice Library containing the logic to deploy a pool contract.
library PoolDeployer {
    /// @notice Deploys a new pool contract.
    function createPool(
        address configurator_,
        address asset_,
        string memory name_,
        string memory symbol_
    )
        public
        returns (address pool_)
    {
        pool_ = address(new Pool(configurator_, asset_, name_, symbol_));
    }
}

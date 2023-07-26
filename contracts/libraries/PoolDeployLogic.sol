// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Pool } from "../Pool.sol";

library PoolDeployLogic {
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

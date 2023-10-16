// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { IsleGlobals } from "../contracts/IsleGlobals.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployGlobals is BaseScript {
    function run() public virtual returns (IsleGlobals globals_) {
        globals_ = deployGlobals();
    }
}

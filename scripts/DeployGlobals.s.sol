// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { IsleGlobals } from "../contracts/IsleGlobals.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployGlobals is BaseScript {
    function run() public virtual broadcast(deployer) returns (IsleGlobals globals_) {
        globals_ = new IsleGlobals();
        globals_.initialize(governor);
    }
}

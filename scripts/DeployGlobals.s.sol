// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { IsleGlobals } from "../contracts/IsleGlobals.sol";

import { BaseScript } from "./Base.s.sol";

// Usage: forge script --broadcast --verify scripts/DeployGlobals.s.sol --rpc-url "$RPC_URL"
contract DeployGlobals is BaseScript {
    function run() public virtual returns (IsleGlobals globals_) {
        globals_ = deployGlobals();
        initGlobals(globals_);
    }

    function initGlobals(IsleGlobals globals_) internal broadcast(governor) {
        globals_.setProtocolFee(0.1e6);
        globals_.setIsleVault(vault);
    }
}

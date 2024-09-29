// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { IsleGlobals } from "../contracts/IsleGlobals.sol";

import { BaseScript } from "./Base.s.sol";

/// @notice Deploys the IsleGlobals contract
/// @notice usage: forge script --broadcast --verify scripts/DeployGlobals.s.sol --rpc-url "$RPC_URL"
contract DeployGlobals is BaseScript {
    function run() public virtual returns (IsleGlobals globals_) {
        globals_ = deployGlobals();
    }

    function initGlobals(address globals_) public broadcast(governor) {
        IsleGlobals(globals_).setProtocolFee(0.1e6);
        IsleGlobals(globals_).setIsleVault(vault);
    }
}

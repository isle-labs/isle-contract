// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

import { IsleGlobals } from "../contracts/IsleGlobals.sol";
import { Receivable } from "../contracts/Receivable.sol";

import { BaseScript } from "./Base.s.sol";

/*
forge script scripts/DeployCore.s.sol \
          --broadcast \
          --rpc-url "sepolia" \
          --sig "run(address)" \
          --verify \
          --private-keys "0xbf164e5bc795b315dcc07d80ac082f060a3ada89af0753fb20114dd7433e45cc" \
          "$GOVERNOR_ADDRESS" \
          -vvvv
*/

contract DeployCore is BaseScript {
    function run() public virtual broadcast(deployer) returns (IsleGlobals globals_, Receivable receivable_) {
        receivable_ = Receivable(address(new UUPSProxy(address(new Receivable()), "")));
        receivable_.initialize(governor);

        globals_ = new IsleGlobals();
        globals_.initialize(governor);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

import { Receivable } from "../contracts/Receivable.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployReceivable is BaseScript {
    function run() public virtual broadcast(deployer) returns (Receivable receivable_) {
        receivable_ = Receivable(address(new UUPSProxy(address(new Receivable()), "")));
        receivable_.initialize(governor);
    }
}

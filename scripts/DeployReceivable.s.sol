// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Receivable } from "../contracts/Receivable.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployReceivable is BaseScript {
    function run(address isleGlobal_) public virtual returns (Receivable receivable_) {
        receivable_ = deployReceivable(isleGlobal_);
    }
}

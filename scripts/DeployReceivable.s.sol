// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Receivable } from "../contracts/Receivable.sol";

import { BaseScript } from "./Base.s.sol";

contract DeployReceivable is BaseScript {
    function run() public virtual returns (Receivable receivable_) {
        receivable_ = deployReceivable();
    }
}

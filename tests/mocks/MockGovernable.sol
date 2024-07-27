// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Governable } from "contracts/abstracts/Governable.sol";

contract MockGovernable is Governable {
    constructor(address governor_) {
        governor = governor_;
    }
}

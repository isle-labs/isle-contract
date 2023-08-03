// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { LopoGlobals } from "../../contracts/LopoGlobals.sol";

contract MockLopoGlobalsV2 is LopoGlobals {
    function upgradeV2Test() public pure returns (string memory) {
        return "Hello World V2";
    }
}

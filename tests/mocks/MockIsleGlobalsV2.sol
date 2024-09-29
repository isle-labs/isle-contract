// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { IsleGlobals } from "../../contracts/IsleGlobals.sol";

contract MockIsleGlobalsV2 is IsleGlobals {
    function upgradeV2Test() public pure returns (string memory) {
        return "Hello World V2";
    }
}

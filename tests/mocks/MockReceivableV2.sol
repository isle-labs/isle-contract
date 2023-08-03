// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Receivable } from "../../contracts/Receivable.sol";

contract MockReceivableV2 is Receivable {
    function upgradeV2Test() public pure returns (string memory) {
        return "ReceivableV2";
    }
}

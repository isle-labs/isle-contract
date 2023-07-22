// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { LopoGlobals } from "../contracts/globals/LopoGlobals.sol";

contract BaseTest is Test {
    address internal GOVERNOR;
    LopoGlobals internal globals;
    uint256[] PRIVATE_KEYS;
    address[] ACCOUNTS;

    function setUp() public virtual {
        globals = new LopoGlobals();
        GOVERNOR = globals.governor();

        PRIVATE_KEYS = vm.envUint("ANVIL_PRIVATE_KEYS", ",");
        ACCOUNTS = vm.envAddress("ANVIL_ACCOUNTS", ",");

        vm.prank(GOVERNOR);
        globals.setValidBorrower(GOVERNOR, true);
    }
}

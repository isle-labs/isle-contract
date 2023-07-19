// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { LopoGlobals } from "../../contracts/globals/LopoGlobals.sol";

contract LopoGlobalsTest is Test {
    address internal GOVERNOR;
    LopoGlobals internal globals;

    function setUp() virtual public {
        globals = new LopoGlobals();
        GOVERNOR = globals.governor();
        vm.prank(GOVERNOR);
        globals.setValidBorrower(GOVERNOR, true);
    }

    function test_governor() public {
        console.log("GOVERNOR: %s", GOVERNOR);
        assertEq(GOVERNOR, address(0x1c9b5a151e5e9de610a8dFa9B773E89CE6da69D2), "GOVERNOR should be this contract");
    }

    function test_isBorrower() public {
        console.log("GOVERNOR isBorrower: %s", globals.isBorrower(GOVERNOR));
        assertTrue(globals.isBorrower(GOVERNOR), "GOVERNOR should be a borrower");
    }
}

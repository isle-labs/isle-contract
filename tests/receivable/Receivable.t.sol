// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./LopoGlobals.t.sol";

contract ReceivableTest is LopoGlobalsTest {
    function setUp() virtual override public { 
        super.setUp();
    }

    function test_console() public {
        console.log("GOVERNOR: %s", GOVERNOR);
    }
}

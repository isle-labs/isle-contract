// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { LopoGlobals } from "../contracts/globals/LopoGlobals.sol";
import { ReceivableStorage } from "../contracts/receivables/ReceivableStorage.sol";

abstract contract BaseTest is Test {
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

    function _printReceivableInfo(ReceivableStorage.ReceivableInfo memory RECVInfo) internal view {
        console.log("# ReceivableInfo -----------------------");
        console.log("-> buyer: %s", RECVInfo.buyer);
        console.log("-> seller: %s", RECVInfo.seller);
        // notice that faceAmount is UD60x18
        console.log("-> faceAmount: %s", RECVInfo.faceAmount.intoUint256());
        console.log("-> repaymentTimestamp: %s", RECVInfo.repaymentTimestamp);
        console.log("-> isValid: %s", RECVInfo.isValid);
        console.log("-> currencyCode: %s", RECVInfo.currencyCode);
        console.log(""); // for layout
    }
}

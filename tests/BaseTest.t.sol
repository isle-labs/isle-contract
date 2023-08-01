// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import { PRBTest } from "@prb-test/PRBTest.sol";
import { console } from "forge-std/console.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { LopoGlobals } from "../contracts/LopoGlobals.sol";
import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";
import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

contract BaseTest is PRBTest {
    LopoGlobals globalsV1;

    UUPSProxy LopoProxy;
    LopoGlobals wrappedLopoProxyV1;

    address DEFAULT_GOVERNOR;
    address DEFAULT_BUYER;
    address DEFAULT_SELLER;
    address DEFAULT_POOL_ADMIN;

    address GOVERNOR;

    uint256[] PRIVATE_KEYS;
    address[] ACCOUNTS;

    function setUp() public virtual {
        PRIVATE_KEYS = vm.envUint("ANVIL_PRIVATE_KEYS", ",");
        ACCOUNTS = vm.envAddress("ANVIL_ACCOUNTS", ",");

        DEFAULT_GOVERNOR = ACCOUNTS[0];
        DEFAULT_BUYER = ACCOUNTS[1];
        DEFAULT_SELLER = ACCOUNTS[2];
        DEFAULT_POOL_ADMIN = ACCOUNTS[3];

        globalsV1 = new LopoGlobals();

        // deploy LopoProxy and point it to the implementation
        LopoProxy = new UUPSProxy(address(globalsV1), "");

        // wrap in ABI to support easier calls
        wrappedLopoProxyV1 = LopoGlobals(address(LopoProxy));

        // initialize the LopoProxy, assign the governor
        wrappedLopoProxyV1.initialize(DEFAULT_GOVERNOR);

        GOVERNOR = wrappedLopoProxyV1.governor();
    }

    function test_setUpState() public {
        assertEq(wrappedLopoProxyV1.governor(), DEFAULT_GOVERNOR);
        assertEq(address(wrappedLopoProxyV1), address(LopoProxy));
    }

    function _printReceivableInfo(ReceivableStorage.ReceivableInfo memory RECVInfo) internal view {
        console.log("# ReceivableInfo ---------------------------------");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../BaseTest.t.sol";
import { ReceivableStorage } from "../../contracts/receivables/ReceivableStorage.sol";
import { Receivable } from "../../contracts/receivables/Receivable.sol";

contract ReceivableTest is BaseTest {

    Receivable receivable;
    address default_buyer;
    address default_seller;
    event AssetCreated(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 faceAmount,
        uint256 repaymentTimestamp
    );

    function setUp() public virtual override {
        super.setUp();
        console.log("lopoGlobals: %s", address(globals));
        receivable = new Receivable(address(globals));
        default_buyer = address(ACCOUNTS[0]);
        default_seller = address(ACCOUNTS[1]);
    }

    function test_createReceivable() public {
        // caller of createReceivable() should be borrower
        globals.setValidBuyer(default_buyer, true);
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(default_buyer, default_seller, 0, 1000e18, block.timestamp + 1 days);
        vm.prank(default_buyer);
        receivable.createReceivable(default_seller, ud(1000e18), block.timestamp + 1 days, 804);
        uint256 tokenId = receivable.tokenOfOwnerByIndex(address(default_seller), 0);
        console.log("tokenId: %s", tokenId);
        console.log("ownerOf: %s", receivable.ownerOf(tokenId));
        console.log("balanceOf: %s", receivable.balanceOf(default_seller));
        console.log("totalSupply: %s", receivable.totalSupply());
        console.log("tokenByIndex: %s", receivable.tokenByIndex(0));
        console.log("tokenURI: %s", receivable.tokenURI(tokenId));
        
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "../BaseTest.t.sol";
import { ReceivableStorage } from "../../contracts/ReceivableStorage.sol";
import { Receivable } from "../../contracts/Receivable.sol";

contract ReceivableTest is BaseTest {
// Receivable receivable;
// address default_buyer;
// address default_seller;

// event AssetCreated(
//     address indexed buyer,
//     address indexed seller,
//     uint256 indexed tokenId,
//     uint256 faceAmount,
//     uint256 repaymentTimestamp
// );

// function setUp() public virtual override {
//     super.setUp();
//     receivable = new Receivable(address(globals));
//     default_buyer = address(ACCOUNTS[0]);
//     default_seller = address(ACCOUNTS[1]);
// }

// function test_createReceivable() public {
//     // caller of createReceivable() should be borrower
//     globals.setValidBuyer(default_buyer, true);
//     vm.expectEmit(true, true, true, true);
//     emit AssetCreated(default_buyer, default_seller, 0, 1000e18, block.timestamp + 1 days);
//     vm.prank(default_buyer);
//     receivable.createReceivable(default_seller, ud(1000e18), block.timestamp + 1 days, 804);
//     uint256 tokenId = receivable.tokenOfOwnerByIndex(address(default_seller), 0);
//     console.log("# Receivable ERC721 --------------------");
//     console.log("-> tokenId: %s", tokenId);
//     console.log("-> ownerOf: %s", receivable.ownerOf(tokenId));
//     console.log("-> balanceOf: %s", receivable.balanceOf(default_seller));
//     console.log("-> totalSupply: %s", receivable.totalSupply());
//     console.log("-> tokenByIndex: %s", receivable.tokenByIndex(0));
//     console.log(""); // for layout

//     // RecevableInfo
//     ReceivableStorage.ReceivableInfo memory RECVInfo = receivable.getReceivableInfoById(tokenId);
//     _printReceivableInfo(RECVInfo);

//     // assertions
//     assertEq(tokenId, 0);
//     assertEq(receivable.ownerOf(tokenId), default_seller);
//     assertEq(receivable.balanceOf(default_seller), 1);
//     assertEq(receivable.totalSupply(), 1);
//     assertEq(receivable.tokenByIndex(0), tokenId);

//     assertEq(RECVInfo.buyer, default_buyer);
//     assertEq(RECVInfo.seller, default_seller);
//     assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
//     assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
//     assertEq(RECVInfo.isValid, true);
//     assertEq(RECVInfo.currencyCode, 804);
// }
}

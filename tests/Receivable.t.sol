// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.19;

import "./BaseTest.t.sol";
import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";
import { Receivable } from "../contracts/Receivable.sol";

contract ReceivableTest is BaseTest {
    Receivable receivable;

    event AssetCreated(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 faceAmount,
        uint256 repaymentTimestamp
    );

    function setUp() public virtual override {
        super.setUp();
        receivable = new Receivable(address(wrappedProxyV1));
    }

    function test_createReceivable() public {
        // onboard buyer
        vm.prank(GOVERNOR);
        wrappedProxyV1.setValidBuyer(DEFAULT_BUYER, true);

        vm.expectEmit(true, true, true, true);
        emit AssetCreated(DEFAULT_BUYER, DEFAULT_SELLER, 0, 1000e18, block.timestamp + 1 days);

        // caller of createReceivable() should be buyer
        vm.prank(DEFAULT_BUYER);
        receivable.createReceivable(DEFAULT_SELLER, ud(1000e18), block.timestamp + 1 days, 804);

        uint256 tokenId = receivable.tokenOfOwnerByIndex(address(DEFAULT_SELLER), 0);
        console.log("# Receivable ERC721 ------------------------------");
        console.log("-> tokenId: %s", tokenId);
        console.log("-> ownerOf(tokenId): %s", receivable.ownerOf(tokenId));
        console.log("-> balanceOf(DEFAULT_SELLER): %s", receivable.balanceOf(DEFAULT_SELLER));
        console.log("-> totalSupply: %s", receivable.totalSupply());
        console.log("-> tokenByIndex(0): %s", receivable.tokenByIndex(0));
        console.log(""); // for layout

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = receivable.getReceivableInfoById(tokenId);
        _printReceivableInfo(RECVInfo);

        // assertions
        assertEq(tokenId, 0);
        assertEq(receivable.ownerOf(tokenId), DEFAULT_SELLER);
        assertEq(receivable.balanceOf(DEFAULT_SELLER), 1);
        assertEq(receivable.totalSupply(), 1);
        assertEq(receivable.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, DEFAULT_BUYER);
        assertEq(RECVInfo.seller, DEFAULT_SELLER);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);
    }
}

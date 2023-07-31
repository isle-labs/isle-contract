// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./BaseTest.t.sol";
import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";
import { Receivable } from "../contracts/Receivable.sol";
import { MockReceivableV2 } from "./mocks/MockReceivableV2.sol";

contract ReceivableTest is BaseTest {
    Receivable receivableV1;
    MockReceivableV2 receivableV2;

    UUPSProxy ReceivableProxy;
    Receivable wrappedReceivableProxyV1;
    MockReceivableV2 wrappedReceivableProxyV2;

    event AssetCreated(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 faceAmount,
        uint256 repaymentTimestamp
    );

    function setUp() public virtual override {
        super.setUp();
        receivableV1 = new Receivable();

        // deploy ReceivableProxy and point it to the implementation
        ReceivableProxy = new UUPSProxy(address(receivableV1), "");

        // wrap in ABI to support easier calls
        wrappedReceivableProxyV1 = Receivable(address(ReceivableProxy));

        // initialize the ReceivableProxy, assign the globals
        wrappedReceivableProxyV1.initialize(address(wrappedLopoProxyV1));

        // onboard buyer
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidBuyer(DEFAULT_BUYER, true);
    }

    function test_createReceivable() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(DEFAULT_BUYER, DEFAULT_SELLER, 0, 1000e18, block.timestamp + 1 days);

        // caller of createReceivable() should be buyer
        vm.prank(DEFAULT_BUYER);
        wrappedReceivableProxyV1.createReceivable(DEFAULT_SELLER, ud(1000e18), block.timestamp + 1 days, 804);

        uint256 tokenId = wrappedReceivableProxyV1.tokenOfOwnerByIndex(address(DEFAULT_SELLER), 0);
        console.log("# Receivable ERC721 ------------------------------");
        console.log("-> tokenId: %s", tokenId);
        console.log("-> ownerOf(tokenId): %s", wrappedReceivableProxyV1.ownerOf(tokenId));
        console.log("-> balanceOf(DEFAULT_SELLER): %s", wrappedReceivableProxyV1.balanceOf(DEFAULT_SELLER));
        console.log("-> totalSupply: %s", wrappedReceivableProxyV1.totalSupply());
        console.log("-> tokenByIndex(0): %s", wrappedReceivableProxyV1.tokenByIndex(0));
        console.log(""); // for layout

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = wrappedReceivableProxyV1.getReceivableInfoById(tokenId);
        _printReceivableInfo(RECVInfo);

        // assertions
        assertEq(tokenId, 0);
        assertEq(wrappedReceivableProxyV1.ownerOf(tokenId), DEFAULT_SELLER);
        assertEq(wrappedReceivableProxyV1.balanceOf(DEFAULT_SELLER), 1);
        assertEq(wrappedReceivableProxyV1.totalSupply(), 1);
        assertEq(wrappedReceivableProxyV1.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, DEFAULT_BUYER);
        assertEq(RECVInfo.seller, DEFAULT_SELLER);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);
    }

    function test_canUpgrade_readData() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(DEFAULT_BUYER, DEFAULT_SELLER, 0, 1000e18, block.timestamp + 1 days);

        // caller of createReceivable() should be buyer
        vm.prank(DEFAULT_BUYER);
        wrappedReceivableProxyV1.createReceivable(DEFAULT_SELLER, ud(1000e18), block.timestamp + 1 days, 804);

        receivableV2 = new MockReceivableV2();

        console.log("wrappedReceivableProxyV1.governor(): %s", wrappedReceivableProxyV1.governor());
        vm.prank(wrappedReceivableProxyV1.governor());
        wrappedReceivableProxyV1.upgradeTo(address(receivableV2));

        // re-wrap the proxy to the new implementation
        wrappedReceivableProxyV2 = MockReceivableV2(address(ReceivableProxy));

        // @notice Receivable is already initialized, so we cannot call initialize() again
        string memory text = wrappedReceivableProxyV2.upgradeV2Test();
        console.log("text: %s", text);
        assertEq(text, "ReceivableV2");

        uint256 tokenId = wrappedReceivableProxyV2.tokenOfOwnerByIndex(address(DEFAULT_SELLER), 0);
        console.log("# Receivable ERC721 ------------------------------");
        console.log("-> tokenId: %s", tokenId);
        console.log("-> ownerOf(tokenId): %s", wrappedReceivableProxyV2.ownerOf(tokenId));
        console.log("-> balanceOf(DEFAULT_SELLER): %s", wrappedReceivableProxyV2.balanceOf(DEFAULT_SELLER));
        console.log("-> totalSupply: %s", wrappedReceivableProxyV2.totalSupply());
        console.log("-> tokenByIndex(0): %s", wrappedReceivableProxyV2.tokenByIndex(0));
        console.log(""); // for layout

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = wrappedReceivableProxyV2.getReceivableInfoById(tokenId);
        _printReceivableInfo(RECVInfo);

        // assertions
        assertEq(tokenId, 0);
        assertEq(wrappedReceivableProxyV2.ownerOf(tokenId), DEFAULT_SELLER);
        assertEq(wrappedReceivableProxyV2.balanceOf(DEFAULT_SELLER), 1);
        assertEq(wrappedReceivableProxyV2.totalSupply(), 1);
        assertEq(wrappedReceivableProxyV2.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, DEFAULT_BUYER);
        assertEq(RECVInfo.seller, DEFAULT_SELLER);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { MockReceivableV2 } from "../mocks/MockReceivableV2.sol";
import { Receivable } from "../../contracts/Receivable.sol";
import { ReceivableStorage } from "../../contracts/ReceivableStorage.sol";
import { Integration_Test } from "./Integration.t.sol";

contract ReceivableTest is Integration_Test {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_createReceivable() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(users.buyer, users.seller, 0, 1000e18, block.timestamp + 30 days);

        // caller of createReceivable() should be buyer
        vm.prank(users.buyer);
        receivable.createReceivable(users.buyer, users.seller, ud(1000e18), block.timestamp + 30 days, 804);

        uint256 tokenId = receivable.tokenOfOwnerByIndex(address(users.seller), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = receivable.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);
        assertEq(receivable.ownerOf(tokenId), users.seller);
        assertEq(receivable.balanceOf(users.seller), 1);
        assertEq(receivable.totalSupply(), 1);
        assertEq(receivable.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, users.buyer);
        assertEq(RECVInfo.seller, users.seller);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 30 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);
    }

    function test_canUpgrade_readDataFromV1() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(users.buyer, users.seller, 0, 1000e18, block.timestamp + 30 days);

        _createReceivable(1000e18);

        MockReceivableV2 receivableV2 = new MockReceivableV2();

        vm.prank(users.governor);
        receivable.upgradeTo(address(receivableV2));

        // re-wrap the proxy to the new implementation
        receivableV2 = MockReceivableV2(address(receivable));

        // @notice Receivable is already initialized, so we cannot call initialize() again
        string memory text = receivableV2.upgradeV2Test();
        assertEq(text, "ReceivableV2");

        uint256 tokenId = receivableV2.tokenOfOwnerByIndex(address(users.seller), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = receivableV2.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);
        assertEq(receivableV2.ownerOf(tokenId), users.seller);
        assertEq(receivableV2.balanceOf(users.seller), 1);
        assertEq(receivableV2.totalSupply(), 1);
        assertEq(receivableV2.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, users.buyer);
        assertEq(RECVInfo.seller, users.seller);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 30 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);

        // test getImplementation() in V2
        assertEq(receivableV2.getImplementation(), address(receivableV2));
    }
}

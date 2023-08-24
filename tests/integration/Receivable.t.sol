// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Integration.t.sol";
import { IReceivableEvent } from "../../contracts/interfaces/IReceivableEvent.sol";
import { Receivable } from "../../contracts/Receivable.sol";
import { MockReceivableV2 } from "../mocks/MockReceivableV2.sol";

contract ReceivableTest is IntegrationTest, IReceivableEvent {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_getImplementation() public {
        assertEq(wrappedReceivableProxy.getImplementation(), address(receivableV1));
    }

    function test_createReceivable() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(users.buyer, users.seller, 0, 1000e18, block.timestamp + 1 days);

        // caller of createReceivable() should be buyer
        vm.prank(users.buyer);
        wrappedReceivableProxy.createReceivable(users.seller, ud(1000e18), block.timestamp + 1 days, 804);

        uint256 tokenId = wrappedReceivableProxy.tokenOfOwnerByIndex(address(users.seller), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = wrappedReceivableProxy.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);
        assertEq(wrappedReceivableProxy.ownerOf(tokenId), users.seller);
        assertEq(wrappedReceivableProxy.balanceOf(users.seller), 1);
        assertEq(wrappedReceivableProxy.totalSupply(), 1);
        assertEq(wrappedReceivableProxy.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, users.buyer);
        assertEq(RECVInfo.seller, users.seller);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);
    }

    function test_canUpgrade_readDataFromV1() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(users.buyer, users.seller, 0, 1000e18, block.timestamp + 1 days);

        // caller of createReceivable() should be buyer
        vm.prank(users.buyer);
        wrappedReceivableProxy.createReceivable(users.seller, ud(1000e18), block.timestamp + 1 days, 804);

        MockReceivableV2 receivableV2 = new MockReceivableV2();

        vm.prank(wrappedReceivableProxy.governor());
        wrappedReceivableProxy.upgradeTo(address(receivableV2));

        // re-wrap the proxy to the new implementation
        MockReceivableV2 wrappedReceivableProxyV2 = MockReceivableV2(address(ReceivableProxy));

        // @notice Receivable is already initialized, so we cannot call initialize() again
        string memory text = wrappedReceivableProxyV2.upgradeV2Test();
        assertEq(text, "ReceivableV2");

        uint256 tokenId = wrappedReceivableProxyV2.tokenOfOwnerByIndex(address(users.seller), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = wrappedReceivableProxyV2.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);
        assertEq(wrappedReceivableProxyV2.ownerOf(tokenId), users.seller);
        assertEq(wrappedReceivableProxyV2.balanceOf(users.seller), 1);
        assertEq(wrappedReceivableProxyV2.totalSupply(), 1);
        assertEq(wrappedReceivableProxyV2.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, users.buyer);
        assertEq(RECVInfo.seller, users.seller);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);

        // test getImplementation() in V2
        assertEq(wrappedReceivableProxyV2.getImplementation(), address(receivableV2));
    }

    function test_setLopoGlobals() public {
        assertEq(wrappedReceivableProxy.lopoGlobals(), address(wrappedLopoGlobalsProxy));

        // since Receivable also have governor(), we use ReceivableV1 to pretend new LopoGlobals
        address mockLopoGlobals = address(wrappedReceivableProxy);
        vm.expectEmit(true, true, true, true);
        emit LopoGlobalsSet(address(wrappedLopoGlobalsProxy), mockLopoGlobals);
        vm.prank(wrappedReceivableProxy.governor());
        wrappedReceivableProxy.setLopoGlobals(mockLopoGlobals);
        assertEq(wrappedReceivableProxy.lopoGlobals(), mockLopoGlobals);
    }

    function test_governor() public {
        assertEq(wrappedReceivableProxy.governor(), users.governor);
    }
}

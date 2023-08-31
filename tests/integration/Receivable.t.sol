// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { console2 } from "@forge-std/console2.sol";

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IERC721EnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import { MockReceivableV2 } from "../mocks/MockReceivableV2.sol";

import { IReceivableEvent } from "../../contracts/interfaces/IReceivableEvent.sol";
import { Receivable } from "../../contracts/Receivable.sol";
import { ReceivableStorage } from "../../contracts/ReceivableStorage.sol";

import { Integration_Test } from "./Integration.t.sol";

contract ReceivableTest is Integration_Test, IReceivableEvent {
    IERC721EnumerableUpgradeable receivableProxyERC721;

    function setUp() public virtual override {
        super.setUp();
        receivableProxyERC721 = IERC721EnumerableUpgradeable(address(receivableProxy));
    }

    function test_getImplementation() public {
        assertEq(receivableProxy.getImplementation(), address(receivableV1));
    }

    function test_createReceivable() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(users.buyer, users.seller, 0, 1000e18, block.timestamp + 1 days);

        // caller of createReceivable() should be buyer
        vm.prank(users.buyer);
        receivableProxy.createReceivable(users.seller, ud(1000e18), block.timestamp + 1 days, 804);

        uint256 tokenId = receivableProxyERC721.tokenOfOwnerByIndex(address(users.seller), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = receivableProxy.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);

        // ERC721 checks
        assertEq(receivableProxyERC721.ownerOf(tokenId), users.seller);
        assertEq(receivableProxyERC721.balanceOf(users.seller), 1);
        assertEq(receivableProxyERC721.totalSupply(), 1);
        assertEq(receivableProxyERC721.tokenByIndex(0), tokenId);

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
        receivableProxy.createReceivable(users.seller, ud(1000e18), block.timestamp + 1 days, 804);

        MockReceivableV2 receivableV2 = new MockReceivableV2();

        vm.prank(receivableProxy.governor());
        UUPSUpgradeable(address(receivableProxy)).upgradeTo(address(receivableV2));

        // re-wrap the proxy to the new implementation
        MockReceivableV2 receivableProxyV2 = MockReceivableV2(address(receivableProxy));

        // @notice Receivable is already initialized, so we cannot call initialize() again
        string memory text = receivableProxyV2.upgradeV2Test();
        assertEq(text, "ReceivableV2");

        uint256 tokenId = receivableProxyV2.tokenOfOwnerByIndex(address(users.seller), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = receivableProxyV2.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);
        assertEq(receivableProxyV2.ownerOf(tokenId), users.seller);
        assertEq(receivableProxyV2.balanceOf(users.seller), 1);
        assertEq(receivableProxyV2.totalSupply(), 1);
        assertEq(receivableProxyV2.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, users.buyer);
        assertEq(RECVInfo.seller, users.seller);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);

        // test getImplementation() in V2
        assertEq(receivableProxyV2.getImplementation(), address(receivableV2));
    }

    function test_setLopoGlobals() public {
        assertEq(receivableProxy.lopoGlobals(), address(lopoGlobalsProxy));

        // since Receivable also have governor(), we use ReceivableV1 to pretend new LopoGlobals
        address mockLopoGlobals = address(receivableProxy);
        vm.expectEmit(true, true, true, true);
        emit LopoGlobalsSet(address(lopoGlobalsProxy), mockLopoGlobals);
        vm.prank(receivableProxy.governor());
        receivableProxy.setLopoGlobals(mockLopoGlobals);
        assertEq(receivableProxy.lopoGlobals(), mockLopoGlobals);
    }

    function test_governor() public {
        assertEq(receivableProxy.governor(), users.governor);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { console2 } from "@forge-std/console2.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import { IERC721EnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import { MockReceivableV2 } from "../../mocks/MockReceivableV2.sol";

import { Receivable } from "../../../contracts/Receivable.sol";
import { ReceivableStorage } from "../../../contracts/ReceivableStorage.sol";

import { Base_Test } from "../../Base.t.sol";

contract Receivable_Unit_Concrete_Test is Base_Test {
    IERC721EnumerableUpgradeable receivableERC721;

    function setUp() public virtual override(Base_Test) {
        Base_Test.setUp();

        deployReceivable();

        receivableERC721 = IERC721EnumerableUpgradeable(address(receivable));

        changePrank(users.governor);
    }

    function test_createReceivable() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(users.buyer, users.seller, 0, 1000e18, block.timestamp + 1 days);

        receivable.createReceivable(users.buyer, users.seller, ud(1000e18), block.timestamp + 1 days, 804);

        uint256 tokenId = receivableERC721.tokenOfOwnerByIndex(address(users.seller), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = receivable.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);

        // ERC721 checks
        assertEq(receivableERC721.ownerOf(tokenId), users.seller);
        assertEq(receivableERC721.balanceOf(users.seller), 1);
        assertEq(receivableERC721.totalSupply(), 1);
        assertEq(receivableERC721.tokenByIndex(0), tokenId);

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

        receivable.createReceivable(users.buyer, users.seller, ud(1000e18), block.timestamp + 1 days, 804);

        MockReceivableV2 receivableV2Impl = new MockReceivableV2();

        UUPSUpgradeable(address(receivable)).upgradeTo(address(receivableV2Impl));

        // re-wrap the proxy to the new implementation
        MockReceivableV2 receivableV2 = MockReceivableV2(address(receivable));

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
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);
    }
}

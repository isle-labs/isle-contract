// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ud } from "@prb/math/UD60x18.sol";

import { IERC721EnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import { ReceivableStorage } from "contracts/ReceivableStorage.sol";

import { Receivable_Unit_Shared_Test } from "../../../shared/receivable/Receivable.t.sol";

contract CreateReceivable_Unit_Concrete_Test is Receivable_Unit_Shared_Test {
    uint256 private _tokenId = 0;

    function setUp() public virtual override(Receivable_Unit_Shared_Test) {
        Receivable_Unit_Shared_Test.setUp();
    }

    function test_createReceivable() public {
        vm.expectEmit({ emitter: address(receivable) });

        emit AssetCreated({
            buyer_: users.buyer,
            seller_: users.seller,
            tokenId_: _tokenId,
            faceAmount_: defaults.FACE_AMOUNT(),
            repaymentTimestamp_: defaults.REPAYMENT_TIMESTAMP()
        });

        receivable.createReceivable({
            buyer_: users.buyer,
            seller_: users.seller,
            faceAmount_: ud(defaults.FACE_AMOUNT()),
            repaymentTimestamp_: defaults.REPAYMENT_TIMESTAMP(),
            currencyCode_: defaults.CURRENCY_CODE()
        });

        IERC721EnumerableUpgradeable wrappedReceivable_ = IERC721EnumerableUpgradeable(address(receivable));

        uint256 tokenId_ = wrappedReceivable_.tokenOfOwnerByIndex(address(users.seller), 0);

        // assertions
        assertEq(tokenId_, _tokenId);

        // ERC721 checks
        assertEq(wrappedReceivable_.ownerOf(tokenId_), users.seller);
        assertEq(wrappedReceivable_.balanceOf(users.seller), 1);
        assertEq(wrappedReceivable_.totalSupply(), 1);
        assertEq(wrappedReceivable_.tokenByIndex(0), tokenId_);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = receivable.getReceivableInfoById(tokenId_);
        assertEq(RECVInfo.buyer, users.buyer);
        assertEq(RECVInfo.seller, users.seller);
        assertEq(RECVInfo.faceAmount.intoUint256(), defaults.FACE_AMOUNT());
        assertEq(RECVInfo.repaymentTimestamp, defaults.REPAYMENT_TIMESTAMP());
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, defaults.CURRENCY_CODE());
    }
}

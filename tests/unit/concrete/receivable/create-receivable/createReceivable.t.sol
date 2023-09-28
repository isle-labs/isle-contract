// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ud } from "@prb/math/UD60x18.sol";
import { IERC721EnumerableUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import { Receivable } from "contracts/libraries/types/DataTypes.sol";

import { ReceivableStorage } from "contracts/ReceivableStorage.sol";

import { Receivable_Unit_Shared_Test } from "../../../shared/receivable/Receivable.t.sol";

contract CreateReceivable_Receivable_Unit_Concrete_Test is Receivable_Unit_Shared_Test {
    function setUp() public virtual override(Receivable_Unit_Shared_Test) {
        Receivable_Unit_Shared_Test.setUp();
    }

    function test_createReceivable() public {
        uint256 expectedTokenId_ = 0;

        vm.expectEmit({ emitter: address(receivable) });
        emit AssetCreated({
            buyer_: users.buyer,
            seller_: users.seller,
            tokenId_: expectedTokenId_,
            faceAmount_: defaults.FACE_AMOUNT(),
            repaymentTimestamp_: defaults.REPAYMENT_TIMESTAMP()
        });

        uint256 tokenId_ = createDefaultReceivable();

        IERC721EnumerableUpgradeable wrappedReceivable_ = IERC721EnumerableUpgradeable(address(receivable));

        // assertions
        assertEq(tokenId_, expectedTokenId_);

        // ERC721 checks
        assertEq(wrappedReceivable_.ownerOf(tokenId_), users.seller);
        assertEq(wrappedReceivable_.balanceOf(users.seller), 1);
        assertEq(wrappedReceivable_.totalSupply(), 1);
        assertEq(wrappedReceivable_.tokenByIndex(0), tokenId_);

        // RecevableInfo
        Receivable.Info memory actualRECVInfo = receivable.getReceivableInfoById(tokenId_);
        assertEq(actualRECVInfo, defaults.receivableInfo());
    }
}

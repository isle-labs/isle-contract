// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ReceivableStorage } from "../ReceivableStorage.sol";

interface IReceivable {
    // events
    event AssetCreated(
        address indexed buyer_,
        address indexed seller_,
        uint256 indexed tokenId_,
        uint256 faceAmount_,
        uint256 repaymentTimestamp_
    );

    event LopoGlobalsSet(address indexed previousLopoGlobals_, address indexed currentLopoGlobals_);

    function createReceivable(
        address seller_,
        UD60x18 faceAmount_,
        uint256 repaymentTimestam_,
        uint16 currencyCode_
    )
        external
        returns (uint256 tokenId_);

    function getReceivableInfoById(uint256 tokenId_) external view returns (ReceivableStorage.ReceivableInfo memory);

    function setLopoGlobals(address lopoGlobals_) external;

    // View Functions
    function lopoGlobals() external view returns (address lopoGlobals_);

    function governor() external view returns (address governor_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IReceivableEvent {
    event AssetCreated(
        address indexed buyer_,
        address indexed seller_,
        uint256 indexed tokenId_,
        uint256 faceAmount_,
        uint256 repaymentTimestamp_
    );

    event AssetBurned(uint256 indexed tokenId_);

    event LopoGlobalsSet(address indexed previousLopoGlobals_, address indexed currentLopoGlobals_);
}

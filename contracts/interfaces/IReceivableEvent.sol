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
}

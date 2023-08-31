// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

abstract contract Events {
    // Pool events
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    // Receivable events
    event AssetCreated(
        address indexed buyer_,
        address indexed seller_,
        uint256 indexed tokenId_,
        uint256 faceAmount_,
        uint256 repaymentTimestamp_
    );

    event LopoGlobalsSet(address indexed previousLopoGlobals_, address indexed currentLopoGlobals_);
}

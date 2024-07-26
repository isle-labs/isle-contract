// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IReceivableEvent {
    /// @notice Emitted when mint a new receivable
    /// @param buyer_ The address of the buyer that's expected to pay for this receivable
    /// @param seller_ The address of the seller that's expected to receive payment for this receivable
    /// @param tokenId_ The id of the receivable
    /// @param faceAmount_ The amount of the receivable
    /// @param repaymentTimestamp_ The timestamp when the receivable is expected to be repaid
    event AssetCreated(
        address indexed buyer_,
        address indexed seller_,
        uint256 indexed tokenId_,
        uint256 faceAmount_,
        uint256 repaymentTimestamp_
    );

    /// @notice Emitted when burn a receivable
    /// @param tokenId_ The id of the receivable
    event AssetBurned(uint256 indexed tokenId_);
}

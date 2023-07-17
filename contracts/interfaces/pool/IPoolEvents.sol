// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract IPoolEvents {

    event OwnershipAccepted(address indexed previousOwner_, address indexed newOwner_);
    event PendingOwnerSet(address indexed owner_, address indexed pendingOwner_);
    event RedemptionRequested(address indexed owner_, uint256 shares_, uint256 escrowedShares_);
    event SharesRemoved(address indexed owner_, uint256 shares_);
    event WithdrawRequested(address indexed owner_, uint256 assets_, uint256 escrowedShares_);
}

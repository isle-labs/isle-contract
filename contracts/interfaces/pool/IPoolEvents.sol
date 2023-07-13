// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

contract IPoolEvents {
    /**
     *  @dev   Initial shares amount was minted to the zero address to prevent the first depositor frontrunning exploit.
     *  @param caller_              The caller of the function that emitted the `BootstrapMintPerformed` event.
     *  @param receiver_            The user that was minted the shares.
     *  @param assets_              The amount of assets deposited.
     *  @param shares_              The amount of shares that would have been minted to the user if it was not the first deposit.
     *  @param bootStrapMintAmount_ The amount of shares that was minted to the zero address to protect the first depositor.
     */
    event BootstrapMintPerformed(
        address indexed caller_,
        address indexed receiver_,
        uint256 assets_,
        uint256 shares_,
        uint256 bootStrapMintAmount_
    );

    /**
     *  @dev   `newOwner_` has accepted the transferral of RDT ownership from `previousOwner_`.
     *  @param previousOwner_ The previous RDT owner.
     *  @param newOwner_      The new RDT owner.
     */
    event OwnershipAccepted(address indexed previousOwner_, address indexed newOwner_);

    /**
     *  @dev   `owner_` has set the new pending owner of RDT to `pendingOwner_`.
     *  @param owner_        The current RDT owner.
     *  @param pendingOwner_ The new pending RDT owner.
     */
    event PendingOwnerSet(address indexed owner_, address indexed pendingOwner_);

    /**
     *  @dev   A new redemption request has been made.
     *  @param owner_          The owner of shares.
     *  @param shares_         The amount of shares requested to redeem.
     *  @param escrowedShares_ The amount of shares actually escrowed for this withdrawal request.
     */
    event RedemptionRequested(address indexed owner_, uint256 shares_, uint256 escrowedShares_);

    /**
     *  @dev   Shares have been removed.
     *  @param owner_  The owner of shares.
     *  @param shares_ The amount of shares requested to be removed.
     */
    event SharesRemoved(address indexed owner_, uint256 shares_);

    /**
     *  @dev   A new withdrawal request has been made.
     *  @param owner_          The owner of shares.
     *  @param assets_         The amount of assets requested to withdraw.
     *  @param escrowedShares_ The amount of shares actually escrowed for this withdrawal request.
     */
    event WithdrawRequested(address indexed owner_, uint256 assets_, uint256 escrowedShares_);
}

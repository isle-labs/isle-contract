// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ILoanManagerStorage {
    /// @notice Gets the asset used for the protocol
    /// @return asset_ The address of the asset
    function asset() external view returns (address asset_);

    /// @notice Gets the unrealized losses
    /// @return unrealizedLosses_ The unrealized losses
    function unrealizedLosses() external view returns (uint128);

    /// @notice Gets the total number of loans
    /// @return loanCounter_ The total number of loans
    function loanCounter() external view returns (uint16);

    /// @notice Gets the total number of payments
    /// @return paymentCounter_ The total number of payments
    function paymentCounter() external view returns (uint24);

    /// @notice Gets the payment ID with the earliest due date
    /// @return paymentWithEarliestDueDate_ The payment ID with the earliest due date
    function paymentWithEarliestDueDate() external view returns (uint24);

    /// @notice Gets the start date of the domain
    /// @return domainStart_ The start date of the domain
    function domainStart() external view returns (uint48);

    /// @notice Gets the end date of the domain
    /// @return domainEnd_ The end date of the domain
    function domainEnd() external view returns (uint48);

    /// @notice Gets the accounted interest
    /// @return accountedInterest_ The accounted interest
    function accountedInterest() external view returns (uint112);

    /// @notice Gets the total principal amount lent out
    /// @return principalOut_ The total principal amount lent out
    function principalOut() external view returns (uint128);

    /// @notice Gets the issuance rate
    /// @return issuanceRate_ The issuance rate
    function issuanceRate() external view returns (uint256);

    /// @notice Gets the payment ID of the given loan
    /// @param loanId_ The ID of the loan
    /// @return paymentId_ The payment ID of the loan
    function paymentIdOf(uint16 loanId_) external view returns (uint24);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ILoanManagerEvents {
    /// @notice Emitted when the loan manager is initialized.
    /// @param poolAddressesProvider_ The address of the pool addresses provider
    event Initialized(address poolAddressesProvider_);

    /// @notice Emitted when the accounting state is updated.
    /// @param issuanceRate_ The updated issuance rate.
    /// @param accountedInterest_ The updated accounted interest.
    event AccountingStateUpdated(uint256 issuanceRate_, uint112 accountedInterest_);

    /*//////////////////////////////////////////////////////////////////////////
                                POOL ADMIN
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a loan is requested
    /// @param loanId_ The id of the loan
    event LoanRequested(uint16 indexed loanId_);

    /// @notice Emitted when a loan is repaid
    /// @param loanId_ The id of the loan
    /// @param principal_ The total principal repaid
    /// @param interest_ The total interest repaid
    event LoanRepaid(uint16 indexed loanId_, uint256 principal_, uint256 interest_);

    /// @notice Emitted when the funds of a loan are withdrawn
    /// @param loanId_ The id of the loan
    /// @param amount_ The amount of principal withdrawn
    event FundsWithdrawn(uint16 indexed loanId_, uint256 amount_);

    /// @notice Emitted when unrealized losses is updated.
    /// @param unrealizedLosses_ The updated unrealized losses.
    event UnrealizedLossesUpdated(uint128 unrealizedLosses_);

    /// @notice Emitted when the principal out is updated.
    /// @param principalOut_ The updated principal outstanding.
    event PrincipalOutUpdated(uint128 principalOut_);

    /// @notice Emitted when the issuance params are updated.
    /// @param domainEnd_ The updated domain end
    /// @param issuanceRate_ The updated issuance rate
    /// @param accountedInterest_ The updated accounted interest
    event IssuanceParamsUpdated(uint48 indexed domainEnd_, uint256 issuanceRate_, uint112 accountedInterest_);

    /// @notice Emitted when a new payment is added to the payment linked list
    /// @param loanId_ The new loan id that the payment id is linked to
    /// @param paymentId_ The payment id of the payment
    /// @param protocolFee_ The protocol fee rate of the payment
    /// @param adminFee_ The admin fee rate of the payment
    /// @param startDate_ The start date of the payment
    /// @param dueDate_ The due date of the payment
    /// @param newRate_ The new issuance rate of the payment
    event PaymentAdded(
        uint16 indexed loanId_,
        uint256 indexed paymentId_,
        uint256 protocolFee_,
        uint256 adminFee_,
        uint256 startDate_,
        uint256 dueDate_,
        uint256 newRate_
    );

    /// @notice Emitted when a payment is removed from the payment list
    /// @param loanId_ The id of the loan that the payment is associated with
    /// @param paymentId_ The payment id of the payment
    event PaymentRemoved(uint16 indexed loanId_, uint256 indexed paymentId_);

    /// @notice Emitted when fees are paid to the admin and protocol
    /// @param loanId_ The id of the loan
    /// @param adminFee_  The amount of admin fee paid
    /// @param protocolFee_ The amount of protocol fee paid
    event FeesPaid(uint16 indexed loanId_, uint256 adminFee_, uint256 protocolFee_);

    /// @notice Emitted when the funds are distributed back to the pool, pool admin, and protocol vault
    /// @param loanId_ The id of the loan
    /// @param principal_ The amount of principal distributed
    /// @param netInterest_ The amount of net interest distributed
    event FundsDistributed(uint16 indexed loanId_, uint256 principal_, uint256 netInterest_);

    /// @notice Emitted when the loan is impaired
    /// @param loanId_ The id of the loan
    /// @param newDueDate_ The new due date of the impaired loan
    event LoanImpaired(uint16 indexed loanId_, uint256 newDueDate_);

    /// @notice Emitted when the impairment on the loan is removed
    /// @param loanId_ The id of the loan
    /// @param originalPaymentDueDate_ The original payment due date of the loan
    event ImpairmentRemoved(uint16 indexed loanId_, uint256 originalPaymentDueDate_);
}

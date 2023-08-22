// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ILoanManagerStorage } from "./ILoanManagerStorage.sol";

/// @title ILoanManager
/// @notice Creates and manages loans.
interface ILoanManager is ILoanManagerStorage {
    /*//////////////////////////////////////////////////////////////////////////
                                    EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a loan is created.
    /// @param issuanceRate_ The updated issuance rate.
    /// @param accountedInterest_ The updated accounted interest.
    event AccountingStateUpdated(uint256 issuanceRate_, uint112 accountedInterest_);

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
    /// @param protocolFeeRate_ The protocol fee rate of the payment
    /// @param adminFeeRate_ The admin fee rate of the payment
    /// @param startDate_ The start date of the payment
    /// @param dueDate_ The due date of the payment
    /// @param newRate_ The new issuance rate of the payment
    event PaymentAdded(
        uint16 indexed loanId_,
        uint256 indexed paymentId_,
        uint256 protocolFeeRate_,
        uint256 adminFeeRate_,
        uint256 startDate_,
        uint256 dueDate_,
        uint256 newRate_
    );

    /// @notice Emitted when a payment is removed from the payment list
    /// @param loanId_ The id of the loan that the payment is associated with
    /// @param paymentId_ The payment id of the payment
    event PaymentRemoved(uint16 indexed loanId_, uint256 indexed paymentId_);

    /// @notice Emitted when a payment is repaid by the buyer
    /// @param loanId_ The id of the loan that the payment is associated with
    /// @param principal_ The amount of principal repaid
    /// @param interest_ The amount of interest repaid
    event PaymentMade(uint16 indexed loanId_, uint256 principal_, uint256 interest_);

    /// @notice Emitted when the funds of a loan are withdrawn
    /// @param loanId_ The id of the loan
    /// @param principalAndInterest_ The total amount of principal and interest withdrawn
    event FundsClaimed(uint16 indexed loanId_, uint256 principalAndInterest_);

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
    /// @param newPaymentDueDate_ The new payment due date of the impaired loan
    event LoanImpaired(uint16 indexed loanId_, uint256 newPaymentDueDate_);

    /// @notice Emitted when the impairment on the loan is removed
    /// @param loanId_ The id of the loan
    /// @param originalPaymentDueDate_ The original payment due date of the loan
    event ImpairmentRemoved(uint16 indexed loanId_, uint256 originalPaymentDueDate_);

    /*//////////////////////////////////////////////////////////////////////////
                                EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Gets the amounf of interest up until this point in time
    /// @return accruedInterest_ The amount of accrued interest up until this point in time
    function accruedInterest() external view returns (uint256 accruedInterest_);

    /// @notice Gets the total assets under management
    /// @return assetsUnderManagement_ The total assets under management
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    /// @notice Gets the detailed payment breakdown of a loan up until this point in time
    /// @param loanId_ The id of the loan
    /// @return principal_ The principal due for the loan
    /// @return interest_ Interest Parameter
    ///                      [0]: The interest due for the loan
    ///                      [1]: The late interest due for the loan
    function getLoanPaymentDetailedBreakdown(uint16 loanId_)
        external
        view
        returns (uint256 principal_, uint256[2] memory interest_);

    /// @notice Gets the payment breakdown of a loan up until this point in time
    /// @param loanId_ The id of the loan
    /// @return principal_ The principal due for the loan
    /// @return interest_ The interest due for the loan
    function getLoanPaymentBreakdown(uint16 loanId_) external view returns (uint256 principal_, uint256 interest_);

    /*//////////////////////////////////////////////////////////////////////////
                                EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Manually updates the accounting state of the pool
    function updateAccounting() external;

    /// @notice Approves loan to be created with the following terms.
    /// @param receivablesTokenId_      Token ID of the receivable that would be used as collateral
    /// @param gracePeriod_             Grace period for the loan
    /// @param principalRequested_      Amount of principal approved by the buyer
    /// @param rates_                   Rates parameters:
    ///                                     [0]: interestRate,
    ///                                     [1]: lateInterestPremiumRate,
    /// @param fee_                     PoolAdmin Fees
    /// @return loanId_                 Id of the loan that is created
    function approveLoan(
        uint256 receivablesTokenId_,
        uint256 gracePeriod_,
        uint256 principalRequested_,
        uint256[2] memory rates_,
        uint256 fee_
    )
        external
        returns (uint16 loanId_);

    /// @notice Funds the loan
    /// @param loanId_ The id of the loan
    function fundLoan(uint16 loanId_) external;

    /// @notice Withdraw the funds from a loan.
    /// @param loanId_                  Id of the loan to withdraw funds from
    /// @param destination_             The destination address for the funds
    /// @return fundsWithdrawn_         The amount of funds withdrawn
    function withdrawFunds(uint16 loanId_, address destination_) external returns (uint256 fundsWithdrawn_);

    /// @notice Repays the loan. (note that the loan can be repaid early but not partially)
    /// @param loanId_ Id of the loan to repay
    /// @param amount_ Repayment amount
    /// @return principal_ Principal amount repaid
    /// @return interest_ Interest amount repaid
    function repayLoan(uint16 loanId_, uint256 amount_) external returns (uint256 principal_, uint256 interest_);

    /// @notice Impairs the loan
    /// @param loanId_ The id of the loan
    function impairLoan(uint16 loanId_) external;

    /// @notice Removes the impairment on the loan
    /// @param loanId_ The id of the loan
    function removeLoanImpairment(uint16 loanId_) external;

    /// @notice Triggers the default of a loan
    /// @param loanId_ The id of the loan that is triggered
    /// @return remainingLosses_ The amount of remaining losses
    /// @return protocolFees_ The amount of protocol fees
    function triggerDefault(uint16 loanId_) external returns (uint256 remainingLosses_, uint256 protocolFees_);
}

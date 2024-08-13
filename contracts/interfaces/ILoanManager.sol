// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Loan } from "../libraries/types/DataTypes.sol";

import { ILoanManagerEvents } from "./ILoanManagerEvents.sol";
import { ILoanManagerStorage } from "./ILoanManagerStorage.sol";

/// @title ILoanManager
/// @notice Creates and manages loans.
interface ILoanManager is ILoanManagerEvents, ILoanManagerStorage {
    /*//////////////////////////////////////////////////////////////
                      EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializes the loan manager.
    /// @param asset_ The address of the asset used for the pool.
    function initialize(address asset_) external;

    /// @notice Gets the loan info.
    /// @param loanId_ The id of the loan.
    /// @return loan_ Struct that contains the info of the loan.
    function getLoanInfo(uint16 loanId_) external view returns (Loan.Info memory loan_);

    /// @notice Gets the amount of interest up until this point in time.
    /// @return accruedInterest_ The amount of accrued interest up until this point in time.
    function accruedInterest() external view returns (uint256 accruedInterest_);

    /// @notice Gets the total assets under management.
    /// @return assetsUnderManagement_ The total value of assets under management.
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    /// @notice Gets the detailed payment breakdown of a loan up until this point in time.
    /// @param loanId_ The id of the loan.
    /// @return principal_ The principal due for the loan.
    /// @return interest_ Interest Parameter.
    ///                   [0]: The interest due for the loan.
    ///                   [1]: The late interest due for the loan.
    function getLoanPaymentDetailedBreakdown(
        uint16 loanId_
    )
        external
        view
        returns (uint256 principal_, uint256[2] memory interest_);

    /// @notice Gets the payment breakdown of a loan up until this point in time.
    /// @param loanId_ The id of the loan.
    /// @return principal_ The principal due for the loan.
    /// @return interest_ The total interest due for the loan.
    function getLoanPaymentBreakdown(uint16 loanId_) external view returns (uint256 principal_, uint256 interest_);

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Manually updates the accounting state of the pool.
    function updateAccounting() external;

    /*//////////////////////////////////////////////////////////////
                          POOL ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Used by the pool admin to fund the loan requested by the buyer.
    /// @param loanId_ The id of the loan.
    function fundLoan(uint16 loanId_) external;

    /// @notice Impairs the loan.
    /// @param loanId_ The id of the loan.
    function impairLoan(uint16 loanId_) external;

    /// @notice Removes the impairment on the loan.
    /// @param loanId_ The id of the loan.
    function removeLoanImpairment(uint16 loanId_) external;

    /// @notice Triggers the default of a loan.
    /// @param loanId_ The id of the loan that is triggered.
    /// @return remainingLosses_ The amount of remaining losses.
    /// @return protocolFees_ The amount of protocol fees.
    function triggerDefault(uint16 loanId_) external returns (uint256 remainingLosses_, uint256 protocolFees_);

    /*//////////////////////////////////////////////////////////////
                            BUYER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Used by buyer to request a loan from the pool with the following terms.
    /// @param receivablesTokenId_ Token ID of the receivable that would be used as collateral.
    /// @param gracePeriod_ Grace period of the loan.
    /// @param principalRequested_ Amount of principal requested by the buyer.
    /// @param rates_ Rates parameters:
    ///               [0]: interestRate.
    ///               [1]: lateInterestPremiumRate.
    /// @return loanId_ Id of the loan that is created.
    function requestLoan(
        address receivableAsset_,
        uint256 receivablesTokenId_,
        uint256 gracePeriod_,
        uint256 principalRequested_,
        uint256[2] memory rates_
    )
        external
        returns (uint16 loanId_);

    /// @notice Repays the loan (note that the loan can be repaid early but not partially).
    /// @param loanId_ Id of the loan to repay.
    /// @return principal_ Principal amount repaid.
    /// @return interest_ Interest amount repaid.
    function repayLoan(uint16 loanId_) external returns (uint256 principal_, uint256 interest_);

    /*//////////////////////////////////////////////////////////////
                            SELLER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Used by sellers to withdraw funds from a loan.
    /// @param loanId_ Id of the loan to withdraw funds from.
    /// @param destination_ The destination address for the funds.
    function withdrawFunds(uint16 loanId_, address destination_) external;
}

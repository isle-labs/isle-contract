// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ILoanManager {
    function unrealizedLosses() external view returns (uint128 unrealizedLosses_);
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);
    function triggerDefault(uint16 loanId_) external returns (uint256 remainingLosses_, uint256 protocolFees_);

    event AccountingStateUpdated(uint256 issuanceRate_, uint112 accountedInterest_);
    event UnrealizedLossesUpdated(uint128 unrealizedLosses_);
    event PrincipalOutUpdated(uint128 principalOut_);
    event IssuanceParamsUpdated(uint48 domainEnd_, uint256 issuanceRate_, uint112 accountedInterest_);
    event PaymentAdded(
        uint16 indexed loanId_,
        uint256 indexed paymentId_,
        uint256 protocolFeeRate_,
        uint256 adminFeeRate_,
        uint256 startDate_,
        uint256 nextPaymentDueDate_,
        uint256 newRate_
    );
    event FeesPaid(uint16 indexed loanId_, uint256 adminFee_, uint256 platformFee_);
    event FundsDistributed(uint16 indexed loanId_, uint256 principal_, uint256 netInterest_);
    event PaymentRemoved(uint16 indexed loanId_, uint256 indexed paymentId_);
    event LoanImpaired(uint256 newPaymentDueDate_);
    event ImpairmentRemoved(uint256 originalPaymentDueDate_);

    event PaymentMade(uint16 indexed loanId_, uint256 principal_, uint256 interest_);
    event FundsClaimed(uint16 indexed loanId_, uint256 principalAndInterest_);
}

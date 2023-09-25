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

    // LoanManager events
    event LoanApproved(uint16 indexed loanId_);
    event PrincipalOutUpdated(uint128 principalOut_);
    event PaymentAdded(
        uint16 indexed loanId_,
        uint256 indexed paymentId_,
        uint256 protocolFeeRate_,
        uint256 adminFeeRate_,
        uint256 startDate_,
        uint256 dueDate_,
        uint256 newRate_
    );
    event IssuanceParamsUpdated(uint48 indexed domainEnd_, uint256 issuanceRate_, uint112 accountedInterest_);
    event LoanRepaid(uint16 indexed loanId_, uint256 principal_, uint256 interest_);
    event FeesPaid(uint16 indexed loanId_, uint256 adminFee_, uint256 protocolFee_);
    event FundsDistributed(uint16 indexed loanId_, uint256 principal_, uint256 netInterest_);
    event PaymentRemoved(uint16 indexed loanId_, uint256 indexed paymentId_);
    event FundsWithdrawn(uint16 indexed loanId_, uint256 amount_);

    event LopoGlobalsSet(address indexed previousLopoGlobals_, address indexed currentLopoGlobals_);
}

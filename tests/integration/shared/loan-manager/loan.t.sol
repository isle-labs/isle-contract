// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LoanManager_Integration_Shared_Test } from "./loanManager.t.sol";

abstract contract Loan_Integration_Shared_Test is LoanManager_Integration_Shared_Test {
    function setUp() public virtual override {
        changePrank(users.poolAdmin);
    }

    function createLoan() internal {
        uint256 receivablesTokenId = createReceivable(defaults.FACE_AMOUNT());
        changePrank(users.poolAdmin);
        uint16 loanId = approveLoan(receivablesTokenId, defaults.PRINCIPAL_REQUESTED());
        fundLoan(loanId);
    }

    function approveLoan(uint256 receivablesTokenId_, uint256 principalRequested_) internal returns (uint16 loanId_) {
        address collateralAsset_ = address(receivable);
        uint256 gracePeriod_ = defaults.GRACE_PERIOD();
        uint256[2] memory rates_ = [defaults.INTEREST_RATE(), defaults.LATE_INTEREST_PREMIUM_RATE()];
        uint256 fee_ = defaults.FEE();

        loanId_ = loanManager.approveLoan(
            collateralAsset_, receivablesTokenId_, gracePeriod_, principalRequested_, rates_, fee_
        );
    }

    function fundLoan(uint16 loanId_) internal {
        loanManager.fundLoan(loanId_);
    }
}

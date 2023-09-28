// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Base_Test, ud } from "../../../Base.t.sol";

abstract contract LoanManager_Integration_Shared_Test is Base_Test {
    function setUp() public virtual override(Base_Test) { }

    function createLoan() internal {
        uint256 receivablesTokenId = createReceivable(defaults.FACE_AMOUNT());
        changePrank(users.buyer);
        uint16 loanId = approveLoan(receivablesTokenId, defaults.PRINCIPAL_REQUESTED());
        changePrank(users.poolAdmin);
        fundLoan(loanId);
    }

    function createReceivable(uint256 faceAmount_) internal returns (uint256 receivablesTokenId_) {
        receivablesTokenId_ = receivable.createReceivable(
            users.buyer, users.seller, ud(faceAmount_), defaults.MAY_31_2023(), defaults.CURRENCY_CODE()
        );
    }

    function approveLoan(uint256 receivablesTokenId_, uint256 principalRequested_) internal returns (uint16 loanId_) {
        address collateralAsset_ = address(receivable);
        uint256 gracePeriod_ = defaults.GRACE_PERIOD();
        uint256[2] memory rates_ = [defaults.INTEREST_RATE(), defaults.LATE_INTEREST_PREMIUM_RATE()];

        loanId_ =
            loanManager.approveLoan(collateralAsset_, receivablesTokenId_, gracePeriod_, principalRequested_, rates_);
    }

    function fundLoan(uint16 loanId_) internal {
        loanManager.fundLoan(loanId_);
    }
}
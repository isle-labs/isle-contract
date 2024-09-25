// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Base_Test } from "../../../Base.t.sol";

abstract contract LoanManager_Integration_Shared_Test is Base_Test {
    function setUp() public virtual override(Base_Test) { }

    function requestLoan(uint256 receivablesTokenId_, uint256 principalRequested_) internal returns (uint16 loanId_) {
        address receivableAsset_ = address(receivable);
        uint256 gracePeriod_ = defaults.GRACE_PERIOD();
        uint256[2] memory rates_ = [defaults.INTEREST_RATE(), defaults.LATE_INTEREST_PREMIUM_RATE()];

        loanId_ =
            loanManager.requestLoan(receivableAsset_, receivablesTokenId_, gracePeriod_, principalRequested_, rates_);
    }

    function fundLoan(uint16 loanId_) internal {
        loanManager.fundLoan(loanId_);
    }

    modifier whenLoanCreated() {
        createDefaultLoan();
        _;
    }

    modifier whenTwoLoansCreated() {
        createDefaultLoan();
        createDefaultLoan();
        _;
    }

    modifier whenCallerPoolAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.poolAdmin });
        _;
    }

    modifier whenCallerPoolConfigurator() {
        changePrank({ msgSender: address(poolConfigurator) });
        _;
    }
}

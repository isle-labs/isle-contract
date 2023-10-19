// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Base_Test } from "../../../Base.t.sol";

import { Receivable_Unit_Shared_Test } from "../../../unit/shared/receivable/Receivable.t.sol";

abstract contract LoanManager_Integration_Shared_Test is Base_Test, Receivable_Unit_Shared_Test {
    function setUp() public virtual override(Base_Test, Receivable_Unit_Shared_Test) { }

    function createDefaultLoan() internal {
        uint256 receivablesTokenId = createDefaultReceivable();
        changePrank(users.buyer);
        uint16 loanId = requestLoan(receivablesTokenId, defaults.PRINCIPAL_REQUESTED());
        changePrank(users.poolAdmin);
        fundLoan(loanId);
    }

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
}

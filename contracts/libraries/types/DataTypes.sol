// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

library DataTypes {
    /**
     *  @dev   Approves the receivable with the following terms.
     *  @param receivableTokenId_      Token ID of the receivable that would be used as collateral
     *  @param gracePeriod_            Grace period for the loan
     *  @param principalRequested_      Amount of principal approved by the buyer
     *  @param rates_                   Rates parameters:
     *                                      [0]: interestRate,
     *                                      [1]: lateInterestPremiumRate,
     *  @param fee_                     PoolAdmin Fees
     */
    struct ApproveReceivableParams {
        uint256 receivableTokenId;
        uint256 gracePeriod;
        uint256 principalRequested;
        uint256[2] rates;
        uint256 fee;
    }
}

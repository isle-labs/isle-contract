// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { LopoLoanStorage } from "./LopoLoanStorage.sol";

/// @title LopoLoanMigrator is to adjust all the rates to 1e6 precision.
contract LopoLoanMigrator is LopoLoanStorage {

    uint256 private constant HUNDRED_PERCENT = 1e6;
    uint256 private constant SCALED_ONE      = 1e18;

    fallback() external {
        _interestRate            /= (SCALED_ONE / HUNDRED_PERCENT);
        _closingRate             /= (SCALED_ONE / HUNDRED_PERCENT);
        _lateFeeRate             /= (SCALED_ONE / HUNDRED_PERCENT);
        _lateInterestPremiumRate /= (SCALED_ONE / HUNDRED_PERCENT);
    }

}

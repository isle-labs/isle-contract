// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;


library LopoConfiguration {

    struct PoolConfiguration {
        address governor;
        address pauseGuardian;
        address baseToken;
        address baseTokenPriceFeed;

        uint64 borrowKink;
        uint64 borrowPerYearInterestRateSlopeLow;
        uint64 borrowPerYearInterestRateSlopeHigh;
        uint64 borrowPerYearInterestRateBase;

        uint104 baseBorrowMin;

        uint24 withdrawalFee;
        uint24 poolManagerFee;
        uint24 protocolFee;
    }
}

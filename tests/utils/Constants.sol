// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

abstract contract Constants {
    uint8 public constant ASSET_DECIMALS = 6; // For USDC

    uint40 internal constant MAY_1_2023 = 1_682_899_200;
    uint40 internal constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1
    uint128 internal constant MAX_UINT128 = type(uint128).max;
    uint40 internal constant MAX_UINT40 = type(uint40).max;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// TODO: Add other interfaces for all variables

interface ILoanManagerStorage {

    /// @notice Gets the unrealized losses
    /// @return unrealizedLosses_ The unrealized losses
    function unrealizedLosses() external view returns (uint128 unrealizedLosses_);

}

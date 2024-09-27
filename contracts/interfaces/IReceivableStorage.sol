// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IReceivableStorage {
    /// @notice Returns the addres of the governor.
    /// @return governor_ The address of the governor.
    function governor() external view returns (address governor_);
}

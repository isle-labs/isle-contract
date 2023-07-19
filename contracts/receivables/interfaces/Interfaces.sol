// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ILopoGlobalsLike {

    function governor() external view returns (address governor_);

    function isBorrower(address borrower_) external view returns (bool isBorrower_);

}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ILoanManager {
    function triggerDefault(uint16 loanId_) external returns (uint256 totalLosses_);
    function unrealizedLosses() external view returns (uint128 unrealizedLosses_);
    function assetsUnderManagement() external view returns (uint256 assetsUnderManagement_);

    event AccountingStateUpdated(uint256 issuanceRate_, uint112 accountedInterest_);
    event UnrealizedLossesUpdated(uint128 unrealizedLosses_);
    event PrincipalOutUpdated(uint128 principalOut_);
}

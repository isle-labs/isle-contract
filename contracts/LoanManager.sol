// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";

import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { ILoanManager } from "./interfaces/ILoanManager.sol";
import { LoanManagerStorage } from "./LoanManagerStorage.sol";
import { Errors } from "./libraries/Errors.sol";
import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";

contract LoanManager is ILoanManager, VersionedInitializable, LoanManagerStorage {
    uint256 public constant HUNDRED_PERCENT = 1e6; // 100.0000%
    uint256 public constant PRECISION = 1e27;
    uint256 public constant LOAN_MANAGER_REVISION = 0x1;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /*//////////////////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    function initialize(IPoolAddressesProvider provider_) external initializer {
        if (ADDRESSES_PROVIDER != provider_) {
            revert Errors.InvalidAddressProvider({
                expectedProvider: address(ADDRESSES_PROVIDER),
                provider: address(provider_)
            });
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = LOAN_MANAGER_REVISION;
    }

    function poolConfigurator() public view returns (address poolConfigurator_) {
        poolConfigurator_ = ADDRESSES_PROVIDER.getPoolConfigurator();
    }

    function accruedInterest() public view returns (uint256 accruedInterest_) {
        uint256 issuanceRate_ = issuanceRate;

        accruedInterest_ = issuanceRate_ == 0 ? 0 : _getIssuance(issuanceRate, block.timestamp - domainStart);
    }

    function getPaymentBreakdown(
        uint16 loanId_,
        uint256 paymentTimestamp_
    )
        public
        view
        returns (uint256 principal_, uint256 interest_, uint256 lateInterest_)
    {
        principal_ = loans[loanId_].principal;

        if (paymentTimestamp_ > loans[loanId_].dueDate) {
            interest_ = _getIssuance(loans[loanId_].interestRate, loans[loanId_].dueDate - loans[loanId_].startDate);
            lateInterest_ =
                _getIssuance(loans[loanId_].lateInterestPremiumRate, paymentTimestamp_ - loans[loanId_].dueDate);
        } else {
            interest_ = _getIssuance(loans[loanId_].interestRate, paymentTimestamp_ - loans[loanId_].startDate);
        }
    }

    function assetsUnderManagement() public view virtual override returns (uint256 assetsUnderManagement_) {
        assetsUnderManagement_ = principalOut + accountedInterest + accruedInterest();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /* Loan Default Functions */
    function triggerDefault(uint16 loanId_) external override returns (uint256 totalLosses_) {
        if (msg.sender != poolConfigurator()) {
            revert Errors.InvalidCaller({ caller: msg.sender, expectedCaller: poolConfigurator() });
        }

        uint40 impairedDate_ = _accountForLoanImpairment(loanId_);

        (uint256 principal_, uint256 interest_, uint256 lateInterest_) = getPaymentBreakdown(loanId_, impairedDate_);

        interest_ += lateInterest_;

        // The payment's interest until the impaired date must be deducted
        uint256 accountedImpairedInterest_ =
            _getIssuance(loans[loanId_].issuanceRate, impairedDate_ - loans[loanId_].startDate);

        _updateInterestAccounting(-SafeCast.toInt256(accountedImpairedInterest_), 0);
        _updateUnrealizedLosses(-SafeCast.toInt256(principal_ + accountedImpairedInterest_));
        _updatePrincipalOut(-SafeCast.toInt256(principal_));

        totalLosses_ = principal_ + interest_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _getIssuance(uint256 issuanceRate_, uint256 interval_) internal pure returns (uint256 issuance_) {
        issuance_ = (issuanceRate_ * interval_) / PRECISION;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _accountForLoanImpairment(uint16 loanId_) internal returns (uint40 impairedDate_) {
        Loan memory loan_ = loans[loanId_];
        impairedDate_ = impairmentFor[loanId_].impairedDate;

        if (impairedDate_ != 0) {
            return impairedDate_;
        }

        impairmentFor[loanId_].impairedDate = impairedDate_;

        _updateInterestAccounting(0, -SafeCast.toInt256(loan_.issuanceRate));
    }

    function _updateInterestAccounting(int256 accountedInterestAdjustment_, int256 issuanceRateAdjustment_) internal {
        accountedInterest = SafeCast.toUint112(
            SafeCast.toUint256(
                SignedMath.max(
                    (SafeCast.toInt256(accountedInterest + accruedInterest()) + accountedInterestAdjustment_), 0
                )
            )
        );

        domainStart = SafeCast.toUint40(block.timestamp);
        issuanceRate = SafeCast.toUint256(SignedMath.max(SafeCast.toInt256(issuanceRate) + issuanceRateAdjustment_, 0));

        emit AccountingStateUpdated(issuanceRate, accountedInterest);
    }

    function _updateUnrealizedLosses(int256 lossesAdjustment_) internal {
        unrealizedLosses = SafeCast.toUint128(
            SafeCast.toUint256(SignedMath.max(SafeCast.toInt256(unrealizedLosses) + lossesAdjustment_, 0))
        );
        emit UnrealizedLossesUpdated(unrealizedLosses);
    }

    function _updatePrincipalOut(int256 principalOutAdjustment_) internal {
        principalOut = SafeCast.toUint128(
            SafeCast.toUint256(SignedMath.max(SafeCast.toInt256(principalOut) + principalOutAdjustment_, 0))
        );
        emit PrincipalOutUpdated(principalOut);
    }
}

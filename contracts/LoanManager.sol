// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SignedMath } from "@openzeppelin/contracts/utils/math/SignedMath.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import { Errors } from "./libraries/Errors.sol";
import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { Receivable, Loan } from "./libraries/types/DataTypes.sol";

import { IAdminable } from "./interfaces/IAdminable.sol";
import { IIsleGlobals } from "./interfaces/IIsleGlobals.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { ILoanManager } from "./interfaces/ILoanManager.sol";
import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";
import { IReceivable } from "./interfaces/IReceivable.sol";

import { LoanManagerStorage } from "./LoanManagerStorage.sol";
import { ReceivableStorage } from "./ReceivableStorage.sol";

contract LoanManager is ILoanManager, IERC721Receiver, LoanManagerStorage, ReentrancyGuard, VersionedInitializable {
    uint256 public constant LOAN_MANAGER_REVISION = 0x1;

    uint256 public constant HUNDRED_PERCENT = 1e6; // 100.0000%
    uint256 private constant SCALED_ONE = 1e18;
    uint256 public constant PRECISION = 1e27;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    using SafeCast for uint256;
    using SafeCast for uint128;
    using SafeCast for int256;
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IPoolAddressesProvider provider_) {
        if (address(provider_) == address(0)) {
            revert Errors.AddressesProviderZeroAddress();
        }
        ADDRESSES_PROVIDER = provider_;
    }

    /// @notice Initializes the Loan Manager.
    /// @dev Function is invoked by the proxy contract when the Loan Manager Contract is added to the
    /// PoolAddressesProvider of the market
    /// @param provider_ The address of the PoolAddressesProvider
    function initialize(IPoolAddressesProvider provider_) external virtual initializer {
        if (ADDRESSES_PROVIDER != provider_) {
            revert Errors.InvalidAddressesProvider({
                expectedProvider: address(ADDRESSES_PROVIDER),
                provider: address(provider_)
            });
        }
        fundsAsset = IPoolConfigurator(ADDRESSES_PROVIDER.getPoolConfigurator()).asset();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Can only be called when the function is not paused
    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    /// @dev Can only be called by the Pool Admin or the Governor
    modifier onlyPoolAdminOrGovernor() {
        _revertIfNotPoolAdminOrGovernor();
        _;
    }

    /// @dev Can only be called by the Pool Admin
    modifier onlyPoolAdmin() {
        _revertIfNotPoolAdmin();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = LOAN_MANAGER_REVISION;
    }

    /// @inheritdoc ILoanManager
    function getLoanInfo(uint16 loanId_) external view returns (Loan.Info memory loan_) {
        return _loans[loanId_];
    }

    /// @inheritdoc ILoanManager
    function accruedInterest() public view override returns (uint256 accruedInterest_) {
        uint256 issuanceRate_ = issuanceRate;
        accruedInterest_ = issuanceRate_ == 0 ? 0 : _getIssuance(issuanceRate, block.timestamp - domainStart);
    }

    /// @inheritdoc ILoanManager
    function assetsUnderManagement() public view override returns (uint256 assetsUnderManagement_) {
        assetsUnderManagement_ = principalOut + accountedInterest + accruedInterest();
    }

    /// @inheritdoc ILoanManager
    function getLoanPaymentDetailedBreakdown(uint16 loanId_)
        public
        view
        override
        returns (uint256 principal_, uint256[2] memory interest_)
    {
        Loan.Info memory loan_ = _loans[loanId_];

        principal_ = loan_.principal;
        interest_ = _getInterestBreakdown(
            block.timestamp,
            loan_.startDate,
            loan_.dueDate,
            loan_.principal,
            loan_.interestRate,
            loan_.lateInterestPremiumRate
        );
    }

    /// @inheritdoc ILoanManager
    function getLoanPaymentBreakdown(uint16 loanId_)
        public
        view
        override
        returns (uint256 principal_, uint256 interest_)
    {
        Loan.Info memory loan_ = _loans[loanId_];
        uint256[2] memory interestArray_;

        interestArray_ = _getInterestBreakdown(
            block.timestamp,
            loan_.startDate,
            loan_.dueDate,
            loan_.principal,
            loan_.interestRate,
            loan_.lateInterestPremiumRate
        );

        principal_ = loan_.principal;
        interest_ = interestArray_[0] + interestArray_[1];
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ILoanManager
    function updateAccounting() external whenNotPaused onlyPoolAdminOrGovernor {
        _advanceGlobalPaymentAccounting();
        _updateIssuanceParams(issuanceRate, accountedInterest);
    }

    /// @inheritdoc ILoanManager
    function approveLoan(
        address collateralAsset_,
        uint256 receivablesTokenId_,
        uint256 gracePeriod_,
        uint256 principalRequested_,
        uint256[2] memory rates_
    )
        external
        override
        whenNotPaused
        returns (uint16 loanId_)
    {
        // Check if the collateral asset is in the allowed list in IsleGlobals
        if (!IIsleGlobals(_globals()).isCollateralAsset(collateralAsset_)) {
            revert Errors.LoanManager_CollateralAssetNotAllowed({ collateralAsset_: collateralAsset_ });
        }

        Receivable.Info memory receivableInfo_ =
            IReceivable(collateralAsset_).getReceivableInfoById(receivablesTokenId_);

        _revertIfCallerNotReceivableBuyer(receivableInfo_.buyer);

        _revertIfInvalidReceivable(
            receivablesTokenId_, receivableInfo_.buyer, receivableInfo_.seller, receivableInfo_.repaymentTimestamp
        );

        if (principalRequested_ > receivableInfo_.faceAmount) {
            revert Errors.LoanManager_PrincipalRequestedTooHigh({
                principalRequested_: principalRequested_,
                maxPrincipal_: receivableInfo_.faceAmount
            });
        }

        // Increment loan
        loanId_ = ++loanCounter;

        // Create loan
        _loans[loanId_] = Loan.Info({
            buyer: receivableInfo_.buyer,
            seller: receivableInfo_.seller,
            collateralAsset: collateralAsset_,
            collateralTokenId: receivablesTokenId_,
            principal: principalRequested_,
            drawableFunds: uint256(0),
            interestRate: rates_[0],
            lateInterestPremiumRate: rates_[1],
            startDate: uint256(0),
            dueDate: receivableInfo_.repaymentTimestamp,
            originalDueDate: uint256(0),
            gracePeriod: gracePeriod_,
            isImpaired: false
        });

        emit LoanApproved({ loanId_: loanId_ });
    }

    /// @inheritdoc ILoanManager
    function fundLoan(uint16 loanId_) external override nonReentrant whenNotPaused onlyPoolAdmin {
        Loan.Info memory loan_ = _loans[loanId_];

        _advanceGlobalPaymentAccounting();

        // transfer funds from pool to loan manager
        uint256 principal_ = loan_.principal;
        IPoolConfigurator(_poolConfigurator()).requestFunds(principal_);

        // Update loan state
        Loan.Info storage loanStorage_ = _loans[loanId_];
        loanStorage_.startDate = block.timestamp;
        loanStorage_.drawableFunds = principal_;

        emit PrincipalOutUpdated(principalOut += principal_.toUint128());

        // Add new issuance rate from queued payment
        _updateIssuanceParams(issuanceRate + _queuePayment(loanId_, block.timestamp, loan_.dueDate), accountedInterest);
    }

    /// @inheritdoc ILoanManager
    function repayLoan(uint16 loanId_)
        external
        override
        whenNotPaused
        returns (uint256 principal_, uint256 interest_)
    {
        // 1. Advance global accounting
        //   - Update `domainStart` to the current `block.timestamp`
        //   - Update `accountedInterest` to account all accrued interest since last update
        _advanceGlobalPaymentAccounting();

        // 2. get the principal and interest amounts
        (principal_, interest_) = getLoanPaymentBreakdown(loanId_);

        uint256 principalAndInterest_ = principal_ + interest_;

        // 3. Transfer the funds from the buyer to the loan manager
        IERC20(fundsAsset).safeTransferFrom(msg.sender, address(this), principalAndInterest_);

        emit LoanRepaid({ loanId_: loanId_, principal_: principal_, interest_: interest_ });

        // 4. Transfer the funds to the pool, poolAdmin, and protocolVault
        _distributeClaimedFunds(loanId_, principal_, interest_);

        // 5. Decrement `principalOut`
        if (principal_ != 0) {
            emit PrincipalOutUpdated(principalOut -= SafeCast.toUint128(principal_));
        }

        // 6. Update the accounting based on the payment that was just made
        uint256 paymentIssuanceRate_ = _handlePaymentAccounting(loanId_);

        // 7. Delete paymentId from mapping
        delete paymentIdOf[loanId_];

        // 8. burn the receivable
        Loan.Info memory loan_ = _loans[loanId_];
        if (IERC721(loan_.collateralAsset).ownerOf(loan_.collateralTokenId) == address(this)) {
            IReceivable(loan_.collateralAsset).burnReceivable(loan_.collateralTokenId);
        }

        _updateIssuanceParams(issuanceRate - paymentIssuanceRate_, accountedInterest);
    }

    /// @inheritdoc ILoanManager
    function withdrawFunds(uint16 loanId_, address destination_, uint256 amount_) external override whenNotPaused {
        Loan.Info memory loan_ = _loans[loanId_];

        // Only the seller can drawdown funds
        if (msg.sender != loan_.seller) {
            revert Errors.LoanManager_CallerNotSeller({ expectedSeller_: loan_.seller });
        }

        if (amount_ > loan_.drawableFunds) {
            revert Errors.LoanManager_Overdraw({
                loanId_: loanId_,
                amount_: amount_,
                withdrawableAmount_: loan_.drawableFunds
            });
        }

        loan_.drawableFunds -= amount_;

        IERC721(loan_.collateralAsset).safeTransferFrom(msg.sender, address(this), loan_.collateralTokenId);

        // check if the loan is already be repaid
        if (paymentIdOf[loanId_] == 0) {
            IReceivable(loan_.collateralAsset).burnReceivable(loan_.collateralTokenId);
        }

        IERC20(fundsAsset).safeTransfer(destination_, amount_);

        emit FundsWithdrawn({ loanId_: loanId_, amount_: amount_ });
    }

    /// @inheritdoc ILoanManager
    function impairLoan(uint16 loanId_) external override whenNotPaused onlyPoolAdminOrGovernor {
        Loan.Info memory loan_ = _loans[loanId_];

        if (loan_.isImpaired) {
            revert Errors.LoanManager_LoanImpaired({ loanId_: loanId_ });
        }

        uint256 paymentId_ = paymentIdOf[loanId_];

        if (paymentId_ == 0) {
            revert Errors.LoanManager_NotLoan({ loanId_: loanId_ });
        }

        Loan.PaymentInfo memory paymentInfo_ = payments[paymentId_];

        _advanceGlobalPaymentAccounting();

        _removePaymentFromList(paymentId_);

        // Use issuance rate from payment info in storage, because it would
        // already if late have been set to zero and accounted for
        _updateIssuanceParams(issuanceRate - payments[paymentId_].issuanceRate, accountedInterest);

        (uint256 netInterest_, uint256 netLateInterest_, uint256 protocolFees_) =
            _getDefaultInterestAndFees(loanId_, paymentInfo_);

        liquidationInfoFor[loanId_] = Loan.LiquidationInfo({
            triggeredByGovernor: msg.sender == _governor(),
            principal: loan_.principal.toUint128(),
            interest: netInterest_.toUint120(),
            lateInterest: netLateInterest_,
            protocolFees: protocolFees_.toUint96()
        });

        emit UnrealizedLossesUpdated(unrealizedLosses += (loan_.principal + netInterest_).toUint128());

        // Update date on loan data structure
        uint256 originalDueDate_ = loan_.dueDate;

        // if payment is late, do not change the payment due date
        uint256 newDueDate_ = _min(block.timestamp, originalDueDate_);

        Loan.Info storage loanStorage_ = _loans[loanId_];

        loanStorage_.dueDate = newDueDate_;
        loanStorage_.originalDueDate = originalDueDate_;
        loanStorage_.isImpaired = true;

        emit LoanImpaired({ loanId_: loanId_, newDueDate_: newDueDate_ });
    }

    /// @inheritdoc ILoanManager
    function removeLoanImpairment(uint16 loanId_)
        external
        override
        nonReentrant
        whenNotPaused
        onlyPoolAdminOrGovernor
    {
        Loan.LiquidationInfo memory liquidationInfo_ = liquidationInfoFor[loanId_];
        Loan.Info memory loan_ = _loans[loanId_];

        _advanceGlobalPaymentAccounting();

        uint24 paymentId_ = paymentIdOf[loanId_];

        if (paymentId_ == 0) {
            revert Errors.LoanManager_NotLoan(loanId_);
        }

        Loan.PaymentInfo memory paymentInfo_ = payments[paymentId_];

        _reverseLoanImpairment(liquidationInfo_);

        delete liquidationInfoFor[loanId_];
        delete payments[paymentId_];

        payments[paymentIdOf[loanId_] = _addPaymentToList(paymentInfo_.dueDate)] = paymentInfo_;

        // Update missing interest as if payment was always part of the list
        _updateIssuanceParams(
            issuanceRate + paymentInfo_.issuanceRate,
            accountedInterest
                + SafeCast.toUint112(
                    _getPaymentAccruedInterest(paymentInfo_.startDate, block.timestamp, paymentInfo_.issuanceRate)
                )
        );

        // Update date on loan data structure
        uint256 originalDueDate_ = loan_.originalDueDate;

        if (!loan_.isImpaired) {
            revert Errors.LoanManager_LoanNotImpaired({ loanId_: loanId_ });
        }

        if (block.timestamp > originalDueDate_) {
            revert Errors.LoanManager_PastDueDate({
                loanId_: loanId_,
                dueDate_: originalDueDate_,
                currentTimestamp_: block.timestamp
            });
        }

        _loans[loanId_].dueDate = originalDueDate_;
        delete _loans[loanId_].originalDueDate;

        emit ImpairmentRemoved(loanId_, originalDueDate_);
    }

    /// @inheritdoc ILoanManager
    function triggerDefault(uint16 loanId_)
        external
        override
        whenNotPaused
        onlyPoolAdmin
        returns (uint256 remainingLosses_, uint256 protocolFees_)
    {
        // check if current time is past the due date plus grace period
        if (block.timestamp <= _loans[loanId_].dueDate + _loans[loanId_].gracePeriod) {
            revert Errors.LoanManager_NotPastDueDatePlusGracePeriod({ loanId_: loanId_ });
        }

        uint256 paymentId_ = paymentIdOf[loanId_];

        if (paymentId_ == 0) {
            revert Errors.LoanManager_NotLoan({ loanId_: loanId_ });
        }

        // NOTE: must get payment info prior to advancing payment accounting, becasue that will set issuance rate to 0.
        Loan.PaymentInfo memory paymentInfo_ = payments[paymentId_];
        Loan.Info memory loan_ = _loans[loanId_];

        // This will cause this payment to be removed from the list, so no need to remove it explicitly
        _advanceGlobalPaymentAccounting();

        uint256 netInterest_;
        uint256 netLateInterest_;

        (netInterest_, netLateInterest_, protocolFees_) = loan_.isImpaired
            ? _getInterestAndFeesFromLiquidationInfo(loanId_)
            : _getDefaultInterestAndFees(loanId_, paymentInfo_);

        // Losses of the pool
        remainingLosses_ = _handleDefault(loanId_, netInterest_, netLateInterest_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _getIssuance(uint256 issuanceRate_, uint256 interval_) internal pure returns (uint256 issuance_) {
        issuance_ = (issuanceRate_ * interval_) / PRECISION;
    }

    function _getInterestBreakdown(
        uint256 currentTime_,
        uint256 startDate_,
        uint256 dueDate_,
        uint256 principal_,
        uint256 interestRate_,
        uint256 lateInterestPremiumRate_
    )
        internal
        pure
        returns (uint256[2] memory interest_)
    {
        interest_[0] = _getInterest(principal_, interestRate_, dueDate_ - startDate_);
        interest_[1] = _getLateInterest(currentTime_, principal_, interestRate_, dueDate_, lateInterestPremiumRate_);
    }

    function _getInterest(
        uint256 principal_,
        uint256 interestRate_,
        uint256 interval_
    )
        internal
        pure
        returns (uint256 interest_)
    {
        interest_ = (principal_ * _getPeriodicInterestRate(interestRate_, interval_)) / SCALED_ONE;
    }

    function _getLateInterest(
        uint256 currentTime_,
        uint256 principal_,
        uint256 interestRate_,
        uint256 dueDate_,
        uint256 lateInterestPremiumRate_
    )
        internal
        pure
        returns (uint256 lateInterest_)
    {
        if (currentTime_ <= dueDate_) {
            return 0;
        }

        uint256 fullDaysLate_ = ((currentTime_ - dueDate_ + (1 days - 1)) / 1 days) * 1 days;

        lateInterest_ = _getInterest(principal_, interestRate_ + lateInterestPremiumRate_, fullDaysLate_);
    }

    function _getPeriodicInterestRate(
        uint256 interestRate_,
        uint256 interval_
    )
        internal
        pure
        returns (uint256 periodicInterestRate_)
    {
        periodicInterestRate_ = (interestRate_ * (SCALED_ONE / HUNDRED_PERCENT) * interval_) / uint256(365 days);
    }

    /* Protocol Address View Functions */
    function _poolConfigurator() internal view returns (address poolConfigurator_) {
        poolConfigurator_ = ADDRESSES_PROVIDER.getPoolConfigurator();
    }

    function _globals() internal view returns (address globals_) {
        globals_ = ADDRESSES_PROVIDER.getIsleGlobals();
    }

    function _governor() internal view returns (address governor_) {
        governor_ = IIsleGlobals(_globals()).governor();
    }

    function _poolAdmin() internal view returns (address poolAdmin_) {
        poolAdmin_ = IAdminable(_poolConfigurator()).admin();
    }

    function _pool() internal view returns (address pool_) {
        pool_ = IPoolConfigurator(_poolConfigurator()).pool();
    }

    function _vault() internal view returns (address vault_) {
        vault_ = IIsleGlobals(_globals()).isleVault();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _updateInterestAccounting(int256 accountedInterestAdjustment_, int256 issuanceRateAdjustment_) internal {
        accountedInterest = SignedMath.max(
            ((accountedInterest + accruedInterest()).toInt256() + accountedInterestAdjustment_), 0
        ).toUint256().toUint112();

        domainStart = block.timestamp.toUint40();
        issuanceRate = (SignedMath.max(issuanceRate.toInt256() + issuanceRateAdjustment_, 0)).toUint256();

        emit AccountingStateUpdated(issuanceRate, accountedInterest);
    }

    function _updateUnrealizedLosses(int256 lossesAdjustment_) internal {
        unrealizedLosses = SignedMath.max(unrealizedLosses.toInt256() + lossesAdjustment_, 0).toUint256().toUint128();
        emit UnrealizedLossesUpdated(unrealizedLosses);
    }

    function _updatePrincipalOut(int256 principalOutAdjustment_) internal {
        principalOut = SignedMath.max(principalOut.toInt256() + principalOutAdjustment_, 0).toUint256().toUint128();
        emit PrincipalOutUpdated(principalOut);
    }

    // Clears all state variables to end a loan, but keep seller withdrawal functionality intact
    function _clearLoanAccounting(uint16 loanId_) internal {
        Loan.Info storage loan_ = _loans[loanId_];

        loan_.gracePeriod = uint256(0);
        loan_.interestRate = uint256(0);
        loan_.lateInterestPremiumRate = uint256(0);

        loan_.dueDate = uint256(0);
        loan_.originalDueDate = uint256(0);
    }

    function _advanceGlobalPaymentAccounting() internal {
        uint256 domainEnd_ = domainEnd;

        uint256 accountedInterest_;

        // If the earliest payment in the list is in the past, then the payment accounting must be retroactively updated
        if (domainEnd_ != 0 && block.timestamp > domainEnd_) {
            uint256 paymentId_ = paymentWithEarliestDueDate;

            // Cache variables
            uint256 domainStart_ = domainStart;
            uint256 issuanceRate_ = issuanceRate;

            while (block.timestamp > domainEnd_) {
                uint256 next_ = sortedPayments[paymentId_].next;

                // Account payment that is already in the past
                (uint256 accountedInterestIncrease_, uint256 issuanceRateReduction_) =
                    _accountToEndOfPayment(paymentId_, issuanceRate_, domainStart_, domainEnd_);

                // Update cached aggregate values for updating the global state
                accountedInterest_ += accountedInterestIncrease_;
                issuanceRate_ -= issuanceRateReduction_;

                // Update the domain start and end
                domainStart_ = domainEnd_;
                domainEnd_ = paymentWithEarliestDueDate == 0
                    ? SafeCast.toUint48(block.timestamp)
                    : payments[paymentWithEarliestDueDate].dueDate;

                if ((paymentId_ = next_) == 0) {
                    break;
                }
            }

            domainEnd = SafeCast.toUint48(domainEnd_);
            issuanceRate = issuanceRate_;
        }

        // Account the accrued interest to the accountedInterest
        accountedInterest += SafeCast.toUint112(accountedInterest_ + accruedInterest());
        domainStart = SafeCast.toUint48(block.timestamp);
    }

    function _updateIssuanceParams(uint256 issuanceRate_, uint112 accountedInterest_) internal {
        uint256 earliestPayment_ = paymentWithEarliestDueDate;

        // Set end domain to current time if there are no payments left, else set it to the earliest payment's due date
        emit IssuanceParamsUpdated(
            domainEnd = earliestPayment_ == 0 ? block.timestamp.toUint48() : payments[earliestPayment_].dueDate,
            issuanceRate = issuanceRate_,
            accountedInterest = accountedInterest_
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                    INTERNAL LOAN ACCOUNTING HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _compareAndSubtractAccountedInterest(uint256 amount_) internal {
        // Rounding errors accrue in `accountedInterest` when _loans are late and the issuance rate is used to calculate
        // the interest more often to increment than to decrement.
        // When this is the case, the underflow is prevented on the last decrement by using the minimum of the two
        // values below.
        accountedInterest -= SafeCast.toUint112(_min(accountedInterest, amount_));
    }

    function _getAccruedAmount(
        uint256 totalAccruingAmount_,
        uint256 startTime_,
        uint256 endTime_,
        uint256 currentTime_
    )
        internal
        pure
        returns (uint256 accruedAmount_)
    {
        accruedAmount_ = totalAccruingAmount_ * (currentTime_ - startTime_) / (endTime_ - startTime_);
    }

    function _getDefaultInterestAndFees(
        uint16 loanId_,
        Loan.PaymentInfo memory paymentInfo_
    )
        internal
        view
        returns (uint256 netInterest_, uint256 netLateInterest_, uint256 protocolFees_)
    {
        // Accrue the interest only up to the current time if the payment due date has not been reached yet.
        // Note: Issuance Rate in paymentInfo is netRate
        netInterest_ = paymentInfo_.issuanceRate == 0
            ? paymentInfo_.incomingNetInterest
            : _getPaymentAccruedInterest({
                startTime_: paymentInfo_.startDate,
                endTime_: _min(paymentInfo_.dueDate, block.timestamp),
                paymentIssuanceRate_: paymentInfo_.issuanceRate
            });

        // Gross interest, which means it is not just to the current timestamp but to the due date
        (, uint256[2] memory grossInterest_) = getLoanPaymentDetailedBreakdown(loanId_);

        uint256 grossLateInterest_ = grossInterest_[1];

        netLateInterest_ = _getNetInterest(grossLateInterest_, paymentInfo_.protocolFee + paymentInfo_.adminFee);

        protocolFees_ = (grossInterest_[0] + grossLateInterest_) * paymentInfo_.protocolFee / HUNDRED_PERCENT;

        // If the payment is early, scale back the management fees pro-rata based on the current timestamp
        if (grossLateInterest_ == 0) {
            protocolFees_ =
                _getAccruedAmount(protocolFees_, paymentInfo_.startDate, paymentInfo_.dueDate, block.timestamp);
        }
    }

    function _getInterestAndFeesFromLiquidationInfo(uint16 loanId_)
        internal
        view
        returns (uint256 netInterest_, uint256 netLateInterest_, uint256 protocolFees_)
    {
        Loan.LiquidationInfo memory liquidationInfo_ = liquidationInfoFor[loanId_];

        netInterest_ = liquidationInfo_.interest;
        netLateInterest_ = liquidationInfo_.lateInterest;
        protocolFees_ = liquidationInfo_.protocolFees;
    }

    function _getNetInterest(uint256 interest_, uint256 feeRate_) internal pure returns (uint256 netInterest_) {
        netInterest_ = interest_ * (HUNDRED_PERCENT - feeRate_) / HUNDRED_PERCENT;
    }

    function _getPaymentAccruedInterest(
        uint256 startTime_,
        uint256 endTime_,
        uint256 paymentIssuanceRate_
    )
        internal
        pure
        returns (uint256 accruedInterest_)
    {
        accruedInterest_ = (endTime_ - startTime_) * paymentIssuanceRate_ / PRECISION;
    }

    /*//////////////////////////////////////////////////////////////////////////
                    INTERNAL PAYMENT ACCOUNTING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _accountToEndOfPayment(
        uint256 paymentId_,
        uint256 issuanceRate_,
        uint256 intervalStart_,
        uint256 intervalEnd_
    )
        internal
        returns (uint256 accountedInterestIncrease_, uint256 issuanceRateReduction_)
    {
        Loan.PaymentInfo memory payment_ = payments[paymentId_];

        _removePaymentFromList(paymentId_);

        issuanceRateReduction_ = payment_.issuanceRate;

        accountedInterestIncrease_ = (intervalEnd_ - intervalStart_) * issuanceRate_ / PRECISION;

        payments[paymentId_].issuanceRate = 0;
    }

    function _deletePayment(uint16 loanId_) internal {
        delete payments[paymentIdOf[loanId_]];
        delete paymentIdOf[loanId_];
    }

    function _handlePaymentAccounting(uint16 loanId_) internal returns (uint256 issuanceRate_) {
        Loan.LiquidationInfo memory liquidationInfo_ = liquidationInfoFor[loanId_];

        uint256 paymentId_ = paymentIdOf[loanId_];

        if (paymentId_ == 0) {
            revert Errors.LoanManager_NotLoan(loanId_);
        }

        // Remove the payment from the mapping once cached in memory
        Loan.PaymentInfo memory paymentInfo_ = payments[paymentId_];
        delete payments[paymentId_];

        emit PaymentRemoved({ loanId_: loanId_, paymentId_: paymentId_ });

        // If the payment has been made against a loan that was impaired, reverse the impairment accounting
        if (liquidationInfo_.principal != 0) {
            _reverseLoanImpairment(liquidationInfo_);
            delete liquidationInfoFor[loanId_];
            return 0;
        }

        // If a payment has been made late, its interest has already been fully accounted through
        // `advanceGlobalAccounting` logic.
        // It also has been removed from the sorted list, and its `issuanceRate` has been removed from the global
        // `issuanceRate`
        // The only accounting that must be done is to update the `accountedInterest` to account for the payment being
        // made
        if (block.timestamp > paymentInfo_.dueDate) {
            _compareAndSubtractAccountedInterest(paymentInfo_.incomingNetInterest);
            return 0;
        }

        _removePaymentFromList(paymentId_);
        issuanceRate_ = paymentInfo_.issuanceRate;

        // If the amount of interest claimed is greater than the amount accounted for, set to zero.
        // Discrepancy between accounted and actual is always captured by balance change in the pool from claimed
        // interest.
        // Reduce the AUM by the amount of interest that was represented for this payment
        _compareAndSubtractAccountedInterest(((block.timestamp - paymentInfo_.startDate) * issuanceRate_) / PRECISION);
    }

    function _queuePayment(uint16 loanId_, uint256 startDate_, uint256 dueDate_) internal returns (uint256 newRate_) {
        uint256 protocolFee_ = IIsleGlobals(_globals()).protocolFee();
        uint256 adminFee_ = IPoolConfigurator(_poolConfigurator()).adminFee();
        uint256 feeRate_ = protocolFee_ + adminFee_;

        Loan.Info memory loan_ = _loans[loanId_];

        uint256 interest_ = _getInterest(loan_.principal, loan_.interestRate, dueDate_ - startDate_);
        newRate_ = (_getNetInterest(interest_, feeRate_) * PRECISION) / (dueDate_ - startDate_);

        // Add the payment to the sorted list
        uint256 paymentId_ = paymentIdOf[loanId_] = _addPaymentToList(SafeCast.toUint48(dueDate_));

        payments[paymentId_] = Loan.PaymentInfo({
            protocolFee: SafeCast.toUint24(protocolFee_),
            adminFee: SafeCast.toUint24(adminFee_),
            startDate: SafeCast.toUint48(startDate_),
            dueDate: SafeCast.toUint48(dueDate_),
            incomingNetInterest: SafeCast.toUint128(newRate_ * (dueDate_ - startDate_) / PRECISION),
            issuanceRate: newRate_
        });

        emit PaymentAdded(loanId_, paymentId_, protocolFee_, adminFee_, startDate_, dueDate_, newRate_);
    }

    function _reverseLoanImpairment(Loan.LiquidationInfo memory liquidationInfo_) internal {
        _compareAndSubtractAccountedInterest(liquidationInfo_.interest);
        unrealizedLosses -= SafeCast.toUint128(liquidationInfo_.principal + liquidationInfo_.interest);

        emit UnrealizedLossesUpdated(unrealizedLosses);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INTERNAL PAYMENT SORTING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _addPaymentToList(uint48 paymentDueDate_) internal returns (uint24 paymentId_) {
        paymentId_ = ++paymentCounter;

        uint24 current_ = uint24(0);
        uint24 next_ = paymentWithEarliestDueDate;

        // Find the first payment next_, in the list that has a due date later than the payment being added
        // Insert the payment before next_, and after current_
        while (next_ != 0 && paymentDueDate_ >= sortedPayments[next_].paymentDueDate) {
            current_ = next_;
            next_ = sortedPayments[current_].next;
        }

        if (current_ != 0) {
            sortedPayments[current_].next = paymentId_;
        } else {
            paymentWithEarliestDueDate = paymentId_;
        }

        if (next_ != 0) {
            sortedPayments[next_].previous = paymentId_;
        }

        sortedPayments[paymentId_] =
            Loan.SortedPayment({ previous: current_, next: next_, paymentDueDate: paymentDueDate_ });
    }

    function _removePaymentFromList(uint256 paymentId_) internal {
        Loan.SortedPayment memory sortedPayment_ = sortedPayments[paymentId_];

        uint24 previous_ = sortedPayment_.previous;
        uint24 next_ = sortedPayment_.next;

        if (paymentWithEarliestDueDate == paymentId_) {
            paymentWithEarliestDueDate = next_;
        }

        if (next_ != 0) {
            sortedPayments[next_].previous = previous_;
        }

        if (previous_ != 0) {
            sortedPayments[previous_].next = next_;
        }

        delete sortedPayments[paymentId_];
    }

    /*//////////////////////////////////////////////////////////////////////////
                        INTERNAL FUNDS DISTRIBUTION FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _distributeClaimedFunds(uint16 loanId_, uint256 principal_, uint256 interest_) internal {
        uint256 paymentId_ = paymentIdOf[loanId_];

        if (paymentId_ == 0) {
            revert Errors.LoanManager_NotLoan(loanId_);
        }

        uint256 protocolFee_ = interest_ * payments[paymentId_].protocolFee / HUNDRED_PERCENT;

        uint256 adminFee_ = IPoolConfigurator(_poolConfigurator()).hasSufficientCover()
            ? interest_ * payments[paymentId_].adminFee / HUNDRED_PERCENT
            : 0;

        uint256 netInterest_ = interest_ - protocolFee_ - adminFee_;

        emit FeesPaid(loanId_, adminFee_, protocolFee_);
        emit FundsDistributed(loanId_, principal_, netInterest_);

        address fundsAsset_ = fundsAsset;

        IERC20(fundsAsset_).safeTransfer(_pool(), principal_ + netInterest_);
        IERC20(fundsAsset_).safeTransfer(_poolAdmin(), adminFee_);
        IERC20(fundsAsset_).safeTransfer(_vault(), protocolFee_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                    INTERNAL LOAN DEFAULT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _handleDefault(
        uint16 loanId_,
        uint256 netInterest_,
        uint256 netLateInterest_
    )
        internal
        returns (uint256 remainingLosses_)
    {
        Loan.Info memory loan_ = _loans[loanId_];

        uint256 principal_ = loan_.principal;

        // Reduce principal out, since it has been accounted for in the liquidation
        emit PrincipalOutUpdated(principalOut -= principal_.toUint128());

        // Calculate the late interest if a late payment was made
        remainingLosses_ = principal_ + netInterest_ + netLateInterest_;

        if (loan_.isImpaired) {
            // Remove unrealized losses that `impairLoan` previously accounted for
            emit UnrealizedLossesUpdated(unrealizedLosses -= (principal_ + netInterest_).toUint128());
            delete liquidationInfoFor[loanId_];
        }

        _compareAndSubtractAccountedInterest(netInterest_);

        _updateIssuanceParams(issuanceRate, accountedInterest);

        _deletePayment(loanId_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            REVERT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _revertIfPaused() internal view {
        if (IIsleGlobals(_globals()).isFunctionPaused(msg.sig)) {
            revert Errors.FunctionPaused(msg.sig);
        }
    }

    function _revertIfNotPoolAdminOrGovernor() internal view {
        if (msg.sender != _poolAdmin() && msg.sender != _governor()) {
            revert Errors.NotPoolAdminOrGovernor({ caller_: msg.sender });
        }
    }

    function _revertIfNotPoolAdmin() internal view {
        if (msg.sender != _poolAdmin()) {
            revert Errors.NotPoolAdmin(msg.sender);
        }
    }

    function _revertIfCallerNotReceivableBuyer(address buyer_) internal view {
        if (msg.sender != buyer_) {
            revert Errors.LoanManager_CallerNotReceivableBuyer({ expectedBuyer_: buyer_ });
        }
    }

    function _revertIfInvalidReceivable(
        uint256 receivablesTokenId_,
        address buyer_,
        address seller_,
        uint256 repaymentTimestamp_
    )
        internal
        view
    {
        IPoolConfigurator poolConfigurator_ = IPoolConfigurator(_poolConfigurator());
        if (
            poolConfigurator_.buyer() != buyer_ || !poolConfigurator_.isSeller(seller_)
                || repaymentTimestamp_ < block.timestamp
        ) {
            revert Errors.LoanManager_InvalidReceivable({ receivablesTokenId_: receivablesTokenId_ });
        }
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 minimum_) {
        minimum_ = a_ < b_ ? a_ : b_;
    }
}

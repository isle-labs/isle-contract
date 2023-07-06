// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { ERC20Helper } from "erc20-helper/ERC20Helper.sol";

import {
    IGlobalsLike,
    ILoanLike,
    ILoanManagerLike,
    IPoolManagerLike
} from "./interfaces/Interfaces.sol";

import { ILopoLoanFeeManager } from "./interfaces/ILopoLoanFeeManager.sol";


contract LopoLoanFeeManager is ILopoLoanFeeManager {

    uint256 internal constant HUNDRED_PERCENT = 100_0000;

    address public override globals;

    mapping(address => uint256) public override delegateOriginationFee;
    mapping(address => uint256) public override delegateRefinanceServiceFee;
    mapping(address => uint256) public override delegateServiceFee;
    mapping(address => uint256) public override platformServiceFee;
    mapping(address => uint256) public override platformRefinanceServiceFee;

    constructor(address globals_) {
        globals = globals_;
    }

    /**************************************************************************************************************************************/
    /*** Payment Functions                                                                                                              ***/
    /**************************************************************************************************************************************/

    function payOriginationFees(address asset_, uint256 principalRequested_) external override returns (uint256 feePaid_) {
        uint256 delegateOriginationFee_ = delegateOriginationFee[msg.sender];
        uint256 platformOriginationFee_ = _getPlatformOriginationFee(msg.sender, principalRequested_);

        // Send origination fee to treasury, with remainder to poolDelegate.
        _transferTo(asset_, _getPoolDelegate(msg.sender), delegateOriginationFee_, "LPFM:POF:PD_TRANSFER");
        _transferTo(asset_, _getTreasury(),               platformOriginationFee_, "LPFM:POF:TREASURY_TRANSFER");

        feePaid_ = delegateOriginationFee_ + platformOriginationFee_;

        emit OriginationFeesPaid(msg.sender, delegateOriginationFee_, platformOriginationFee_);
    }

    function payServiceFees(address asset_, uint256 numberOfPayments_) external override returns (uint256 feePaid_) {
        (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceServiceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceServiceFee_
        ) = getServiceFeeBreakdown(msg.sender, numberOfPayments_);

        feePaid_ = delegateServiceFee_ + delegateRefinanceServiceFee_ + platformServiceFee_ + platformRefinanceServiceFee_;

        _transferTo(asset_, _getPoolDelegate(msg.sender), delegateServiceFee_ + delegateRefinanceServiceFee_, "LPFM:PSF:PD_TRANSFER");
        _transferTo(asset_, _getTreasury(),               platformServiceFee_ + platformRefinanceServiceFee_, "LPFM:PSF:TREASURY_TRANSFER");

        // Refinance fees should be only paid once.
        delete delegateRefinanceServiceFee[msg.sender];
        delete platformRefinanceServiceFee[msg.sender];

        emit ServiceFeesPaid(
            msg.sender,
            delegateServiceFee_,
            delegateRefinanceServiceFee_,
            platformServiceFee_,
            platformRefinanceServiceFee_
        );
    }

    /**************************************************************************************************************************************/
    /*** Fee Update Functions                                                                                                           ***/
    /**************************************************************************************************************************************/

    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external override {
        delegateOriginationFee[msg.sender] = delegateOriginationFee_;
        delegateServiceFee[msg.sender]     = delegateServiceFee_;

        emit FeeTermsUpdated(msg.sender, delegateOriginationFee_, delegateServiceFee_);
    }

    function updatePlatformServiceFee(uint256 principalRequested_, uint256 paymentInterval_) external override {
        uint256 platformServiceFee_ = getPlatformServiceFeeForPeriod(msg.sender, principalRequested_, paymentInterval_);

        platformServiceFee[msg.sender] = platformServiceFee_;

        emit PlatformServiceFeeUpdated(msg.sender, platformServiceFee_);
    }

    function updateRefinanceServiceFees(uint256 principalRequested_, uint256 timeSinceLastDueDate_) external override {
        uint256 platformRefinanceServiceFee_ = getPlatformServiceFeeForPeriod(msg.sender, principalRequested_, timeSinceLastDueDate_);
        uint256 delegateRefinanceServiceFee_ = getDelegateServiceFeesForPeriod(msg.sender, timeSinceLastDueDate_);

        platformRefinanceServiceFee[msg.sender] += platformRefinanceServiceFee_;
        delegateRefinanceServiceFee[msg.sender] += delegateRefinanceServiceFee_;

        emit PartialRefinanceServiceFeesUpdated(msg.sender, platformRefinanceServiceFee_, delegateRefinanceServiceFee_);
    }

    /**************************************************************************************************************************************/
    /***  View Functions                                                                                                                ***/
    /**************************************************************************************************************************************/

    function getDelegateServiceFeesForPeriod(address loan_, uint256 interval_) public view override returns (uint256 delegateServiceFee_) {
        uint256 paymentInterval_ = ILoanLike(loan_).paymentInterval();

        delegateServiceFee_ = delegateServiceFee[loan_] * interval_ / paymentInterval_;
    }

    function getOriginationFees(address loan_, uint256 principalRequested_) external view override returns (uint256 originationFees_) {
        originationFees_ = _getPlatformOriginationFee(loan_, principalRequested_) + delegateOriginationFee[loan_];
    }

    function getPlatformOriginationFee(address loan_, uint256 principalRequested_)
        external view override returns (uint256 platformOriginationFee_)
    {
        platformOriginationFee_ =  _getPlatformOriginationFee(loan_, principalRequested_);
    }

    function getPlatformServiceFeeForPeriod(address loan_, uint256 principalRequested_, uint256 interval_)
        public view override returns (uint256 platformServiceFee_)
    {
        uint256 platformServiceFeeRate_ = IGlobalsLike(globals).platformServiceFeeRate(_getPoolManager(loan_));
        platformServiceFee_             = principalRequested_ * platformServiceFeeRate_ * interval_ / 365 days / HUNDRED_PERCENT;
    }

    function getServiceFees(address loan_, uint256 numberOfPayments_) external view override returns (uint256 serviceFees_) {
        (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceServiceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceServiceFee_
        ) = getServiceFeeBreakdown(loan_, numberOfPayments_);

        serviceFees_ = delegateServiceFee_ + delegateRefinanceServiceFee_ + platformServiceFee_ + platformRefinanceServiceFee_;
    }

    function getServiceFeeBreakdown(address loan_, uint256 numberOfPayments_) public view override
        returns (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceFee_
        )
    {
        delegateServiceFee_   = delegateServiceFee[loan_] * numberOfPayments_;
        platformServiceFee_   = platformServiceFee[loan_] * numberOfPayments_;
        delegateRefinanceFee_ = delegateRefinanceServiceFee[loan_];
        platformRefinanceFee_ = platformRefinanceServiceFee[loan_];
    }

    function getServiceFeesForPeriod(address loan_, uint256 interval_) external view override returns (uint256 serviceFee_) {
        uint256 principalRequested_ = ILoanLike(loan_).principalRequested();

        serviceFee_ =
            getDelegateServiceFeesForPeriod(loan_, interval_) +
            getPlatformServiceFeeForPeriod(loan_, principalRequested_, interval_);
    }

    /**************************************************************************************************************************************/
    /*** Internal View Functions                                                                                                        ***/
    /**************************************************************************************************************************************/

    function _getAsset(address loan_) internal view returns (address asset_) {
        return ILoanLike(loan_).fundsAsset();
    }

    function _getPlatformOriginationFee(address loan_, uint256 principalRequested_)
        internal view returns (uint256 platformOriginationFee_)
    {
        uint256 platformOriginationFeeRate_ = IGlobalsLike(globals).platformOriginationFeeRate(_getPoolManager(loan_));
        uint256 loanTermLength_             = ILoanLike(loan_).paymentInterval() * ILoanLike(loan_).paymentsRemaining();

        platformOriginationFee_ = platformOriginationFeeRate_ * principalRequested_ * loanTermLength_ / 365 days / HUNDRED_PERCENT;
    }

    function _getPoolManager(address loan_) internal view returns (address pool_) {
        return ILoanManagerLike(ILoanLike(loan_).lender()).poolManager();
    }

    function _getPoolDelegate(address loan_) internal view returns (address poolDelegate_) {
        return IPoolManagerLike(_getPoolManager(loan_)).poolDelegate();
    }

    function _getTreasury() internal view returns (address lopoTreasury_) {
        return IGlobalsLike(globals).lopoTreasury();
    }

    /**************************************************************************************************************************************/
    /*** Internal Helper Functions                                                                                                      ***/
    /**************************************************************************************************************************************/

    function _transferTo(address asset_, address destination_, uint256 amount_, string memory errorMessage_) internal {
        require(destination_ != address(0), "LPFM:TT:ZERO_DESTINATION");
        require(ERC20Helper.transferFrom(asset_, msg.sender, destination_, amount_), errorMessage_);
    }

}

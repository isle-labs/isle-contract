// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IERC20 } from "../../../erc20/interfaces/IERC20.sol";

contract MockGlobals {

    bool internal _isFunctionPaused;

    address public governor;
    address public lopoTreasury;
    address public securityAdmin;

    bool public protocolPaused;

    mapping(address => uint256) public platformOriginationFeeRate;
    mapping(address => uint256) public platformServiceFeeRate;

    mapping(address => bool) public isBorrower;
    mapping(address => bool) public isCollateralAsset;
    mapping(address => bool) public isPoolAsset;

    bool internal _isInstanceOf;

    constructor (address governor_) {
        governor   = governor_;
    }

    function isFunctionPaused(bytes4) external view returns (bool isFunctionPaused_) {
        isFunctionPaused_ = _isFunctionPaused;
    }

    function isInstanceOf(bytes32, address) external view returns (bool) {
        return _isInstanceOf;
    }

    function setGovernor(address governor_) external {
        governor = governor_;
    }

    function setLopoTreasury(address lopoTreasury_) external {
        lopoTreasury = lopoTreasury_;
    }

    function setPlatformOriginationFeeRate(address poolManager_, uint256 feeRate_) external {
        platformOriginationFeeRate[poolManager_] = feeRate_;
    }

    function setPlatformServiceFeeRate(address poolManager_, uint256 feeRate_) external {
        platformServiceFeeRate[poolManager_] = feeRate_;
    }

    function setProtocolPaused(bool paused_) external {
        protocolPaused = paused_;
    }

    function setValidBorrower(address borrower_, bool isValid_) external {
        isBorrower[borrower_] = isValid_;
    }

    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external {
        isCollateralAsset[collateralAsset_] = isValid_;
    }

    function setValidPoolAsset(address poolAsset_, bool isValid_) external {
        isPoolAsset[poolAsset_] = isValid_;
    }

    function __setFunctionPaused(bool paused_) external {
        _isFunctionPaused = paused_;
    }

    function __setIsInstanceOf(bool isInstanceOf_) external {
        _isInstanceOf = isInstanceOf_;
    }

    function __setSecurityAdmin(address securityAdmin_) external {
        securityAdmin = securityAdmin_;
    }

}

contract MockFactory {

    address public lopoGlobals;

    constructor(address lopoGlobals_) {
        lopoGlobals = lopoGlobals_;
    }

    function setGlobals(address globals_) external {
        lopoGlobals = globals_;
    }

    function upgradeInstance(uint256 , bytes calldata arguments_) external {
        address implementation = abi.decode(arguments_, (address));

        ( bool success, ) = msg.sender.call(abi.encodeWithSignature("setImplementation(address)", implementation));

        require(success);
    }

}

contract MockLoanManagerFactory {

    bool internal _isInstance;

    constructor() {
        _isInstance = true;
    }

    function isInstance(address) external view returns (bool) {
        return _isInstance;
    }

    function __setIsInstance(bool isInstance_) external {
        _isInstance = isInstance_;
    }

}

contract MockFeeManager {

    uint256 internal _delegateServiceFee;
    uint256 internal _platformServiceFee;
    uint256 internal _delegateRefinanceFee;
    uint256 internal _platformRefinanceFee;
    uint256 internal _serviceFeesToPay;

    function payOriginationFees(address asset_, uint256 principalRequested_) external returns (uint256 feePaid_) { }

    function payServiceFees(address asset_, uint256 paymentsRemaining_) external returns (uint256 feePaid_) {
        if (_serviceFeesToPay == 0) return 0;

        IERC20(asset_).transferFrom(msg.sender, address(this), feePaid_ = _serviceFeesToPay);
    }

    function updateDelegateFeeTerms(uint256 delegateOriginationFee_, uint256 delegateServiceFee_) external { }

    function updatePlatformServiceFee(uint256 principalRequested_, uint256 paymentInterval_) external { }

    function updateRefinanceServiceFees(uint256 principalRequested_, uint256 timeSinceLastDueDate_) external { }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function delegateRefinanceFee(address) public view returns (uint256 delegateRefinanceFee_) {
        delegateRefinanceFee_ = _delegateRefinanceFee;
    }

    function delegateServiceFee(address) public view returns (uint256 delegateServiceFee_) {
        delegateServiceFee_ = _delegateServiceFee;
    }

    function platformRefinanceFee(address) public view returns (uint256 platformRefinanceFee_) {
        platformRefinanceFee_ = _platformRefinanceFee;
    }

    function platformServiceFee(address) public view returns (uint256 platformServiceFee_) {
        platformServiceFee_ = _platformServiceFee;
    }

    function getServiceFees(address, uint256) external pure returns (uint256 serviceFees_) {
        return 0;
    }

    function getServiceFeeBreakdown(address, uint256) external view
        returns (
            uint256 delegateServiceFee_,
            uint256 delegateRefinanceFee_,
            uint256 platformServiceFee_,
            uint256 platformRefinanceFee_
        )
    {
        delegateServiceFee_   = _delegateServiceFee;
        platformServiceFee_   = _platformServiceFee;
        delegateRefinanceFee_ = _delegateRefinanceFee;
        platformRefinanceFee_ = _platformRefinanceFee;
    }

    function getServiceFeesForPeriod(address, uint256) external pure returns (uint256 serviceFee_) {
        return 0;
    }

    function __setDelegateServiceFee(uint256 delegateServiceFee_) external {
        _delegateServiceFee = delegateServiceFee_;
    }

    function __setDelegateRefinanceFee(uint256 delegateRefinanceFee_) external {
        _delegateRefinanceFee = delegateRefinanceFee_;
    }

    function __setPlatformRefinanceFee(uint256 platformRefinanceFee_) external {
        _platformRefinanceFee = platformRefinanceFee_;
    }

    function __setPlatformServiceFee(uint256 platformServiceFee_) external {
        _platformServiceFee = platformServiceFee_;
    }

    function __setServiceFeesToPay(uint256 serviceFeesToPay_) external {
        _serviceFeesToPay = serviceFeesToPay_;
    }

}

contract MockLoanManager {

    address public factory;
    address public fundsAsset;
    address public poolManager;

    constructor() {
        factory     = address(new MockLoanManagerFactory());
        poolManager = address(new MockPoolManager(address(1)));
    }

    function claim(uint256 principal_, uint256 interest_, uint256 previousPaymentDueDate_, uint256 nextPaymentDueDate_) external { }

    function __setPoolManager(address poolManager_) external {
        poolManager = poolManager_;
    }

    function __setFundsAsset(address asset_) external {
        fundsAsset = asset_;
    }

}

contract MockPoolManager {

    address public poolDelegate;

    constructor(address poolDelegate_) {
        poolDelegate = poolDelegate_;
    }

}

contract EmptyContract {

    fallback() external { }

}

contract RevertingERC20 {

    mapping(address => uint256) public balanceOf;

    function mint(address to_, uint256 value_) external {
        balanceOf[to_] += value_;
    }

    function approve(address, uint256) external pure returns (bool) {
        revert();
    }

    function transfer(address, uint256) external pure returns (bool) {
        revert();
    }

}

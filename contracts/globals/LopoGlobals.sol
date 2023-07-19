// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

contract LopoGlobals is ILopoGlobals {
    /**
     * Structs **
     */

    struct PoolDelegate {
        address ownedPoolManager;
        bool isPoolDelegate;
    }

    /**
     * Storage **
     */

    address public override lopoVault;
    address public override migrationAdmin;
    address public override pendingLopoGovernor;

    bool public override protocolPaused;

    // configs share by all pools
    UD60x18 public override riskFreeRate;
    UD60x18 public override minPoolLiquidityRatio;
    UD60x18 public override protocolFeeRate;

    mapping(address => bool) public override isReceivable;
    mapping(address => bool) public override isBorrower;
    mapping(address => bool) public override isCollateralAsset;
    mapping(address => bool) public override isPoolAsset;

    // configs by poolManager
    mapping(address => bool) public override isEnabled;
    mapping(address => UD60x18) public override minDepositLimit;
    mapping(address => uint256) public override withdrawalDurationInDays;
    // mapping(address => address) public override insurancePool; // this should be implemented in other place
    mapping(address => uint256) public override maxCoverLiquidationPercent;
    mapping(address => uint256) public override minCoverAmount;
    mapping(address => uint256) public override exitFeePercent;
    mapping(address => uint256) public override insuranceFeePercent;

    mapping(address => PoolDelegate) public override poolDelegates;

    /**
     * Modifiers **
     */

    modifier onlyGovernor() {
        _checkIsLopoGovernor();
        _;
    }

    /**
     * Governor Transfer Functions **
     */

    function acceptLopoGovernor() external override {
        require(msg.sender == pendingLopoGovernor, "LG:Caller_Not_Pending_Gov");
        // emit GovernorshipAccepted(admin(), msg.sender);
        pendingLopoGovernor = address(0);
        // lopoGovernor = msg.sender;
        // _setAddress(ADMIN_SLOT, msg.sender);
    }

    function setPendingLopoGovernor(address _pendingGovernor) external override onlyGovernor {
        emit PendingGovernorSet(pendingLopoGovernor = _pendingGovernor);
    }

    /**
     * Global Setters **
     */

    function activatePoolManager(address _poolManager) external override onlyGovernor {

    }

    function setLopoVault(address _vault) external override onlyGovernor {
        require(_vault != address(0), "LG:Invalid_Vault");
        emit LopoVaultSet(lopoVault, _vault);
        lopoVault = _vault;
    }

    // function setMigrationAdmin(address _migrationAdmin) external override onlyGovernor {
    //     emit MigrationAdminSet(migrationAdmin, _migrationAdmin);
    //     migrationAdmin = _migrationAdmin;
    // }

    /**
     * Boolean Setters **
     */

    function setProtocolPause(bool _protocolPaused) external override onlyGovernor {
        emit ProtocolPauseSet(msg.sender, protocolPaused = _protocolPaused);
    }

    /**
     * Allowlist Setters **
     */

    function setIsEnabled(address _poolManager, bool _isEnabled) external override onlyGovernor {
        isEnabled[_poolManager] = _isEnabled;
        emit IsEnabledSet(_poolManager, _isEnabled);
    }

    function setValidReceivable(address _receivable, bool _isValid) external override onlyGovernor {
        require(_receivable != address(0), "LG:SVPD:ZERO_ADDR");
        isReceivable[_receivable] = _isValid;
        emit ValidReceivableSet(_receivable, _isValid);
    }


    function setValidBorrower(address _borrower, bool _isValid) external override onlyGovernor {
        isBorrower[_borrower] = _isValid;
        emit ValidBorrowerSet(_borrower, _isValid);
    }

    function setValidCollateralAsset(address _collateralAsset, bool _isValid) external override onlyGovernor {
        isCollateralAsset[_collateralAsset] = _isValid;
        emit ValidCollateralAssetSet(_collateralAsset, _isValid);
    }

    function setValidPoolAsset(address _poolAsset, bool _isValid) external override onlyGovernor {
        isPoolAsset[_poolAsset] = _isValid;
        emit ValidPoolAssetSet(_poolAsset, _isValid);
    }

    function setValidPoolDelegate(address _account, bool _isValid) external override onlyGovernor {
        require(_account != address(0), "LG:SVPD:ZERO_ADDR");

        // Cannot remove pool delegates that own a pool manager.
        require(_isValid || poolDelegates[_account].ownedPoolManager == address(0), "LG:SVPD:OWNS_POOL_MANAGER");

        poolDelegates[_account].isPoolDelegate = _isValid;
        emit ValidPoolDelegateSet(_account, _isValid);
    }

    /**
     * Cover Setters **
     */

    // function setMaxCoverLiquidationPercent(address _poolManager, uint256 _maxCoverLiquidationPercent) external
    // override onlyGovernor {
    //     require(_maxCoverLiquidationPercent <= HUNDRED_PERCENT, "LG:SMCLP:GT_100");
    //     maxCoverLiquidationPercent[_poolManager] = _maxCoverLiquidationPercent;
    //     emit MaxCoverLiquidationPercentSet(_poolManager, _maxCoverLiquidationPercent);
    // }

    // function setMinCoverAmount(address _poolManager, uint256 _minCoverAmount) external override onlyGovernor {
    //     minCoverAmount[_poolManager] = _minCoverAmount;
    //     emit MinCoverAmountSet(_poolManager, _minCoverAmount);
    // }

    /**
     * Fee Setters **
     */

    function setRiskFreeRate(UD60x18 _riskFreeRate) external override onlyGovernor {
        require(_riskFreeRate <= ud(1e18), "LG:SRFR:GT_1");
        emit RiskFreeRateSet(_riskFreeRate.intoUint256());
        riskFreeRate = _riskFreeRate;
    }

    function setMinPoolLiquidityRatio(UD60x18 _minPoolLiquidityRatio) external override onlyGovernor {
        require(_minPoolLiquidityRatio <= ud(1e18), "LG:SMPR:GT_1");
        emit MinPoolLiquidityRatioSet(_minPoolLiquidityRatio.intoUint256());
        minPoolLiquidityRatio = _minPoolLiquidityRatio;
    }

    function setProtocolFeeRate(UD60x18 _protocolFeeRate) external override onlyGovernor {
        require(_protocolFeeRate <= ud(1e18), "LG:SPFR:GT_1");
        emit ProtocolFeeRateSet(_protocolFeeRate.intoUint256());
        protocolFeeRate = _protocolFeeRate;
    }

    /**
     * Pool Restriction Setters **
     */

    function setMinDepositLimit(address _poolManager, UD60x18 _minDepositLimit) external override onlyGovernor {
        emit MinDepositLimitSet(
            _poolManager,  _minDepositLimit.intoUint256()
        );
        minDepositLimit[_poolManager] = _minDepositLimit;
    }

    function setWithdrawalDurationInDays(
        address _poolManager,
        uint256 _withdrawalDurationInDays
    )
        external
        onlyGovernor
    {
        emit WithdrawalDurationInDaysSet(
            _poolManager,  _withdrawalDurationInDays
        );
        withdrawalDurationInDays[_poolManager] = _withdrawalDurationInDays;
    }

    /**
     * View Function **
     */

    function governor() external view override returns (address governor_) {
        // governor_ = admin();
    }

    function isPoolDelegate(address account_) external view override returns (bool isPoolDelegate_) {
        isPoolDelegate_ = poolDelegates[account_].isPoolDelegate;
    }

    function ownedPoolManager(address account_) external view override returns (address poolManager_) {
        poolManager_ = poolDelegates[account_].ownedPoolManager;
    }

    /**
     * Helper Function **
     */

    function _checkIsLopoGovernor() internal view {
        // require(msg.sender == admin(), "LG:Caller_Not_Gov");
    }

    function _setAddress(bytes32 _slot, address _value) private {
        assembly {
            sstore(_slot, _value)
        }
    }
}

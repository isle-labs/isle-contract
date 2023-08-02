// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ILopoGlobals } from "../../contracts/interfaces/ILopoGlobals.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { Errors } from "../../contracts/libraries/Errors.sol";
import { VersionedInitializable } from "../../contracts/libraries/upgradability/VersionedInitializable.sol";
import { Adminable } from "../../contracts/abstracts/Adminable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract MockLopoGlobalsV2 is ILopoGlobals, VersionedInitializable, Adminable, UUPSUpgradeable {
    uint256 public constant LOPO_GLOBALS_REVISION = 0x2;

    /*//////////////////////////////////////////////////////////////////////////
                            UUPS FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernor { }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Struct
    //////////////////////////////////////////////////////////////////////////*/

    struct PoolAdmin {
        address ownedPoolConfigurator;
        bool isPoolAdmin;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Storage
    //////////////////////////////////////////////////////////////////////////*/

    address public override lopoVault;
    address public override pendingLopoGovernor;

    bool public override protocolPaused;

    mapping(address => bool) public isContractPaused;
    mapping(address => mapping(bytes4 => bool)) public isFunctionUnpaused;

    // configs share by all pools
    UD60x18 public override riskFreeRate;
    UD60x18 public override minPoolLiquidityRatio;
    UD60x18 public override protocolFeeRate;

    mapping(address => bool) public override isReceivable;
    mapping(address => bool) public override isBorrower;
    mapping(address => bool) public override isBuyer;
    mapping(address => bool) public override isCollateralAsset;
    mapping(address => bool) public override isPoolAsset;

    // configs by poolConfigurator
    mapping(address => UD60x18) public override minDepositLimit;
    mapping(address => uint256) public override withdrawalDurationInDays;
    // mapping(address => address) public override insurancePool; // this should be implemented in other place
    mapping(address => uint256) public override maxCoverLiquidationPercent;
    mapping(address => uint256) public override minCoverAmount;
    mapping(address => uint256) public override exitFeePercent;
    mapping(address => uint256) public override insuranceFeePercent;

    mapping(address => PoolAdmin) public override poolAdmins;

    /*//////////////////////////////////////////////////////////////////////////
                            Initialization
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(address governor_) external initializer {
        admin = governor_;
        emit Initialized();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = LOPO_GLOBALS_REVISION;
    }

    function isPoolAdmin(address account_) external view override returns (bool isPoolAdmin_) {
        isPoolAdmin_ = poolAdmins[account_].isPoolAdmin;
    }

    function ownedPoolConfigurator(address account_) external view override returns (address poolConfigurator_) {
        poolConfigurator_ = poolAdmins[account_].ownedPoolConfigurator;
    }

    function governor() external view override returns (address governor_) {
        governor_ = admin;
    }

    function isFunctionPaused(bytes4 sig_) external view override returns (bool functionIsPaused_) {
        functionIsPaused_ = isFunctionPaused(msg.sender, sig_);
    }

    function isFunctionPaused(address contract_, bytes4 sig_) public view override returns (bool functionIsPaused_) {
        functionIsPaused_ = (protocolPaused || isContractPaused[contract_]) && !isFunctionUnpaused[contract_][sig_];
    }

    /*//////////////////////////////////////////////////////////////////////////
                            NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function transferOwnedPoolConfigurator(address fromPoolAdmin_, address toPoolAdmin_) external override {
        PoolAdmin storage fromAdmin_ = poolAdmins[fromPoolAdmin_];
        PoolAdmin storage toAdmin_ = poolAdmins[toPoolAdmin_];

        /* Checks */
        address poolConfigurator_ = fromAdmin_.ownedPoolConfigurator; // For caching
        if (poolConfigurator_ != msg.sender) {
            revert Errors.Globals_CallerNotPoolConfigurator(poolConfigurator_, msg.sender);
        }

        if (!toAdmin_.isPoolAdmin) {
            revert Errors.Globals_ToInvalidPoolAdmin(toPoolAdmin_);
        }

        poolConfigurator_ = toAdmin_.ownedPoolConfigurator;
        if (poolConfigurator_ != address(0)) {
            revert Errors.Globals_AlreadyHasConfigurator(toPoolAdmin_, poolConfigurator_);
        }

        fromAdmin_.ownedPoolConfigurator = address(0);
        toAdmin_.ownedPoolConfigurator = msg.sender;

        emit PoolConfiguratorOwnershipTransferred(fromPoolAdmin_, toPoolAdmin_, msg.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            MODIFIER
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyGovernor() {
        _checkIsLopoGovernor();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Governor Transfer Functions
    //////////////////////////////////////////////////////////////////////////*/

    function acceptLopoGovernor() external override {
        if (msg.sender != pendingLopoGovernor) {
            revert Errors.Globals_CallerNotPendingGovernor(pendingLopoGovernor, msg.sender);
        }
        emit GovernorshipAccepted(admin, msg.sender);
        pendingLopoGovernor = address(0);
        admin = msg.sender;
    }

    function setPendingLopoGovernor(address _pendingGovernor) external override onlyGovernor {
        emit PendingGovernorSet(pendingLopoGovernor = _pendingGovernor);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            GLOBALS SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setLopoVault(address _vault) external override onlyGovernor {
        if (lopoVault == address(0)) {
            revert Errors.Globals_InvalidVault(_vault);
        }
        emit LopoVaultSet(lopoVault, _vault);
        lopoVault = _vault;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            BOOLEAN SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setProtocolPause(bool _protocolPaused) external override onlyGovernor {
        emit ProtocolPauseSet(msg.sender, protocolPaused = _protocolPaused);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Allowlist Setters
    //////////////////////////////////////////////////////////////////////////*/

    function setOwnedPoolConfigurator(address _poolAdmin, address _poolConfigurator) external override onlyGovernor {
        PoolAdmin storage admin_ = poolAdmins[_poolAdmin];
        if (admin_.ownedPoolConfigurator != address(0)) {
            revert Errors.Globals_AlreadyHasConfigurator(_poolAdmin, admin_.ownedPoolConfigurator);
        }
        admin_.ownedPoolConfigurator = _poolConfigurator;
        admin_.isPoolAdmin = true;
        emit OwnedPoolConfiguratorSet(_poolAdmin, _poolConfigurator);
    }

    function setValidReceivable(address _receivable, bool _isValid) external override onlyGovernor {
        if (_receivable == address(0)) {
            revert Errors.Globals_InvalidReceivable(_receivable);
        }
        isReceivable[_receivable] = _isValid;
        emit ValidReceivableSet(_receivable, _isValid);
    }

    function setValidBorrower(address _borrower, bool _isValid) external override onlyGovernor {
        isBorrower[_borrower] = _isValid;
        emit ValidBorrowerSet(_borrower, _isValid);
    }

    function setValidBuyer(address _buyer, bool _isValid) external override onlyGovernor {
        isBuyer[_buyer] = _isValid;
        emit ValidBuyerSet(_buyer, _isValid);
    }

    function setValidCollateralAsset(address _collateralAsset, bool _isValid) external override onlyGovernor {
        isCollateralAsset[_collateralAsset] = _isValid;
        emit ValidCollateralAssetSet(_collateralAsset, _isValid);
    }

    function setValidPoolAsset(address _poolAsset, bool _isValid) external override onlyGovernor {
        isPoolAsset[_poolAsset] = _isValid;
        emit ValidPoolAssetSet(_poolAsset, _isValid);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FEE SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setRiskFreeRate(UD60x18 _riskFreeRate) external override onlyGovernor {
        if (_riskFreeRate > ud(1e18)) {
            revert Errors.Globals_RiskFreeRateGreaterThanOne(_riskFreeRate.intoUint256());
        }
        emit RiskFreeRateSet(_riskFreeRate.intoUint256());
        riskFreeRate = _riskFreeRate;
    }

    function setMinPoolLiquidityRatio(UD60x18 _minPoolLiquidityRatio) external override onlyGovernor {
        if (_minPoolLiquidityRatio > ud(1e18)) {
            revert Errors.Globals_MinPoolLiquidityRatioGreaterThanOne(_minPoolLiquidityRatio.intoUint256());
        }
        emit MinPoolLiquidityRatioSet(_minPoolLiquidityRatio.intoUint256());
        minPoolLiquidityRatio = _minPoolLiquidityRatio;
    }

    function setProtocolFeeRate(UD60x18 _protocolFeeRate) external override onlyGovernor {
        if (_protocolFeeRate > ud(1e18)) {
            revert Errors.Globals_ProtocolFeeRateGreaterThanOne(_protocolFeeRate.intoUint256());
        }
        emit ProtocolFeeRateSet(_protocolFeeRate.intoUint256());
        protocolFeeRate = _protocolFeeRate;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            POOL RESTRICTION SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setMinDepositLimit(address _poolConfigurator, UD60x18 _minDepositLimit) external override onlyGovernor {
        emit MinDepositLimitSet(_poolConfigurator, _minDepositLimit.intoUint256());
        minDepositLimit[_poolConfigurator] = _minDepositLimit;
    }

    function setWithdrawalDurationInDays(
        address _poolConfigurator,
        uint256 _withdrawalDurationInDays
    )
        external
        onlyGovernor
    {
        emit WithdrawalDurationInDaysSet(_poolConfigurator, _withdrawalDurationInDays);
        withdrawalDurationInDays[_poolConfigurator] = _withdrawalDurationInDays;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _checkIsLopoGovernor() internal view {
        if (msg.sender != admin) {
            revert Errors.Globals_CallerNotGovernor(admin, msg.sender);
        }
    }

    function upgradeV2Test() public pure returns (string memory) {
        return "Hello World V2";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { Errors } from "./libraries/Errors.sol";
import { Errors } from "./libraries/Errors.sol";

import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";
import { Adminable } from "./abstracts/Adminable.sol";

contract LopoGlobals is ILopoGlobals, VersionedInitializable, Adminable, UUPSUpgradeable {
    uint256 public constant LOPO_GLOBALS_REVISION = 0x1;

    uint256 public constant HUNDRED_PERCENT = 1_000_000; // 100.0000%

    /*//////////////////////////////////////////////////////////////////////////
                            UUPS FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation) internal override onlyGovernor { }

    function getImplementation() external view override returns (address) {
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

    mapping(address => bool) public override isBuyer;
    mapping(address => bool) public isContractPaused;
    mapping(address => mapping(bytes4 => bool)) public isFunctionUnpaused;

    // configs shared by all pools
    uint256 public override riskFreeRate;
    UD60x18 public override minPoolLiquidityRatio;
    uint256 public override gracePeriod;
    uint256 public override lateInterestExcessRate;

    mapping(address => bool) public override isCollateralAsset;
    mapping(address => bool) public override isPoolAsset;
    mapping(address => bool) public override isReceivable;

    // configs by poolAddressesProvider
    mapping(address => bool) public override isEnabled;
    mapping(address => UD60x18) public override minDepositLimit;
    mapping(address => uint256) public override withdrawalDurationInDays;
    // mapping(address => address) public override insurancePool; // this should be implemented in other place
    mapping(address => uint256) public override maxCoverLiquidationPercent;
    mapping(address => uint256) public override minCoverAmount;
    mapping(address => uint256) public override exitFeePercent;
    mapping(address => uint256) public override protocolFeeRate;

    mapping(address => PoolAdmin) public override poolAdmins;

    /*//////////////////////////////////////////////////////////////////////////
                            Initialization
    //////////////////////////////////////////////////////////////////////////*/

    function initialize(address governor_) external override initializer {
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

    /**
     * @dev transfer ownership of poolConfigurator from one poolAdmin to another legal poolAdmin
     * @param fromPoolAdmin_ address of poolAdmin to transfer from
     * @param toPoolAdmin_ address of poolAdmin to transfer to
     * @notice only poolConfigurator can call this function
     * @notice only legal poolAdmin with no poolConfigurator can be transferred to
     */
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

    function setPendingLopoGovernor(address pendingGovernor_) external override onlyGovernor {
        emit PendingGovernorSet(pendingLopoGovernor = pendingGovernor_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            GLOBALS SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setLopoVault(address vault_) external override onlyGovernor {
        if (lopoVault == address(0)) {
            revert Errors.Globals_InvalidVault(vault_);
        }
        emit LopoVaultSet(lopoVault, vault_);
        lopoVault = vault_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            BOOLEAN SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setProtocolPause(bool protocolPaused_) external override onlyGovernor {
        emit ProtocolPauseSet(msg.sender, protocolPaused = protocolPaused_);
    }

    function setContractPause(address contract_, bool contractPaused_) external override onlyGovernor {
        emit ContractPauseSet(msg.sender, contract_, isContractPaused[contract_] = contractPaused_);
    }

    function setFunctionUnpause(
        address contract_,
        bytes4 sig_,
        bool functionUnpaused_
    )
        external
        override
        onlyGovernor
    {
        emit FunctionUnpauseSet(msg.sender, contract_, sig_, isFunctionUnpaused[contract_][sig_] = functionUnpaused_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            Allowlist Setters
    //////////////////////////////////////////////////////////////////////////*/

    function setValidPoolAdmin(address poolAdmin_, bool isValid_) external override onlyGovernor {
        poolAdmins[poolAdmin_].isPoolAdmin = isValid_;
        emit ValidPoolAdminSet(poolAdmin_, isValid_);
    }

    function setPoolConfigurator(address poolAdmin_, address poolConfigurator_) external override onlyGovernor {
        if (!poolAdmins[poolAdmin_].isPoolAdmin) {
            revert Errors.Globals_ToInvalidPoolAdmin(poolAdmin_);
        }
        if (poolAdmins[poolAdmin_].ownedPoolConfigurator != address(0)) {
            revert Errors.Globals_AlreadyHasConfigurator(poolAdmin_, poolAdmins[poolAdmin_].ownedPoolConfigurator);
        }
        if (poolConfigurator_ == address(0)) {
            revert Errors.Globals_ToInvalidPoolConfigurator(poolConfigurator_);
        }
        poolAdmins[poolAdmin_].ownedPoolConfigurator = poolConfigurator_;
        emit PoolConfiguratorSet(poolAdmin_, poolConfigurator_);
    }

    function setValidBuyer(address buyer_, bool isValid_) external override onlyGovernor {
        isBuyer[buyer_] = isValid_;
        emit ValidBuyerSet(buyer_, isValid_);
    }

    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external override onlyGovernor {
        isCollateralAsset[collateralAsset_] = isValid_;
        emit ValidCollateralAssetSet(collateralAsset_, isValid_);
    }

    function setValidPoolAsset(address poolAsset_, bool isValid_) external override onlyGovernor {
        isPoolAsset[poolAsset_] = isValid_;
        emit ValidPoolAssetSet(poolAsset_, isValid_);
    }

    function setValidReceivable(address receivable_, bool isValid_) external override onlyGovernor {
        isReceivable[receivable_] = isValid_;
        emit ValidReceivableSet(receivable_, isValid_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            FEE SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setRiskFreeRate(uint256 riskFreeRate_) external override onlyGovernor {
        // if (riskFreeRate_ > ud(1e18)) {
        //     revert Errors.Globals_RiskFreeRateGreaterThanOne(riskFreeRate_.intoUint256());
        // }
        emit RiskFreeRateSet(riskFreeRate_);
        riskFreeRate = riskFreeRate_;
    }

    function setMinPoolLiquidityRatio(UD60x18 minPoolLiquidityRatio_) external override onlyGovernor {
        if (minPoolLiquidityRatio_ > ud(1e18)) {
            revert Errors.Globals_MinPoolLiquidityRatioGreaterThanOne(minPoolLiquidityRatio_.intoUint256());
        }
        emit MinPoolLiquidityRatioSet(minPoolLiquidityRatio_.intoUint256());
        minPoolLiquidityRatio = minPoolLiquidityRatio_;
    }

    function setProtocolFeeRate(address poolConfigurator_, uint256 protocolFeeRate_) external override onlyGovernor {
        emit ProtocolFeeRateSet(poolConfigurator_, protocolFeeRate_);
        protocolFeeRate[poolConfigurator_] = protocolFeeRate_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            POOL RESTRICTION SETTERS
    //////////////////////////////////////////////////////////////////////////*/

    function setMinCoverAmount(address poolConfigurator_, uint256 minCoverAmount_) external override onlyGovernor {
        emit MinCoverAmountSet(poolConfigurator_, minCoverAmount_);
        minCoverAmount[poolConfigurator_] = minCoverAmount_;
    }

    function setMinDepositLimit(address poolConfigurator_, UD60x18 minDepositLimit_) external override onlyGovernor {
        emit MinDepositLimitSet(poolConfigurator_, minDepositLimit_.intoUint256());
        minDepositLimit[poolConfigurator_] = minDepositLimit_;
    }

    function setWithdrawalDurationInDays(
        address poolConfigurator_,
        uint256 withdrawalDurationInDays_
    )
        external
        override
        onlyGovernor
    {
        emit WithdrawalDurationInDaysSet(poolConfigurator_, withdrawalDurationInDays_);
        withdrawalDurationInDays[poolConfigurator_] = withdrawalDurationInDays_;
    }

    function setMaxCoverLiquidationPercent(
        address poolConfigurator_,
        uint256 maxCoverLiquidationPercent_
    )
        external
        onlyGovernor
    {
        emit MaxCoverLiquidationPercentSet(poolConfigurator_, maxCoverLiquidationPercent_);
        maxCoverLiquidationPercent[poolConfigurator_] = maxCoverLiquidationPercent_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _checkIsLopoGovernor() internal view {
        if (msg.sender != admin) {
            revert Errors.Globals_CallerNotGovernor(admin, msg.sender);
        }
    }
}

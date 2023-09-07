// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { Errors } from "./libraries/Errors.sol";

import { Adminable } from "./abstracts/Adminable.sol";

import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";

contract LopoGlobals is ILopoGlobals, VersionedInitializable, Adminable, UUPSUpgradeable {
    uint256 public constant LOPO_GLOBALS_REVISION = 0x1;
    uint256 public constant HUNDRED_ = 1_000_000; // 100.0000%

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyGovernor() {
        _revertIfNotGovernor();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            UUPS FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address newImplementation_) internal override onlyGovernor { }

    function getImplementation() external view override returns (address implementation_) {
        implementation_ = _getImplementation();
    }

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = LOPO_GLOBALS_REVISION;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Storage
    //////////////////////////////////////////////////////////////////////////*/

    uint24 public override protocolFee;
    address public override lopoVault;

    bool public override protocolPaused;
    mapping(address => bool) public override isContractPaused;
    mapping(address => mapping(bytes4 => bool)) public override isFunctionUnpaused;

    mapping(address => PoolAdmin) public override poolAdmins;
    mapping(address => PoolConfigurator) public override poolConfigurators;
    mapping(address => bool) public override isCollateralAsset;
    mapping(address => bool) public override isPoolAsset;

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ILopoGlobals
    function initialize(address governor_) external override initializer {
        admin = governor_;
        emit Initialized();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ILopoGlobals
    function setLopoVault(address vault_) external override onlyGovernor {
        if (lopoVault == address(0)) {
            revert Errors.Globals_InvalidVault(vault_);
        }
        emit LopoVaultSet(lopoVault, vault_);
        lopoVault = vault_;
    }

    /// @inheritdoc ILopoGlobals
    function setProtocolPaused(bool protocolPaused_) external override onlyGovernor {
        emit ProtocolPausedSet(msg.sender, protocolPaused = protocolPaused_);
    }

    /// @inheritdoc ILopoGlobals
    function setContractPause(address contract_, bool contractPaused_) external override onlyGovernor {
        emit ContractPausedSet(msg.sender, contract_, isContractPaused[contract_] = contractPaused_);
    }

    /// @inheritdoc ILopoGlobals
    function setFunctionUnpaused(
        address contract_,
        bytes4 sig_,
        bool functionUnpaused_
    )
        external
        override
        onlyGovernor
    {
        emit FunctionUnpausedSet(msg.sender, contract_, sig_, isFunctionUnpaused[contract_][sig_] = functionUnpaused_);
    }

    /// @inheritdoc ILopoGlobals
    function setProtocolFee(uint24 protocolFee_) external override onlyGovernor {
        emit ProtocolFeeSet(protocolFee_);
        protocolFee = protocolFee_;
    }

    /// @inheritdoc ILopoGlobals
    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external override onlyGovernor {
        isCollateralAsset[collateralAsset_] = isValid_;
        emit ValidCollateralAssetSet(collateralAsset_, isValid_);
    }

    /// @inheritdoc ILopoGlobals
    function setValidPoolAsset(address poolAsset_, bool isValid_) external override onlyGovernor {
        isPoolAsset[poolAsset_] = isValid_;
        emit ValidPoolAssetSet(poolAsset_, isValid_);
    }

    /// @inheritdoc ILopoGlobals
    function setValidPoolAdmin(address poolAdmin_, bool isValid_) external override onlyGovernor {
        poolAdmins[poolAdmin_].isPoolAdmin = isValid_;
        emit ValidPoolAdminSet(poolAdmin_, isValid_);
    }

    /// @inheritdoc ILopoGlobals
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

    /// @inheritdoc ILopoGlobals
    function setMaxCoverLiquidation(
        address poolConfigurator_,
        uint24 maxCoverLiquidation_
    )
        external
        override
        onlyGovernor
    {
        emit MaxCoverLiquidationSet(poolConfigurator_, maxCoverLiquidation_);
        poolConfigurators[poolConfigurator_].maxCoverLiquidation = maxCoverLiquidation_;
    }

    /// @inheritdoc ILopoGlobals
    function setMinCover(address poolConfigurator_, uint104 minCover_) external override onlyGovernor {
        emit MinCoverSet(poolConfigurator_, minCover_);
        poolConfigurators[poolConfigurator_].minCover = minCover_;
    }

    /// @inheritdoc ILopoGlobals
    function setPoolLimit(address poolConfigurator_, uint104 poolLimit_) external override onlyGovernor {
        emit PoolLimitSet(poolConfigurator_, poolLimit_);
        poolConfigurators[poolConfigurator_].poolLimit = poolLimit_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ILopoGlobals
    function governor() external view override returns (address governor_) {
        governor_ = admin;
    }

    /// @inheritdoc ILopoGlobals
    function isFunctionPaused(address contract_, bytes4 sig_) public view override returns (bool functionIsPaused_) {
        functionIsPaused_ = (protocolPaused || isContractPaused[contract_]) && !isFunctionUnpaused[contract_][sig_];
    }

    /// @inheritdoc ILopoGlobals
    function isFunctionPaused(bytes4 sig_) external view override returns (bool functionIsPaused_) {
        functionIsPaused_ = isFunctionPaused(msg.sender, sig_);
    }

    /// @inheritdoc ILopoGlobals
    function isPoolAdmin(address account_) external view override returns (bool isPoolAdmin_) {
        isPoolAdmin_ = poolAdmins[account_].isPoolAdmin;
    }

    /// @inheritdoc ILopoGlobals
    function ownedPoolConfigurator(address poolAdmin_) external view override returns (address poolConfigurator_) {
        poolConfigurator_ = poolAdmins[poolAdmin_].ownedPoolConfigurator;
    }

    /// @inheritdoc ILopoGlobals
    function maxCoverLiquidation(address poolConfigurator_)
        external
        view
        override
        returns (uint24 maxCoverLiqduidation_)
    {
        maxCoverLiqduidation_ = poolConfigurators[poolConfigurator_].maxCoverLiquidation;
    }

    /// @inheritdoc ILopoGlobals
    function minCover(address poolConfigurator_) external view override returns (uint104 minCover_) {
        minCover_ = poolConfigurators[poolConfigurator_].minCover;
    }

    /// @inheritdoc ILopoGlobals
    function poolLimit(address poolConfigurator_) external view override returns (uint104 poolLimit_) {
        poolLimit_ = poolConfigurators[poolConfigurator_].poolLimit;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _revertIfNotGovernor() internal view {
        if (msg.sender != admin) {
            revert Errors.Globals_CallerNotGovernor(admin, msg.sender);
        }
    }
}

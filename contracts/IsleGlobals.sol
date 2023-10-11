// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { Errors } from "./libraries/Errors.sol";
import { Globals } from "./libraries/types/DataTypes.sol";

import { Adminable } from "./abstracts/Adminable.sol";

import { IIsleGlobals } from "./interfaces/IIsleGlobals.sol";

contract IsleGlobals is IIsleGlobals, VersionedInitializable, Adminable, UUPSUpgradeable {
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
    address public override isleVault;

    bool public override protocolPaused;
    mapping(address => bool) public override isContractPaused;
    mapping(address => mapping(bytes4 => bool)) public override isFunctionUnpaused;

    mapping(address => Globals.PoolAdmin) public override poolAdmins;
    mapping(address => Globals.PoolConfigurator) public override poolConfigurators;
    mapping(address => bool) public override isCollateralAsset;
    mapping(address => bool) public override isPoolAsset;
    mapping(address => bool) public override isPoolBuyer;

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IIsleGlobals
    function initialize(address governor_) external override initializer {
        admin = governor_;
        emit Initialized();
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IIsleGlobals
    function setIsleVault(address vault_) external override onlyGovernor {
        if (vault_ == address(0)) {
            revert Errors.Globals_InvalidVault(vault_);
        }
        emit IsleVaultSet(isleVault, vault_);
        isleVault = vault_;
    }

    /// @inheritdoc IIsleGlobals
    function setProtocolPaused(bool protocolPaused_) external override onlyGovernor {
        emit ProtocolPausedSet(msg.sender, protocolPaused = protocolPaused_);
    }

    /// @inheritdoc IIsleGlobals
    function setContractPaused(address contract_, bool contractPaused_) external override onlyGovernor {
        emit ContractPausedSet(msg.sender, contract_, isContractPaused[contract_] = contractPaused_);
    }

    /// @inheritdoc IIsleGlobals
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

    /// @inheritdoc IIsleGlobals
    function setProtocolFee(uint24 protocolFee_) external override onlyGovernor {
        emit ProtocolFeeSet(protocolFee = protocolFee_);
    }

    /// @inheritdoc IIsleGlobals
    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external override onlyGovernor {
        isCollateralAsset[collateralAsset_] = isValid_;
        emit ValidCollateralAssetSet(collateralAsset_, isValid_);
    }

    /// @inheritdoc IIsleGlobals
    function setValidPoolAsset(address poolAsset_, bool isValid_) external override onlyGovernor {
        isPoolAsset[poolAsset_] = isValid_;
        emit ValidPoolAssetSet(poolAsset_, isValid_);
    }

    /// @inheritdoc IIsleGlobals
    function setValidPoolAdmin(address poolAdmin_, bool isValid_) external override onlyGovernor {
        poolAdmins[poolAdmin_].isPoolAdmin = isValid_;
        emit ValidPoolAdminSet(poolAdmin_, isValid_);
    }

    function setValidPoolBuyer(address poolBuyer_, bool isValid_) external override onlyGovernor {
        isPoolBuyer[poolBuyer_] = isValid_;
        emit ValidPoolBuyerSet(poolBuyer_, isValid_);
    }

    /// @inheritdoc IIsleGlobals
    function setPoolConfigurator(address poolAdmin_, address poolConfigurator_) external override onlyGovernor {
        if (!poolAdmins[poolAdmin_].isPoolAdmin) {
            revert Errors.Globals_ToInvalidPoolAdmin(poolAdmin_);
        }
        if (poolAdmins[poolAdmin_].ownedPoolConfigurator != address(0)) {
            revert Errors.Globals_AlreadyOwnsConfigurator(poolAdmin_, poolAdmins[poolAdmin_].ownedPoolConfigurator);
        }
        if (poolConfigurator_ == address(0)) {
            revert Errors.Globals_ToInvalidPoolConfigurator(poolConfigurator_);
        }
        poolAdmins[poolAdmin_].ownedPoolConfigurator = poolConfigurator_;
        emit PoolConfiguratorSet(poolAdmin_, poolConfigurator_);
    }

    /// @inheritdoc IIsleGlobals
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

    /// @inheritdoc IIsleGlobals
    function setMinCover(address poolConfigurator_, uint104 minCover_) external override onlyGovernor {
        emit MinCoverSet(poolConfigurator_, minCover_);
        poolConfigurators[poolConfigurator_].minCover = minCover_;
    }

    /// @inheritdoc IIsleGlobals
    function setPoolLimit(address poolConfigurator_, uint104 poolLimit_) external override onlyGovernor {
        emit PoolLimitSet(poolConfigurator_, poolLimit_);
        poolConfigurators[poolConfigurator_].poolLimit = poolLimit_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IIsleGlobals
    function governor() external view override returns (address governor_) {
        governor_ = admin;
    }

    /// @inheritdoc IIsleGlobals
    function isFunctionPaused(address contract_, bytes4 sig_) public view override returns (bool functionIsPaused_) {
        functionIsPaused_ = (protocolPaused || isContractPaused[contract_]) && !isFunctionUnpaused[contract_][sig_];
    }

    /// @inheritdoc IIsleGlobals
    function isFunctionPaused(bytes4 sig_) external view override returns (bool functionIsPaused_) {
        functionIsPaused_ = isFunctionPaused(msg.sender, sig_);
    }

    /// @inheritdoc IIsleGlobals
    function isPoolAdmin(address account_) external view override returns (bool isPoolAdmin_) {
        isPoolAdmin_ = poolAdmins[account_].isPoolAdmin;
    }

    /// @inheritdoc IIsleGlobals
    function ownedPoolConfigurator(address poolAdmin_) external view override returns (address poolConfigurator_) {
        poolConfigurator_ = poolAdmins[poolAdmin_].ownedPoolConfigurator;
    }

    /// @inheritdoc IIsleGlobals
    function maxCoverLiquidation(address poolConfigurator_)
        external
        view
        override
        returns (uint24 maxCoverLiqduidation_)
    {
        maxCoverLiqduidation_ = poolConfigurators[poolConfigurator_].maxCoverLiquidation;
    }

    /// @inheritdoc IIsleGlobals
    function minCover(address poolConfigurator_) external view override returns (uint104 minCover_) {
        minCover_ = poolConfigurators[poolConfigurator_].minCover;
    }

    /// @inheritdoc IIsleGlobals
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ILopoGlobalsEvents {
    event Initialized();

    /// @dev   The address for the Lopo vault has been set.
    /// @param previousLopoVault_ The previous vault.
    /// @param currentLopoVault_  The new vault.
    event LopoVaultSet(address indexed previousLopoVault_, address indexed currentLopoVault_);

    /// @dev   The protocol pause was set to a new state.
    /// @param caller_         The address of the security admin or governor that performed the action.
    /// @param protocolPaused_ The protocol paused state.
    event ProtocolPausedSet(address indexed caller_, bool protocolPaused_);

    /// @dev Emitted when a contract is paused or unpaused.
    /// @param caller_ The address that performed the action.
    /// @param contract_ The address of the contract being paused or unpaused.
    /// @param contractPaused_ The new paused state of the contract.
    event ContractPausedSet(address indexed caller_, address indexed contract_, bool contractPaused_);

    /// @dev Emitted when a function is unpaused or paused.
    /// @param caller_ The address that performed the action.
    /// @param contract_ The address of the contract.
    /// @param sig_ The function signature.
    /// @param functionUnpaused_ The new unpaused state of the function.
    event FunctionUnpausedSet(
        address indexed caller_, address indexed contract_, bytes4 indexed sig_, bool functionUnpaused_
    );

    /// @dev Emitted when the protocol fee has been set.
    /// @param protocolFee_ The new protocol fee value.
    event ProtocolFeeSet(uint24 protocolFee_);

    /// @dev   A valid asset was set.
    /// @param collateralAsset_ The address of the collateral asset.
    /// @param isValid_         The validity of the collateral asset.
    event ValidCollateralAssetSet(address indexed collateralAsset_, bool isValid_);

    /// @dev   A valid asset was set.
    /// @param poolAsset_ The address of the asset.
    /// @param isValid_   The validity of the asset.
    event ValidPoolAssetSet(address indexed poolAsset_, bool isValid_);

    /// @dev Emitted when a valid pool admin is set.
    /// @param poolAdmin_ The address of the pool admin.
    /// @param isValid_ The validity of the pool admin.
    event ValidPoolAdminSet(address indexed poolAdmin_, bool isValid_);

    /// @dev Emitted when a pool configurator is set.
    /// @param poolAdmin_ The address of the pool admin.
    /// @param poolConfigurator_ The address of the pool configurator.

    event PoolConfiguratorSet(address indexed poolAdmin_, address indexed poolConfigurator_);

    /// @dev   The max liquidation percent for the given pool manager has been set.
    /// @param poolManager_                The address of the pool manager.
    /// @param maxCoverLiquidation_ The new value for the cover liquidation percent.
    event MaxCoverLiquidationSet(address indexed poolManager_, uint24 maxCoverLiquidation_);

    /// @dev Emitted when the min cover value is set.
    /// @param poolConfigurator_ The address of the pool configurator.
    /// @param minCover_ The new min cover value.
    event MinCoverSet(address indexed poolConfigurator_, uint104 indexed minCover_);

    /// @dev Emitted when the pool limit is set.
    /// @param poolConfigurator_ The address of the pool configurator.
    /// @param poolLimit_ The new pool limit value.
    event PoolLimitSet(address indexed poolConfigurator_, uint104 poolLimit_);
}

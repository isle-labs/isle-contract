// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IIsleGlobalsEvents {
    event Initialized();

    /// @dev The address for the Isle vault has been set.
    /// @param previousIsleVault_ The previous vault.
    /// @param currentIsleVault_  The new vault.
    event IsleVaultSet(address indexed previousIsleVault_, address indexed currentIsleVault_);

    /// @dev The protocol pause was set to a new state.
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
}

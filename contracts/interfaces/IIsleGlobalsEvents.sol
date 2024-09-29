// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

interface IIsleGlobalsEvents {
    /// @dev The IsleGlobals contract has been initialized.
    /// @param governor_ The address of the governor.
    event Initialized(address governor_);

    /// @dev The address for the Isle vault has been set.
    /// @param previousVault_ The previous vault.
    /// @param newVault_  The new vault.
    event IsleVaultSet(address indexed previousVault_, address indexed newVault_);

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
    /// @param receivableAsset_ The address of the receivable asset.
    /// @param isValid_         The validity of the receivable asset.
    event ValidReceivableAssetSet(address indexed receivableAsset_, bool isValid_);

    /// @dev   A valid asset was set.
    /// @param poolAsset_ The address of the asset.
    /// @param isValid_   The validity of the asset.
    event ValidPoolAssetSet(address indexed poolAsset_, bool isValid_);

    /// @dev Emitted when a valid pool admin is set.
    /// @param poolAdmin_ The address of the pool admin.
    /// @param isValid_ The validity of the pool admin.
    event ValidPoolAdminSet(address indexed poolAdmin_, bool isValid_);
}

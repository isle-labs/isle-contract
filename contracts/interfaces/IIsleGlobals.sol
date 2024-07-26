// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IGovernable } from "./IGovernable.sol";
import { IIsleGlobalsEvents } from "./IIsleGlobalsEvents.sol";

/// @title IIsleGlobals
/// @notice Interface for the IsleGlobals contract.
/// @notice This interface provides functions to manage the global configurations of the Isle Protocol.
interface IIsleGlobals is IIsleGlobalsEvents, IGovernable {
    /*//////////////////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initializes the contract.
    /// @param governor_ The address of the governor.
    function initialize(address governor_) external;

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the address of the Isle vault.
    /// @param isleVault_ The address of the Isle vault.
    function setIsleVault(address isleVault_) external;

    /// @notice Pause or unpause the protocol.
    /// @param protocolPaused_ A boolean indicating the status of the protocol pause.
    function setProtocolPaused(bool protocolPaused_) external;

    /// @notice Pause or unpause a specific contract.
    /// @param contract_ The address of the contract to set the pause status for.
    /// @param contractPaused_ A boolean indicating the pause status of the contract.
    function setContractPaused(address contract_, bool contractPaused_) external;

    /// @notice Unpause or ununpause (xD) a specific function in a contract.
    /// @notice Normally used to unpause specific functions when a contract is paused.
    /// @param contract_ The address of the contract.
    /// @param sig_ The function signature.
    /// @param functionUnpaused_ A boolean indicating whether the function is unpaused.
    function setFunctionUnpaused(address contract_, bytes4 sig_, bool functionUnpaused_) external;

    /// @notice Sets the protocol fee.
    /// @param protocolFee_ A uint24 indicating the protocol fee (100.0000% = 1e6 (6 decimal precision)).
    function setProtocolFee(uint24 protocolFee_) external;

    /// @notice Sets the validity of a receivable asset (should match ERC-721).
    /// @param receivableAsset_ The address of the receivable asset to set the validity for.
    /// @param isValid_         A boolean indicating the validity of the receivable asset.
    function setValidReceivableAsset(address receivableAsset_, bool isValid_) external;

    /// @notice Sets the validity of the pool asset (should match ERC-20).
    /// @param poolAsset_ The address of the pool asset to set the validity for.
    /// @param isValid_   A boolean indicating the validity of the pool asset.
    function setValidPoolAsset(address poolAsset_, bool isValid_) external;

    /// @notice Sets the validity of a pool admin.
    /// @param poolAdmin_ The address of the pool admin to set the validity for.
    /// @param isValid_   A boolean indicating the validity of the pool admin.
    function setValidPoolAdmin(address poolAdmin_, bool isValid_) external;

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL STORAGE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the protocol fee.
    /// @return protocolFee_ A uint24 indicating the protocol fee.
    function protocolFee() external view returns (uint24 protocolFee_);

    /// @notice Gets isle vault address.
    /// @return isleVault_ The address of the isle vault.
    function isleVault() external view returns (address isleVault_);

    /// @notice Gets the status of the protocol pause.
    /// @return protocolPaused_ A boolean indicating whether the protocol is paused.
    function protocolPaused() external view returns (bool protocolPaused_);

    /// @notice Returns the pause status of a specific contract.
    /// @param contract_ The address of the contract to check.
    /// @return contractPaused_ A boolean indicating whether a contract is paused.
    function isContractPaused(address contract_) external view returns (bool contractPaused_);

    /// @notice Returns the unpause status of a specific function in a contract.
    /// @param contract_ The address of the contract.
    /// @param sig_ The function signature.
    /// @return functionUnpaused_ A boolean indicating whether the function is unpaused.
    function isFunctionUnpaused(address contract_, bytes4 sig_) external view returns (bool functionUnpaused_);

    /// @notice Returns if the account is a valid poolAdmin.
    /// @param account_ The address of the account to check.
    /// @return isPoolAdmin_ Whether the account is a valid poolAdmin.
    function isPoolAdmin(address account_) external view returns (bool isPoolAdmin_);

    /// @notice Gets the validity of a receivable asset.
    /// @param  receivableAsset_   The address of the receivableAsset to query.
    /// @return isReceivableAsset_ A boolean indicating the validity of the receivable asset.
    function isReceivableAsset(address receivableAsset_) external view returns (bool isReceivableAsset_);

    /// @notice Gets the validity of a pool asset.
    /// @param  poolAsset_   The address of the poolAsset to query.
    /// @return isPoolAsset_ A boolean indicating the validity of the pool asset.
    function isPoolAsset(address poolAsset_) external view returns (bool isPoolAsset_);

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the pause status of a specific function in a contract.
    /// @param contract_ The address of the contract.
    /// @param sig_ The function signature.
    /// @return isFunctionPaused_ A boolean indicating the pause status of the function.
    function isFunctionPaused(address contract_, bytes4 sig_) external view returns (bool isFunctionPaused_);

    /// @notice Returns the pause status of a specific function in the caller contract.
    /// @param sig_ The function signature.
    /// @return isFunctionPaused_ A boolean indicating the pause status of the function.
    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { ILopoGlobalsEvents } from "./ILopoGlobalsEvents.sol";

/// @title ILopoGlobals
/// @notice Interface for the LopoGlobals contract
/// @notice This interface provides functions for managing the global settings of the Lopo protocol
interface ILopoGlobals is ILopoGlobalsEvents {

    /*//////////////////////////////////////////////////////////////////////////
                                Struct
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Struct representing a pool admin
    struct PoolAdmin {
        address ownedPoolConfigurator; // The address of the pool configurator owned by the pool admin
        bool isPoolAdmin; // Indicates whether the address is a valid pool admin
        uint256 poolLimit; // The maximum limit for the pool under the pool admin
        uint256 minCover; // The minimum cover required for the pool admin
        uint256 maxCoverLiquidation; // The maximum cover liquidation as a percentage for the pool admin
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Initializes the contract
    /// @param governor_ The address of the governor
    function initialize(address governor_) external;

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice   Sets the address of the Lopo vault.
    /// @param lopoVault_ The address of the Lopo vault.
    function setLopoVault(address lopoVault_) external;

    /// @notice   Sets the protocol pause.
    /// @param protocolPaused_ A boolean indicating the status of the protocol pause.
    function setProtocolPause(bool protocolPaused_) external;

    /// @notice Sets the pause status of a specific contract
    /// @param contract_ The address of the contract to set the pause status for
    /// @param contractPaused_ A boolean indicating the pause status of the contract
    function setContractPause(address contract_, bool contractPaused_) external;

    /// @notice Sets the unpause status of a specific function in a contract
    /// @param contract_ The address of the contract
    /// @param sig_ The function signature
    /// @param functionUnpaused_ A boolean indicating the unpause status of the function
    function setFunctionUnpause(address contract_, bytes4 sig_, bool functionUnpaused_) external;

    /// @notice   Sets the protocol fee
    /// @param protocolFee_ A uint256 indicating the protocol fee
    function setProtocolFee(uint256 protocolFee_) external;

    /// @notice   Sets the validity of a collateral asset.
    /// @param collateralAsset_ The address of the collateral asset to set the validity for.
    /// @param isValid_         A boolean indicating the validity of the collateral asset.
    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external;

    /// @notice   Sets the validity of the pool asset.
    /// @param poolAsset_ The address of the pool asset to set the validity for.
    /// @param isValid_   A boolean indicating the validity of the pool asset.
    function setValidPoolAsset(address poolAsset_, bool isValid_) external;

    /// @notice Sets the validity of a pool admin.
    /// @param poolAdmin_ The address of the pool admin to set the validity for.
    /// @param isValid_   A boolean indicating the validity of the pool admin.
    function setValidPoolAdmin(address poolAdmin_, bool isValid_) external;

    /// @notice Sets the pool configurator that is owned by the pool admin.
    /// @param poolAdmin_ The address of the pool admin.
    /// @param poolConfigurator_ The address of the pool configurator.
    function setPoolConfigurator(address poolAdmin_, address poolConfigurator_) external;

    /// @notice Sets the min cover required for the pool admin.
    /// @param poolAdmin_ The address of the pool admin.
    /// @param minCover_ The min cover required for the pool admin.
    function setMinCover(address poolAdmin_, uint256 minCover_) external;

    /// @notice Sets the max cover liquidation that is applied for the pool admin.
    /// @param poolAdmin_ The address of the pool admin.
    /// @param maxCoverLiquidation_ The max cover liquidation as a percentage for the pool admin.
    function setMaxCoverLiquidation(address poolAdmin_, uint256 maxCoverLiquidation_) external;

    /// @notice Transfers the pool configurator to another
    /// @param fromPoolAdmin_ The address of the pool admin to transfer from.
    /// @param toPoolAdmin_ The address of the pool admin to transfer to.
    function transferOwnedPoolConfigurator(address fromPoolAdmin_, address toPoolAdmin_) external;

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL STORAGE FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the protocol fee
    /// @return protocolFee_ A uint256 indicating the protocol fee
    function protocolFee() external view returns (uint256 protocolFee_);

    /// @notice    Gets lopo vault address.
    /// @return lopoVault_ The address of the lopo vault.
    function lopoVault() external view returns (address lopoVault_);

    /// @notice    Gets the status of the protocol pause.
    /// @return protocolPaused_ A boolean indicating the status of the protocol pause.
    function protocolPaused() external view returns (bool protocolPaused_);

    /// @notice Returns the pause status of a specific contract
    /// @param contract_ The address of the contract to check
    /// @return contractPaused_ A boolean indicating the pause status of the contract
    function isContractPaused(address contract_) external view returns (bool contractPaused_);

    /// @notice Returns the unpause status of a specific function in a contract
    /// @param contract_ The address of the contract
    /// @param sig_ The function signature
    /// @return functionUnpaused_ A boolean indicating the unpause status of the function
    function isFunctionUnpaused(address contract_, bytes4 sig_) external view returns (bool functionUnpaused_);

    /// @notice Returns the information about the pool admin
    /// @return poolAdminInfo_ The struct containing information of the pool admin
    function poolAdmins(address poolAdmin_) external view returns (PoolAdmin calldata poolAdminInfo_);

    /// @notice    Gets the validity of a collateral asset.
    /// @param  collateralAsset_   The address of the collateralAsset to query.
    /// @return isCollateralAsset_ A boolean indicating the validity of the collateral asset.
    function isCollateralAsset(address collateralAsset_) external view returns (bool isCollateralAsset_);

    /// @notice    Gets the validity of a pool asset.
    /// @param  poolAsset_   The address of the poolAsset to query.
    /// @return isPoolAsset_ A boolean indicating the validity of the pool asset.
    function isPoolAsset(address poolAsset_) external view returns (bool isPoolAsset_);

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the implementation contract
    /// @return implementation_ The address of the implementation contract
    function getImplementation() external view returns (address implementation_);

    /// @notice    Gets governor address.
    /// @return governor_ The address of the governor.
    function governor() external view returns (address governor_);

    /// @notice Returns the pause status of a specific function in a contract
    /// @param contract_ The address of the contract
    /// @param sig_ The function signature
    /// @return isFunctionPaused_ A boolean indicating the pause status of the function
    function isFunctionPaused(address contract_, bytes4 sig_) external view returns (bool isFunctionPaused_);

    /// @notice Returns the pause status of a specific function in a contract
    /// @param sig_ The function signature
    /// @return isFunctionPaused_ A boolean indicating the pause status of the function
    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

    /// @notice Returns if the account is a valid poolAdmin
    /// @param account_ The address of the account to check
    /// @return isPoolAdmin_ Whether the account is a valid poolAdmin
    function isPoolAdmin(address account_) external view returns (bool isPoolAdmin_);

    /// @notice Returns the pool configurator that the account owns
    /// @param poolAdmin_ The address of the pool admin
    /// @return poolConfigurator_ The address of the pool configurator
    function ownedPoolConfigurator(address poolAdmin_) external view returns (address poolConfigurator_);

    /// @notice Returns the max cover liquidation as a percentage for a pool admin
    /// @param poolAdmin_ The address of the pool admin
    /// @return maxCoverLiquidation_ The max cover liquidation as a percentage for the pool admin
    function maxCoverLiquidation(address poolAdmin_)
        external
        view
        returns (uint256 maxCoverLiquidation_);

    /// @notice Returns the min cover required for a pool admin
    /// @param poolAdmin_ The address of the pool admin
    /// @return minCover_ The min cover required for the pool admin
    function minCover(address poolAdmin_) external view returns (uint256 minCover_);
}

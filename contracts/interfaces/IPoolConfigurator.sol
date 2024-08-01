// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IPoolAddressesProvider } from "./IPoolAddressesProvider.sol";
import { IPoolConfiguratorStorage } from "./IPoolConfiguratorStorage.sol";
import { IPoolConfiguratorEvents } from "./IPoolConfiguratorEvents.sol";

interface IPoolConfigurator is IPoolConfiguratorStorage, IPoolConfiguratorEvents {
    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZER
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The initializer function for the pool configurator (must be called directly after deployment)
    /// @param provider_ The address of the pool addresses provider
    /// @param poolAdmin_ The address of the pool admin
    /// @param asset_ The ERC20 asset used in the lending pool
    /// @param name_  The name of the pool token
    /// @param symbol_ The symbol of the pool token
    function initialize(
        IPoolAddressesProvider provider_,
        address poolAdmin_,
        address asset_,
        string memory name_,
        string memory symbol_
    )
        external;

    /*//////////////////////////////////////////////////////////////////////////
                                GOVERNOR FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the max cover liquidation for the pool configurator
    /// @param maxCoverLiquidation_ The max cover liquidation as a percentage for the pool admin
    function setMaxCoverLiquidation(uint24 maxCoverLiquidation_) external;

    /// @notice Sets the min cover required for the pool configurator.
    /// @param minCover_ The min cover required for the pool admin.
    function setMinCover(uint104 minCover_) external;

    /// @notice Sets the pool limit for the pool configurator
    /// @param poolLimit_ The size limit of the pool
    function setPoolLimit(uint104 poolLimit_) external;

    /// @notice Transfers to a new admin
    /// @param newAdmin_ The address of the new admin
    function transferAdmin(address newAdmin_) external;

    /*//////////////////////////////////////////////////////////////////////////
                            POOL ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets whether the pool is open to the public (permissioned or permissionless)
    /// @param isOpenToPublic_ Whether the pool is open to the public
    function setOpenToPublic(bool isOpenToPublic_) external;

    /// @notice Sets the admin fee rate that would be applied to the pool
    /// @param adminFee_ The new admin fee
    function setAdminFee(uint24 adminFee_) external;

    /// @notice Assigns a buyer to the pool
    /// @param buyer_ The address of the buyer for this pool
    function setBuyer(address buyer_) external;

    /// @notice Sets the status of a seller
    /// @param seller_ The address of the seller
    /// @param isValid_ Whether the seller is valid
    function setValidSeller(address seller_, bool isValid_) external;

    /// @notice Sets the status of a lender (liquidity providers)
    /// @param lender_ The address of the lender
    /// @param isValid_ Whether the lender is valid
    function setValidLender(address lender_, bool isValid_) external;

    /// @notice Request funds from the pool and fund the loan manager
    /// @param principal_ The amount of principal to request
    function requestFunds(uint256 principal_) external;

    /// @notice Triggers the defaults of a specific loan in the loan manager
    /// @param loanId_ The ID of the defaulted loan
    function triggerDefault(uint16 loanId_) external;

    /// @notice Requests to redeem shares
    /// @param shares_ The amount of shares to redeem
    /// @param owner_ The owner of the shares
    function requestRedeem(uint256 shares_, address owner_) external;

    /// @notice Processes the redemption of shares for a specific owner
    /// @param shares_ The amount of shares to redeem
    /// @param owner_ The owner of the shares
    /// @param sender_ The sender of the process request
    /// @return redeemableShares_ The amount of redeemable shares
    /// @return resultingAssets_ The corresponding amount of assets with the redeemable shares
    function processRedeem(
        uint256 shares_,
        address owner_,
        address sender_
    )
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);

    /// @notice Removes shares from its withdrawal request
    /// @param shares_ The amount of shares to remove from withdrawal
    /// @param owner_ The owner of the shares
    /// @return sharesReturned_ The amount of shares returned
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /// @notice Pool admin deposits pool cover
    /// @param amount_ The amount of assets to deposit as first-loss cover
    function depositCover(uint256 amount_) external;

    /// @notice Pool admin withdraws from pool cover
    /// @param amount_ The amount of assets to withdraw from first-loss cover
    /// @param recipient_ The address of the recipient
    function withdrawCover(uint256 amount_, address recipient_) external;

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the max cover liquidation of the pool
    /// @return maxCoverLiquidation_ The max cover liquidation of the pool
    function maxCoverLiquidation() external view returns (uint24 maxCoverLiquidation_);

    /// @notice Returns the min cover required for the pool configurator.
    /// @return minCover_ The min cover required for the pool admin.
    function minCover() external view returns (uint104 minCover_);

    /// @notice Returns the pool limit of the pool configurator
    /// @return poolLimit_ The size limit of the pool
    function poolLimit() external view returns (uint104 poolLimit_);

    /// @notice Returns whether the pool is open to public
    /// @return openToPublic_ Whether the pool is open to public
    function openToPublic() external view returns (bool openToPublic_);

    /// @notice Returns the admin fee of the pool
    /// @return adminFee_ The admin fee of the pool
    function adminFee() external view returns (uint24 adminFee_);

    /// @notice Returns the max deposit amount of a receiver
    /// @param receiver_ The address of the receiver
    /// @return maxAssets_ The max amount of assets that can be deposited
    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);

    /// @notice Returns the max mint amount of a receiver
    /// @param receiver_ The address of the receiver
    /// @return maxShares_ The max amount of shares that can be minted
    function maxMint(address receiver_) external view returns (uint256 maxShares_);

    /// @notice Returns the max redeem amount of an owner
    /// @param owner_ The address of the owner
    /// @return maxShares_ The max amount of shares that can be redeemed
    function maxRedeem(address owner_) external view returns (uint256 maxShares_);

    /// @notice Previews the amount of assets that can be redeemed for the amount of shares specified
    /// @param owner_ The address of the owner
    /// @param shares_ The amount of shares to redeem
    /// @return assets_ The amount of assets that would be received
    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);

    /// @notice Returns the total amount of assets in the pool
    /// @return totalAssets_ The total amount of assets in the pool
    function totalAssets() external view returns (uint256 totalAssets_);

    /// @notice Returns whether the pool currently has sufficient cover
    /// @return hasSufficientCover_ Whether the pool currently has sufficient cover
    function hasSufficientCover() external view returns (bool hasSufficientCover_);

    /// @notice Returns the current amount of unrealized losses of the pool
    /// @return unrealizedLosses_ The current amount of unrealized losses of the pool
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
}

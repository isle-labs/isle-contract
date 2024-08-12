// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IPool is IERC4626 {
    /*//////////////////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the pool configurator.
    /// @return configurator_ The address of the pool configurator.
    function configurator() external view returns (address configurator_);

    /*//////////////////////////////////////////////////////////////////////////
                    EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Deposits assets into the pool with the permit signature.
    /// @param assets The amount of assets to deposit.
    /// @param receiver The address of the receiver.
    /// @param deadline The deadline of the permit signature.
    /// @param v The v of the permit signature.
    /// @param r The r of the permit signature.
    /// @param s The s of the permit signature.
    /// @return shares_ The corresponding amount of shares minted.
    function depositWithPermit(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint256 shares_);

    /// @notice Mints shares from the pool with the permit signature.
    /// @param shares The amount of shares to mint.
    /// @param receiver The address of the receiver.
    /// @param maxAssets The maximum amount of assets to deposit.
    /// @param deadline The deadline of the permit signature.
    /// @param v The v of the permit signature.
    /// @param r The r of the permit signature.
    /// @param s The s of the permit signature.
    /// @return assets_ The corresponding amount of assets deposited.
    function mintWithPermit(
        uint256 shares,
        address receiver,
        uint256 maxAssets,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
        returns (uint256 assets_);

    /// @notice Remove shares from the pool.
    /// @param shares_ The amount of shares to remove.
    /// @param owner_ The owner of the shares.
    /// @return sharesReturned_ The amount of shares returned.
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /// @notice Request the redemption of shares from the pool.
    /// @param shares_ The amount of shares to redeem.
    /// @param owner_ The owner of the shares.
    function requestRedeem(uint256 shares_, address owner_) external;

    /*//////////////////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns of the balance of the account.
    /// @param account_ The address of the account.
    /// @return assets_ The amount of assets.
    function balanceOfAssets(address account_) external view returns (uint256 assets_);

    /// @notice Returns the amount of assets that can be withdrawn for the amount of shares.
    /// @param shares_ The amount of shares.
    /// @return assets_ The amount of assets.
    function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);

    /// @notice Returns the amount of shares that will be burned to withdraw the amount of assets.
    /// @param assets_ The amount of assets to withdraw.
    /// @return shares_ The amount of shares.
    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    /// @notice Returns the unrealized losses of the pool.
    /// @return unrealizedLosses_ The unrealized losses.
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
}

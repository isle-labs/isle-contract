// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IWithdrawalManager {
    /*//////////////////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    function lockedShares(address account_) external view returns (uint256 lockedShares_);

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function lockedLiquidity() external view returns (uint256 lockedLiquidity_);
    function isInExitWindow(address owner_) external view returns (bool isInExitWindow_);
    function previewRedeem(
        address owner_,
        uint256 shares_
    )
        external
        view
        returns (uint256 redeemableShares_, uint256 resultingAssets_);
    function previewWithdraw(
        address owner_,
        uint256 assets_
    )
        external
        view
        returns (uint256 redeemableAssets_, uint256 resultingShares_);

    /*//////////////////////////////////////////////////////////////////////////
                            NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function processExit(
        uint256 requestedShares_,
        address owner_
    )
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);
    function addShares(uint256 shares_, address owner_) external;
}

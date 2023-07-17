// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolConfiguratorActions {

    /* Ownership Transfer Functions */
    function acceptPoolAdmin() external;
    function setPendingPoolAdmin(address pendingPoolAdmin_) external;

    /* Administrative Functions */
    function addLoanManager(address loanManagerFactory_) external returns (address loanManager_);
    function completeConfiguration() external;
    function setActive(bool active_) external;
    function setAllowedLender(address lender_, bool isValid_) external;
    function setIsLoanManager(address loanManager_, bool isLoanManager_) external;
    function setLiquidityCap(uint256 liquidityCap_) external;
    function setOpenToPublic() external;
    function setWithdrawalManager(address withdrawalManager_) external;

    /* Funding Functions */
    function requestFunds(address destination_, uint256 principal_) external;

    /* Default Functions */
    function triggerDefault(address loan_, address liquidatorFactory_) external;

    /* Exit Functions */
    function processRedeem(uint256 shares_, address owner_, address sender_)
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);
    function processWithdraw(uint256 assets_, address owner_, address sender_)
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);
    function requestRedeem(uint256 shares_, address owner_, address sender_) external;
    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    /* Cover Functions */
    function depositCover(uint256 amount_) external;
    function withdrawCover(uint256 amount_, address recipient_) external;

    /* LP Token View Functions */
    function convertToExitShares(uint256 amount_) external view returns (uint256 shares_);
    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address destination_);
    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);
    function maxMint(address receiver_) external view returns (uint256 maxShares_);
    function maxRedeem(address owner_) external view returns (uint256 maxShares_);
    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);
    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);
    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    /* View Functions */

    // function canCall(bytes32 functionId_, address caller_, bytes memory data_)
    //     external view
    //     returns (bool canCall_, string memory errorMessage_);

    function globals() external view returns (address globals_);
    function governor() external view returns (address governor_);
    function hasSufficientCover() external view returns (bool hasSufficientCover_);
    function loanManagerListLength() external view returns (uint256 loanManagerListLength_);
    function totalAssets() external view returns (uint256 totalAssets_);
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
}

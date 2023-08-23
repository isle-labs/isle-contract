// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IPoolConfiguratorActions } from "./pool/IPoolConfiguratorActions.sol";
import { IPoolConfiguratorStorage } from "./pool/IPoolConfiguratorStorage.sol";
import { IPoolConfiguratorEvents } from "./pool/IPoolConfiguratorEvents.sol";

interface IPoolConfigurator is IPoolConfiguratorActions, IPoolConfiguratorStorage, IPoolConfiguratorEvents {
    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /* LP Token */
    function convertToExitShares(uint256 amount_) external view returns (uint256 shares_);
    function getEscrowParams(
        address owner_,
        uint256 shares_
    )
        external
        view
        returns (uint256 escrowShares_, address destination_);
    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);
    function maxMint(address receiver_) external view returns (uint256 maxShares_);
    function maxRedeem(address owner_) external view returns (uint256 maxShares_);
    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);
    function previewRedeem(address owner_, uint256 shares_) external view returns (uint256 assets_);
    function previewWithdraw(address owner_, uint256 assets_) external view returns (uint256 shares_);

    /* Others */
    function hasSufficientCover() external view returns (bool hasSufficientCover_);
    function totalAssets() external view returns (uint256 totalAssets_);
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
    function getPool() external view returns (address pool_);

    /*//////////////////////////////////////////////////////////////////////////
                            NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /* Ownership Transfer Functions */
    function acceptPoolAdmin() external;
    function setPendingPoolAdmin(address pendingPoolAdmin_) external;

    /* Administrative Functions */
    function completeConfiguration() external;
    function setValidBorrower(address borrower_, bool isValid_) external;
    function setValidLender(address lender_, bool isValid_) external;
    function setLiquidityCap(uint256 liquidityCap_) external;
    function setOpenToPublic(bool isOpenToPublic_) external;

    /* Funding Functions */
    function requestFunds(uint256 principal_) external;

    /* Default Functions */
    function triggerDefault(uint16 loanId_) external;

    /* Exit Functions */
    function processRedeem(
        uint256 shares_,
        address owner_,
        address sender_
    )
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);
    function processWithdraw(
        uint256 assets_,
        address owner_,
        address sender_
    )
        external
        returns (uint256 redeemableShares_, uint256 resultingAssets_);
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);
    function requestRedeem(uint256 shares_, address owner_, address sender_) external;
    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external;

    /* Cover Functions */
    function depositCover(uint256 amount_) external;
    function withdrawCover(uint256 amount_, address recipient_) external;
}

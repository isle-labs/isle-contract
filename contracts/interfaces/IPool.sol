// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IERC4626 } from "@openzeppelin/interfaces/IERC4626.sol";

interface IPool is IERC4626 {
    /* ========== Events ========== */
    event OwnershipAccepted(address indexed previousOwner_, address indexed newOwner_);
    event PendingOwnerSet(address indexed owner_, address indexed pendingOwner_);
    event RedemptionRequested(address indexed owner_, uint256 shares_, uint256 escrowedShares_);
    event SharesRemoved(address indexed owner_, uint256 shares_);
    event WithdrawRequested(address indexed owner_, uint256 assets_, uint256 escrowedShares_);

    /* ========== State Variables ========== */
    function configurator() external view returns (address configurator_);

    /* ========== LP Functions ========== */
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

    /* ========== Withdrawal Request Functions ========== */
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);
    function requestRedeem(uint256 shares_, address owner_) external returns (uint256 escrowShares_);
    function requestWithdraw(uint256 assets_, address owner_) external returns (uint256 escrowShares_);

    /* ========== View Functions ========== */
    function balanceOfAssets(address account_) external view returns (uint256 asseets_);
    function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);
    function convertToExitShares(uint256 assets_) external view returns (uint256 shares_);

    /**
     *  @dev    Returns the amount unrealized gains.
     *  @return unrealizedGains_ Amount of unrealized gains.
     */
    function unrealizedGains() external view returns (uint256 unrealizedGains_);

    /**
     *  @dev    Returns the amount unrealized losses.
     *  @return unrealizedLosses_ Amount of unrealized losses.
     */
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

// Reference: https://github.com/maple-labs/pool-v2/blob/main/contracts/interfaces/IPool.sol

interface IPool is IERC20, IERC4626 {
    /**************************************************************************************************************************************/
    /*** LP Functions                                                                                                                   ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Does a ERC4626 `deposit` with a ERC-2612 `permit`.
     *  @param  assets_   The amount of `asset` to deposit.
     *  @param  receiver_ The receiver of the shares.
     *  @param  deadline_ The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_        ECDSA signature v component.
     *  @param  r_        ECDSA signature r component.
     *  @param  s_        ECDSA signature s component.
     *  @return shares_   The amount of shares minted.
     */
    function depositWithPermit(uint256 assets_, address receiver_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
        external returns (uint256 shares_);

    /**
     *  @dev    Does a ERC4626 `mint` with a ERC-2612 `permit`.
     *  @param  shares_    The amount of `shares` to mint.
     *  @param  receiver_  The receiver of the shares.
     *  @param  maxAssets_ The maximum amount of assets that can be taken, as per the permit.
     *  @param  deadline_  The timestamp after which the `permit` signature is no longer valid.
     *  @param  v_         ECDSA signature v component.
     *  @param  r_         ECDSA signature r component.
     *  @param  s_         ECDSA signature s component.
     *  @return assets_    The amount of shares deposited.
     */
    function mintWithPermit(uint256 shares_, address receiver_, uint256 maxAssets_, uint256 deadline_, uint8 v_, bytes32 r_, bytes32 s_)
        external returns (uint256 assets_);

    /**************************************************************************************************************************************/
    /*** Withdrawal Request Functions                                                                                                   ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Removes shares from the withdrawal mechanism, can only be called after the beginning of the withdrawal window has passed.
     *  @param  shares_         The amount of shares to redeem.
     *  @param  owner_          The owner of the shares.
     *  @return sharesReturned_ The amount of shares withdrawn.
     */
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);

    /**
     *  @dev    Requests a redemption of shares from the pool.
     *  @param  shares_       The amount of shares to redeem.
     *  @param  owner_        The owner of the shares.
     *  @return escrowShares_ The amount of shares sent to escrow.
     */
    function requestRedeem(uint256 shares_, address owner_) external returns (uint256 escrowShares_);

    /**
     *  @dev    Requests a withdrawal of assets from the pool.
     *  @param  assets_       The amount of assets to withdraw.
     *  @param  owner_        The owner of the shares.
     *  @return escrowShares_ The amount of shares sent to escrow.
     */
    function requestWithdraw(uint256 assets_, address owner_) external returns (uint256 escrowShares_);

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    /**
     *  @dev    Returns the amount of underlying assets owned by the specified account.
     *  @param  account_ Address of the account.
     *  @return assets_  Amount of assets owned.
     */
    function balanceOfAssets(address account_) external view returns (uint256 assets_);

    /**
     *  @dev    Returns the amount of exit assets for the input amount.
     *  @param  shares_ The amount of shares to convert to assets.
     *  @return assets_ Amount of assets able to be exited.
     */
    function convertToExitAssets(uint256 shares_) external view returns (uint256 assets_);

    /**
     *  @dev    Returns the amount of exit shares for the input amount.
     *  @param  assets_ The amount of assets to convert to shares.
     *  @return shares_ Amount of shares able to be exited.
     */
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

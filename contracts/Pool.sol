// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { ERC20, IERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { Errors } from "./libraries/Errors.sol";

import { IPool } from "./interfaces/IPool.sol";
import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";

/// @title Pool
/// @notice See the documentation in {IPool}.
contract Pool is IPool, ERC20Permit {
    using Math for uint256;

    address public configurator; // The address of the pool configurator that manages administrative functionality.
    ERC20Permit private immutable _asset; // The address of the underlying asset.

    uint8 private immutable _underlyingDecimals;

    constructor(
        address configurator_,
        address asset_,
        string memory name_,
        string memory symbol_
    )
        ERC20Permit(name_)
        ERC20(name_, symbol_)
    {
        if (asset_ == address(0)) revert Errors.Pool_ZeroAsset();
        if ((configurator = configurator_) == address(0)) revert Errors.Pool_ZeroConfigurator();
        if (!IERC20(asset_).approve(configurator_, type(uint256).max)) revert Errors.Pool_FailedApprove();

        _underlyingDecimals = ERC20(asset_).decimals();
        _asset = ERC20Permit(asset_);
    }

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPool
    function depositWithPermit(
        uint256 assets_,
        address receiver_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    )
        external
        returns (uint256 shares_)
    {
        // Checks: receiver is not the zero address.
        if (receiver_ == address(0)) revert Errors.Pool_RecipientZeroAddress();

        // Checks: deposit amount is less than or equal to the max deposit.
        if (assets_ > maxDeposit(receiver_)) revert Errors.Pool_DepositGreaterThanMax(assets_, maxDeposit(receiver_));

        _asset.permit(_msgSender(), address(this), assets_, deadline_, v_, r_, s_);

        shares_ = deposit(assets_, receiver_);
    }

    /// @inheritdoc IPool
    function mintWithPermit(
        uint256 shares_,
        address receiver_,
        uint256 maxAssets_,
        uint256 deadline_,
        uint8 v_,
        bytes32 r_,
        bytes32 s_
    )
        external
        returns (uint256 assets_)
    {
        // Checks: receiver is not the zero address.
        if (receiver_ == address(0)) revert Errors.Pool_RecipientZeroAddress();

        // Checks: mint amount is less than or equal to the max mint.
        if (shares_ > maxMint(receiver_)) revert Errors.Pool_MintGreaterThanMax(shares_, maxMint(receiver_));

        assets_ = previewMint(shares_);
        if (assets_ > maxAssets_) revert Errors.Pool_InsufficientPermit(assets_, maxAssets_);

        _asset.permit(_msgSender(), address(this), maxAssets_, deadline_, v_, r_, s_);
        _deposit(_msgSender(), receiver_, assets_, shares_);
    }

    /// @inheritdoc IPool
    function removeShares(uint256 shares_, address owner_) external override returns (uint256 sharesReturned_) {
        if (_msgSender() != owner_) {
            _spendAllowance(owner_, _msgSender(), shares_);
        }
        sharesReturned_ = IPoolConfigurator(configurator).removeShares(shares_, owner_);
    }

    /// @inheritdoc IPool
    function requestRedeem(uint256 shares_, address owner_) external override {
        address destination_ = configurator;

        if (_msgSender() != owner_) {
            _spendAllowance(owner_, _msgSender(), shares_);
        }

        if (shares_ != 0 && destination_ != address(0)) {
            _transfer(owner_, destination_, shares_);
        }

        IPoolConfigurator(configurator).requestRedeem({ shares_: shares_, owner_: owner_ });
    }

    /*//////////////////////////////////////////////////////////////
                       PUBLIC CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPool
    function balanceOfAssets(address account_) public view override returns (uint256 balanceOfAssets_) {
        balanceOfAssets_ = convertToAssets(balanceOf(account_));
    }

    /// @inheritdoc IPool
    function convertToExitAssets(uint256 shares_) public view override returns (uint256 assets_) {
        assets_ = _convertToExitAssets(shares_, Math.Rounding.Down);
    }

    /// @inheritdoc IPool
    function convertToExitShares(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = _convertToExitShares(assets_, Math.Rounding.Down);
    }

    /// @inheritdoc IPool
    function unrealizedLosses() public view override returns (uint256 unrealizedLosses_) {
        unrealizedLosses_ = IPoolConfigurator(configurator).unrealizedLosses();
    }

    /*//////////////////////////////////////////////////////////////
                                IERC462
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC4626
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        // Checks: receiver is not the zero address.
        if (receiver == address(0)) revert Errors.Pool_RecipientZeroAddress();

        // Checks: deposit amount is less than or equal to the max deposit.
        if (assets > maxDeposit(receiver)) revert Errors.Pool_DepositGreaterThanMax(assets, maxDeposit(receiver));

        shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    /// @inheritdoc IERC4626
    /// @notice As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share
    /// is zero.
    /// In this case, the shares will be minted without requiring any assets to be deposited.
    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
        // Checks: receiver is not the zero address.
        if (receiver == address(0)) revert Errors.Pool_RecipientZeroAddress();

        // Checks: mint amount is less than or equal to the max mint.
        if (shares > maxMint(receiver)) revert Errors.Pool_MintGreaterThanMax(shares, maxMint(receiver));

        assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);
    }

    /// @inheritdoc IERC4626
    /// @notice Withdraw functions not implemented
    function withdraw(
        uint256 assets_,
        address receiver_,
        address owner_
    )
        public
        pure
        override
        returns (uint256 shares_)
    {
        assets_;
        receiver_;
        owner_;
        shares_; // Not implemented

        revert Errors.Pool_WithdrawalNotImplemented();
    }

    /// @inheritdoc IERC4626
    function redeem(uint256 shares_, address receiver_, address owner_) public override returns (uint256 assets_) {
        if (shares_ > maxRedeem(owner_)) revert Errors.Pool_RedeemMoreThanMax(shares_, maxRedeem(owner_));

        uint256 redeemableShares_;
        (redeemableShares_, assets_) = IPoolConfigurator(configurator).processRedeem(shares_, owner_, _msgSender());

        _withdraw({
            caller: _msgSender(),
            receiver: receiver_,
            owner: owner_,
            assets: assets_,
            shares: redeemableShares_
        });
    }

    /// @inheritdoc IERC4626
    function maxDeposit(address receiver_) public view override returns (uint256 maxAssets_) {
        maxAssets_ = IPoolConfigurator(configurator).maxDeposit(receiver_);
    }

    /// @inheritdoc IERC4626
    function maxMint(address receiver_) public view override returns (uint256 maxShares_) {
        maxShares_ = IPoolConfigurator(configurator).maxMint(receiver_);
    }

    /// @inheritdoc IERC4626
    function maxWithdraw(address owner_) public pure override returns (uint256 maxAssets_) {
        owner_;
        maxAssets_; // Not implemented
        revert Errors.Pool_WithdrawalNotImplemented();
    }

    /// @inheritdoc IERC4626
    function maxRedeem(address owner_) public view override returns (uint256 maxShares_) {
        maxShares_ = IPoolConfigurator(configurator).maxRedeem(owner_);
    }

    /// @inheritdoc IERC4626
    function previewWithdraw(uint256 assets_) public pure override returns (uint256 shares_) {
        shares_;
        assets_; // not implemented
        revert Errors.Pool_WithdrawalNotImplemented();
    }

    /// @inheritdoc IERC4626
    function previewRedeem(uint256 shares_) public view override returns (uint256 assets_) {
        assets_ = IPoolConfigurator(configurator).previewRedeem(msg.sender, shares_);
    }

    /// @inheritdoc IERC4626
    function convertToShares(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = _convertToShares(assets_, Math.Rounding.Down);
    }

    /// @inheritdoc IERC4626
    function convertToAssets(uint256 shares_) public view override returns (uint256 assets_) {
        assets_ = _convertToAssets(shares_, Math.Rounding.Down);
    }

    /// @inheritdoc IERC4626
    function previewDeposit(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = _convertToShares(assets_, Math.Rounding.Down);
    }

    /// @inheritdoc IERC4626
    function previewMint(uint256 shares_) public view override returns (uint256 assets_) {
        assets_ = _convertToAssets(shares_, Math.Rounding.Up);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     */
    function decimals() public view override(IERC20Metadata, ERC20) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /// @inheritdoc IERC4626
    function asset() public view override returns (address) {
        return address(_asset);
    }

    /// @inheritdoc IERC4626
    function totalAssets() public view override returns (uint256) {
        return IPoolConfigurator(configurator).totalAssets();
    }

    /*//////////////////////////////////////////////////////////////
                    INTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal {
        // If _asset is ERC777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(_asset, caller, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If _asset is ERC777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(_asset, receiver, assets);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                      INTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _decimalsOffset() internal pure returns (uint8) {
        return 4;
    }

    function _convertToShares(
        uint256 assets_,
        Math.Rounding rounding_
    )
        internal
        view
        virtual
        returns (uint256 shares_)
    {
        shares_ = assets_.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding_);
    }

    function _convertToExitShares(
        uint256 assets_,
        Math.Rounding rounding_
    )
        internal
        view
        virtual
        returns (uint256 shares_)
    {
        shares_ =
            assets_.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() - unrealizedLosses() + 1, rounding_);
    }

    function _convertToAssets(
        uint256 shares_,
        Math.Rounding rounding_
    )
        internal
        view
        virtual
        returns (uint256 assets_)
    {
        assets_ = shares_.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding_);
    }

    function _convertToExitAssets(
        uint256 shares_,
        Math.Rounding rounding_
    )
        internal
        view
        virtual
        returns (uint256 assets_)
    {
        assets_ =
            shares_.mulDiv(totalAssets() - unrealizedLosses() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding_);
    }
}

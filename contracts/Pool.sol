// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IPool } from "./interfaces/IPool.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { ERC20 } from "./abstracts/ERC20.sol";
import { SafeERC20 } from "./vendor/utils/SafeERC20.sol";
import { Math } from "./vendor/utils/math/Math.sol";
import { IPoolConfiguratorLike } from "./interfaces/Interfaces.sol";


contract Pool is IPool, ERC20 {

    using Math for uint256;

    address public configurator; // The address of the pool configurator that manages administrative functionality.
    IERC20 private immutable _asset; // The address of the underlying asset.

    uint8 private immutable _underlyingDecimals;

    constructor(
        address configurator_,
        address asset_,
        address destination_,
        uint256 initialSupply_,
        string memory name_,
        string memory symbol_
    )
        ERC20(name_, symbol_)
    {
        require(asset_ != address(0), "P:C:ZERO_ASSET");
        require((configurator = configurator_) != address(0), "P:C:ZERO_MANAGER");

        if (initialSupply_ != 0) {
            _mint(destination_, initialSupply_);
        }

        require(IERC20(asset_).approve(configurator_, type(uint256).max), "P:C:FAILED_APPROVE");

        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(IERC20(asset_));
        _underlyingDecimals = success ? assetDecimals : 18;
        _asset = IERC20(asset_);
    }

    /* ========== LP Functions ========== */

    /** @dev See {IERC4626-deposit}. */
    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        require(assets <= maxDeposit(receiver), "ERC4626: deposit more than max");

        uint256 shares = previewDeposit(assets);
        _deposit(_msgSender(), receiver, assets, shares);

        return shares;
    }

    function depositWithPermit(
        uint256 assets,
        address receiver,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    )
        external returns (uint256)
    {
        _asset.permit(_msgSender(), address(this), assets, deadline, v, r, s);
        return deposit(assets, receiver);
    }

    /** @dev See {IERC4626-mint}.
     *
     * As opposed to {deposit}, minting is allowed even if the vault is in a state where the price of a share is zero.
     * In this case, the shares will be minted without requiring any assets to be deposited.
     */
    function mint(uint256 shares, address receiver) public override returns (uint256) {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    function mintWithPermit(
        uint256 shares,
        address receiver,
        uint256 maxAssets,
        uint256 deadline,
        uint8   v,
        bytes32 r,
        bytes32 s
    )
        external returns (uint256)
    {
        require(shares <= maxMint(receiver), "ERC4626: mint more than max");

        uint256 assets = previewMint(shares);
        require((assets = previewMint(shares)) <= maxAssets, "ERC4626: Insufficient permit");

        _asset.permit(_msgSender(), address(this), maxAssets, deadline, v, r, s);
        _deposit(_msgSender(), receiver, assets, shares);

        return assets;
    }

    /** @dev See {IERC4626-withdraw}. */
    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        require(assets <= maxWithdraw(owner), "ERC4626: withdraw more than max");

        uint256 shares = previewWithdraw(assets);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return shares;
    }

    /** @dev See {IERC4626-redeem}. */
    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        require(shares <= maxRedeem(owner), "ERC4626: redeem more than max");

        uint256 assets = previewRedeem(shares);
        _withdraw(_msgSender(), receiver, owner, assets, shares);

        return assets;
    }

    /* ========== Withdrawal Request Functions ========== */
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_) {
        if (_msgSender() != owner_)
            _spendAllowance(owner_, _msgSender(), shares_);

        emit SharesRemoved(owner_, sharesReturned_ = IPoolConfiguratorLike(configurator).removeShares(shares_, owner_));
    }

    function requestRedeem(uint256 shares_, address owner_) external returns (uint256 escrowShares_) {
        address destination_;

        ( escrowShares_, destination_ ) = IPoolConfiguratorLike(configurator).getEscrowParams(owner_, shares_);

        if (_msgSender() != owner_)
            _spendAllowance(owner_, _msgSender(), escrowShares_);

        if (escrowShares_ != 0 && destination_ != address(0))
            _transfer(owner_, destination_, escrowShares_);

        IPoolConfiguratorLike(configurator).requestRedeem(escrowShares_, owner_, _msgSender());
    }

    function requestWithdraw(uint256 assets_, address owner_) external returns (uint256 escrowShares_) {
        address destination_;

        ( escrowShares_, destination_ ) = IPoolConfiguratorLike(configurator).getEscrowParams(owner_, convertToExitShares(assets_));

        if (_msgSender() != owner_)
            _spendAllowance(owner_, _msgSender(), escrowShares_);

        if (escrowShares_ != 0 && destination_ != address(0))
            _transfer(owner_, destination_, escrowShares_);

        IPoolConfiguratorLike(configurator).requestWithdraw(escrowShares_, assets_, owner_, _msgSender());
    }

    /* ========== Internal Functions ========== */
    /**
     * @dev Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
     */
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool, uint8) {
        (bool success, bytes memory encodedDecimals) = address(asset_).staticcall(
            abi.encodeWithSelector(IERC20.decimals.selector)
        );
        if (success && encodedDecimals.length >= 32) {
            uint256 returnedDecimals = abi.decode(encodedDecimals, (uint256));
            if (returnedDecimals <= type(uint8).max) {
                return (true, uint8(returnedDecimals));
            }
        }
        return (false, 0);
    }

    function _convertToShares(uint256 assets_, Math.Rounding rounding_) internal view virtual returns (uint256 shares_) {
        shares_ = assets_.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() + 1, rounding_);
    }

    function _convertToExitShares(uint256 assets_, Math.Rounding rounding_) internal view virtual returns (uint256 shares_) {
        shares_ = assets_.mulDiv(totalSupply() + 10 ** _decimalsOffset(), totalAssets() - unrealizedLosses() - unrealizedGains() + 1, rounding_);
    }

    function _convertToAssets(uint256 shares_, Math.Rounding rounding_) internal view virtual returns (uint256 assets_) {
        assets_ = shares_.mulDiv(totalAssets() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding_);
    }

    function _convertToExitAssets(uint256 shares_, Math.Rounding rounding_) internal view virtual returns (uint256 assets_) {
        assets_ = shares_.mulDiv(totalAssets() - unrealizedLosses() - unrealizedGains() + 1, totalSupply() + 10 ** _decimalsOffset(), rounding_);
    }

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
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal {
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

    function _decimalsOffset() internal pure returns (uint8) {
        return 0;
    }

     /* ========== Public View Functions ========== */
    function balanceOfAssets(address account_) public view override returns (uint256 balanceOfAssets_) {
        balanceOfAssets_ = convertToAssets(balanceOf(account_));
    }

    function maxDeposit(address receiver_) public view override returns (uint256 maxAssets_) {
        maxAssets_ = IPoolConfiguratorLike(configurator).maxDeposit(receiver_);
    }

    function maxMint(address receiver_) public view override returns (uint256 maxShares_) {
        maxShares_ = IPoolConfiguratorLike(configurator).maxMint(receiver_);
    }

    function maxWithdraw(address owner_) public view override returns (uint256 maxAssets_) {
        maxAssets_ = IPoolConfiguratorLike(configurator).maxWithdraw(owner_);
    }

    function maxRedeem(address owner_) public view override returns (uint256 maxShares_) {
        maxShares_ = IPoolConfiguratorLike(configurator).maxRedeem(owner_);
    }

    function previewWithdraw(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = IPoolConfiguratorLike(configurator).previewWithdraw(assets_);
    }

    function previewRedeem(uint256 shares_) public view override returns (uint256 assets_) {
        assets_ = IPoolConfiguratorLike(configurator).previewRedeem(shares_);
    }

    function convertToShares(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = _convertToShares(assets_, Math.Rounding.Down);
    }

    function convertToExitShares(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = _convertToExitShares(assets_, Math.Rounding.Down);
    }

    function convertToAssets(uint256 shares_) public view override returns (uint256 assets_) {
        assets_ = _convertToAssets(shares_, Math.Rounding.Down);
    }

    function convertToExitAssets(uint256 shares_) public view override returns (uint256 assets_) {
        assets_ = _convertToExitAssets(shares_, Math.Rounding.Down);
    }

    function unrealizedGains() public view override returns (uint256 unrealizedGains_) {
        unrealizedGains_ = IPoolConfiguratorLike(configurator).unrealizedGains();
    }

    function unrealizedLosses() public view override returns (uint256 unrealizedLosses_) {
        unrealizedLosses_ = IPoolConfiguratorLike(configurator).unrealizedLosses();
    }

    /** @dev See {IERC4626-previewDeposit}. */
    function previewDeposit(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = _convertToShares(assets_, Math.Rounding.Down);
    }

    /** @dev See {IERC4626-previewMint}. */
    function previewMint(uint256 shares_) public view override returns (uint256 assets_) {
        assets_ = _convertToAssets(shares_, Math.Rounding.Up);
    }

    /**
     * @dev Decimals are computed by adding the decimal offset on top of the underlying asset's decimals. This
     * "original" value is cached during construction of the vault contract. If this read operation fails (e.g., the
     * asset has not been created yet), a default of 18 is used to represent the underlying asset's decimals.
     *
     */
    function decimals() public view override(ERC20, IERC20) returns (uint8) {
        return _underlyingDecimals + _decimalsOffset();
    }

    /** @dev See {IERC4626-asset}. */
    function asset() public view override returns (address) {
        return address(_asset);
    }

    /** @dev See {IERC4626-totalAssets}. */
    function totalAssets() public view override returns (uint256) {
        return _asset.balanceOf(address(this));
    }
}
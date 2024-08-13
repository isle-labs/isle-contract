// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Errors } from "./libraries/Errors.sol";
import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { PoolDeployer } from "./libraries/PoolDeployer.sol";

import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { IIsleGlobals } from "./interfaces/IIsleGlobals.sol";
import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";
import { ILoanManager } from "./interfaces/ILoanManager.sol";
import { IPool } from "./interfaces/IPool.sol";

import { PoolConfiguratorStorage } from "./PoolConfiguratorStorage.sol";

/// @title Pool Configurator
/// @notice See the documentation in {IPoolConfigurator}.
contract PoolConfigurator is VersionedInitializable, IPoolConfigurator, PoolConfiguratorStorage {
    using SafeERC20 for IERC20;

    uint256 public constant HUNDRED_PERCENT = 1_000_000; // e.g. 100% = 100 * HUNDRED_PERCENT, integer with 6 decimal
        // precision
    uint256 public constant POOL_CONFIGURATOR_REVISION = 0x1;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    modifier onlyAdminOrGovernor() {
        _revertIfNotAdminOrGovernor();
        _;
    }

    modifier onlyGovernor() {
        _revertIfNotGovernor();
        _;
    }

    modifier onlyAdmin() {
        _revertIfNotAdmin();
        _;
    }

    modifier onlyPool() {
        _revertIfNotPool();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              INITIALIZERS
    //////////////////////////////////////////////////////////////*/

    constructor(IPoolAddressesProvider provider_) {
        if (address(provider_) == address(0)) {
            revert Errors.AddressesProviderZeroAddress();
        }
        ADDRESSES_PROVIDER = provider_;
    }

    /// @inheritdoc VersionedInitializable
    function getRevision() public pure virtual override returns (uint256 revision_) {
        revision_ = POOL_CONFIGURATOR_REVISION;
    }

    /// @inheritdoc IPoolConfigurator
    function initialize(
        IPoolAddressesProvider provider_,
        address poolAdmin_,
        address asset_,
        string calldata name_,
        string calldata symbol_
    )
        external
        override
        initializer
    {
        /* Checks */
        if (ADDRESSES_PROVIDER != provider_) {
            revert Errors.InvalidAddressesProvider({
                expectedProvider: address(ADDRESSES_PROVIDER),
                provider: address(provider_)
            });
        }

        IIsleGlobals globals_ = _globals();
        if (poolAdmin_ == address(0) || !globals_.isPoolAdmin(poolAdmin_)) {
            revert Errors.PoolConfigurator_InvalidPoolAdmin(poolAdmin_);
        }

        if (asset_ == address(0) || !globals_.isPoolAsset(asset_)) {
            revert Errors.PoolConfigurator_InvalidPoolAsset(asset_);
        }

        /* Effects */
        address pool_ =
            PoolDeployer.createPool({ configurator_: address(this), asset_: asset_, name_: name_, symbol_: symbol_ });

        admin = poolAdmin_; // Sets admin for Governable
        asset = asset_;
        pool = pool_;

        emit Initialized({ poolAdmin_: poolAdmin_, asset_: asset_, pool_: pool_ });
    }

    /*//////////////////////////////////////////////////////////////
                    EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolConfigurator
    function transferAdmin(address newAdmin_) external virtual override onlyGovernor {
        if (newAdmin_ == address(0) || !_globals().isPoolAdmin(newAdmin_)) {
            revert Errors.PoolConfigurator_InvalidPoolAdmin(newAdmin_);
        }
        address oldAdmin_ = admin;
        admin = newAdmin_;
        emit TransferAdmin({ oldAdmin_: oldAdmin_, newAdmin_: newAdmin_ });
    }

    /// @inheritdoc IPoolConfigurator
    function setBuyer(address buyer_) external override whenNotPaused onlyAdmin {
        emit BuyerSet(buyer = buyer_);
    }

    /// @inheritdoc IPoolConfigurator
    function setValidSeller(address seller_, bool isValid_) external override whenNotPaused onlyAdmin {
        emit ValidSellerSet(seller_, isSeller[seller_] = isValid_);
    }

    /// @inheritdoc IPoolConfigurator
    function setValidLender(address lender_, bool isValid_) external override whenNotPaused onlyAdmin {
        emit ValidLenderSet(lender_, isLender[lender_] = isValid_);
    }

    /// @inheritdoc IPoolConfigurator
    function setAdminFee(uint24 adminFee_) external override whenNotPaused onlyAdmin {
        emit AdminFeeSet(_config.adminFee = adminFee_);
    }

    /// @inheritdoc IPoolConfigurator
    function setOpenToPublic(bool isOpenToPublic_) external override whenNotPaused onlyAdmin {
        emit OpenToPublicSet(_config.openToPublic = isOpenToPublic_);
    }

    /// @inheritdoc IPoolConfigurator
    function setMaxCoverLiquidation(uint24 maxCoverLiquidation_) external override whenNotPaused onlyGovernor {
        emit MaxCoverLiquidationSet(_config.maxCoverLiquidation = maxCoverLiquidation_);
    }

    /// @inheritdoc IPoolConfigurator
    function setMinCover(uint104 minCover_) external override whenNotPaused onlyGovernor {
        emit MinCoverSet(_config.minCover = minCover_);
    }

    /// @inheritdoc IPoolConfigurator
    function setPoolLimit(uint104 poolLimit_) external override whenNotPaused onlyGovernor {
        emit PoolLimitSet(_config.poolLimit = poolLimit_);
    }

    /// @inheritdoc IPoolConfigurator
    function requestFunds(uint256 principal_) external override whenNotPaused {
        address asset_ = asset;
        address pool_ = pool;
        address loanManager_ = address(_loanManager());

        // Checks
        if (msg.sender != loanManager_) {
            revert Errors.PoolConfigurator_CallerNotLoanManager({ expectedCaller_: loanManager_, caller_: msg.sender });
        }
        if (IERC20(pool_).totalSupply() == 0) {
            revert Errors.PoolConfigurator_PoolSupplyZero();
        }
        if (!_hasSufficientCover()) {
            revert Errors.PoolConfigurator_InsufficientCover();
        }

        IERC20(asset_).safeTransferFrom(pool_, msg.sender, principal_);

        uint256 lockedLiquidity_ = _withdrawalManager().lockedLiquidity();

        if (IERC20(asset_).balanceOf(pool_) < lockedLiquidity_) {
            revert Errors.PoolConfigurator_InsufficientLiquidity();
        }
    }

    /// @inheritdoc IPoolConfigurator
    function triggerDefault(uint16 loanId_) external override whenNotPaused onlyAdminOrGovernor {
        (uint256 losses_,) = _loanManager().triggerDefault(loanId_);
        _handleCover(losses_);
    }

    /// @inheritdoc IPoolConfigurator
    function requestRedeem(uint256 shares_, address owner_) external override whenNotPaused onlyPool {
        address pool_ = pool;
        IWithdrawalManager withdrawalManager_ = _withdrawalManager();

        IPool(pool_).approve(address(withdrawalManager_), shares_);

        withdrawalManager_.addShares(shares_, owner_);

        emit RedeemRequested(owner_, shares_);
    }

    /// @inheritdoc IPoolConfigurator
    function processRedeem(
        uint256 shares_,
        address owner_,
        address sender_
    )
        external
        override
        whenNotPaused
        onlyPool
        returns (uint256 redeemableShares_, uint256 resultingAssets_)
    {
        if (owner_ != sender_ && IPool(pool).allowance(owner_, sender_) == 0) {
            revert Errors.PoolConfigurator_NoAllowance({ owner_: owner_, spender_: sender_ });
        }
        (redeemableShares_, resultingAssets_) = _withdrawalManager().processExit(shares_, owner_);
        emit RedeemProcessed(owner_, redeemableShares_, resultingAssets_);
    }

    /// @inheritdoc IPoolConfigurator
    function removeShares(
        uint256 shares_,
        address owner_
    )
        external
        override
        whenNotPaused
        onlyPool
        returns (uint256 sharesReturned_)
    {
        emit SharesRemoved(owner_, sharesReturned_ = _withdrawalManager().removeShares(shares_, owner_));
    }

    /// @inheritdoc IPoolConfigurator
    function depositCover(uint256 amount_) external override whenNotPaused {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount_);
        poolCover += amount_;
        emit CoverDeposited(amount_);
    }

    /// @inheritdoc IPoolConfigurator
    function withdrawCover(uint256 amount_, address recipient_) external override whenNotPaused onlyAdmin {
        recipient_ = recipient_ == address(0) ? msg.sender : recipient_;

        IERC20(asset).safeTransfer(recipient_, amount_);

        poolCover -= amount_;

        if (!_hasSufficientCover()) {
            revert Errors.PoolConfigurator_InsufficientCover();
        }

        emit CoverWithdrawn(amount_);
    }

    /*//////////////////////////////////////////////////////////////
                      EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolConfigurator
    function openToPublic() external view override returns (bool openToPublic_) {
        openToPublic_ = _config.openToPublic;
    }

    /// @inheritdoc IPoolConfigurator
    function adminFee() external view override returns (uint24 adminFee_) {
        adminFee_ = _config.adminFee;
    }

    /// @inheritdoc IPoolConfigurator
    function maxCoverLiquidation() external view returns (uint24 maxCoverLiquidation_) {
        maxCoverLiquidation_ = _config.maxCoverLiquidation;
    }

    /// @inheritdoc IPoolConfigurator
    function minCover() external view returns (uint104 minCover_) {
        minCover_ = _config.minCover;
    }

    /// @inheritdoc IPoolConfigurator
    function poolLimit() external view returns (uint104 poolLimit_) {
        poolLimit_ = _config.poolLimit;
    }

    /// @inheritdoc IPoolConfigurator
    function maxDeposit(address receiver_) external view virtual override returns (uint256 maxAssets_) {
        maxAssets_ = _getMaxAssets(receiver_, _totalAssets());
    }

    /// @inheritdoc IPoolConfigurator
    function maxMint(address receiver_) external view virtual override returns (uint256 maxShares_) {
        uint256 totalAssets_ = _totalAssets();
        uint256 maxAssets_ = _getMaxAssets(receiver_, totalAssets_);

        maxShares_ = IPool(pool).previewDeposit(maxAssets_);
    }

    /// @inheritdoc IPoolConfigurator
    function maxRedeem(address owner_) external view virtual override returns (uint256 maxShares_) {
        IWithdrawalManager withdrawalManager_ = _withdrawalManager();

        uint256 lockedShares_ = withdrawalManager_.lockedShares(owner_);
        maxShares_ = withdrawalManager_.isInExitWindow(owner_) ? lockedShares_ : 0;
    }

    /// @inheritdoc IPoolConfigurator
    function previewRedeem(address owner_, uint256 shares_) external view virtual override returns (uint256 assets_) {
        (, assets_) = _withdrawalManager().previewRedeem(owner_, shares_);
    }

    /// @inheritdoc IPoolConfigurator
    function totalAssets() external view override returns (uint256 totalAssets_) {
        totalAssets_ = _totalAssets();
    }

    /// @inheritdoc IPoolConfigurator
    function hasSufficientCover() external view override returns (bool hasSufficientCover_) {
        hasSufficientCover_ = _hasSufficientCover();
    }

    /// @inheritdoc IPoolConfigurator
    function unrealizedLosses() external view override returns (uint256 unrealizedLosses_) {
        // `totalAssets` does not.
        // NOTE: Use minimum to prevent underflows in the case that `unrealizedLosses` includes late interest and
        unrealizedLosses_ = _min(_loanManager().unrealizedLosses(), _totalAssets());
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _totalAssets() internal view returns (uint256 totalAssets_) {
        totalAssets_ = IERC20(asset).balanceOf(address(pool)) + _loanManager().assetsUnderManagement();
    }

    function _revertIfPaused() internal view {
        if (_globals().isFunctionPaused(msg.sig)) {
            revert Errors.PoolConfigurator_Paused();
        }
    }

    function _revertIfNotAdmin() internal view {
        if (msg.sender != admin) {
            revert Errors.PoolConfigurator_CallerNotPoolAdmin(msg.sender);
        }
    }

    function _revertIfNotAdminOrGovernor() internal view {
        if (msg.sender != admin && msg.sender != _globals().governor()) {
            revert Errors.PoolConfigurator_CallerNotPoolAdminOrGovernor(msg.sender);
        }
    }

    function _revertIfNotGovernor() internal view {
        if (msg.sender != _globals().governor()) {
            revert Errors.PoolConfigurator_CallerNotGovernor(msg.sender);
        }
    }

    function _revertIfNotPool() internal view {
        if (msg.sender != pool) {
            revert Errors.InvalidCaller({ caller: msg.sender, expectedCaller: pool });
        }
    }

    function _hasSufficientCover() internal view returns (bool hasSufficientCover_) {
        uint256 minCover_ = _config.minCover;
        hasSufficientCover_ = minCover_ != 0 && poolCover >= minCover_;
    }

    function _handleCover(uint256 losses_) internal {
        uint256 availableCover_ = (poolCover * _config.maxCoverLiquidation) / HUNDRED_PERCENT;

        uint256 coverAmount_ = _min(availableCover_, losses_);

        poolCover -= coverAmount_;
        // transfer cover to pool
        IERC20(asset).transfer(pool, coverAmount_);

        emit CoverLiquidated(coverAmount_);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 min_) {
        min_ = a_ < b_ ? a_ : b_;
    }

    function _getMaxAssets(address receiver_, uint256 totalAssets_) internal view returns (uint256 maxAssets_) {
        bool depositAllowed_ = _config.openToPublic || isLender[receiver_];
        uint256 poolLimit_ = _config.poolLimit;
        maxAssets_ = poolLimit_ > totalAssets_ && depositAllowed_ ? poolLimit_ - totalAssets_ : 0;
    }

    function _globals() internal view returns (IIsleGlobals globals_) {
        globals_ = IIsleGlobals(ADDRESSES_PROVIDER.getIsleGlobals());
    }

    function _loanManager() internal view returns (ILoanManager loanManager_) {
        loanManager_ = ILoanManager(ADDRESSES_PROVIDER.getLoanManager());
    }

    function _withdrawalManager() internal view returns (IWithdrawalManager withdrawalManager_) {
        withdrawalManager_ = IWithdrawalManager(ADDRESSES_PROVIDER.getWithdrawalManager());
    }
}

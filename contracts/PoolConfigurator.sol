// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { Errors } from "./libraries/Errors.sol";
import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { PoolDeployer } from "./libraries/PoolDeployer.sol";

import { Adminable } from "./abstracts/Adminable.sol";
import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";
import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";
import { ILoanManager } from "./interfaces/ILoanManager.sol";
import { IPool } from "./interfaces/IPool.sol";

import { PoolConfiguratorStorage } from "./PoolConfiguratorStorage.sol";

/// @title Pool Configurator
/// @notice See the documentation in {IPoolConfigurator}.
contract PoolConfigurator is Adminable, VersionedInitializable, IPoolConfigurator, PoolConfiguratorStorage {
    uint256 public constant HUNDRED_PERCENT = 1_000_000; // Four decimal precision.
    uint256 public constant POOL_CONFIGURATOR_REVISION = 0x1;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    modifier onlyAdminOrGovernor() {
        _revertIfNotAdminOrGovernor();
        _;
    }

    modifier onlyPool() {
        _revertIfNotPool();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZERS
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IPoolAddressesProvider provider_) {
        ADDRESSES_PROVIDER = provider_;
    }

    /// @inheritdoc VersionedInitializable
    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = POOL_CONFIGURATOR_REVISION;
    }

    /// @inheritdoc IPoolConfigurator
    function initialize(
        IPoolAddressesProvider provider_,
        address poolAdmin_,
        address asset_,
        string memory name_,
        string memory symbol_
    )
        external
        override
        initializer
    {
        /* Checks */
        if (ADDRESSES_PROVIDER != provider_) {
            revert Errors.InvalidAddressProvider({
                expectedProvider: address(ADDRESSES_PROVIDER),
                provider: address(provider_)
            });
        }

        ILopoGlobals globals_ = _globals();
        if (poolAdmin_ == address(0) || !globals_.isPoolAdmin(poolAdmin_)) {
            revert Errors.PoolConfigurator_InvalidPoolAdmin(poolAdmin_);
        }
        if (asset_ == address(0) || !globals_.isPoolAsset(asset_)) {
            revert Errors.PoolConfigurator_InvalidPoolAsset(asset_);
        }

        /* Effects */
        address pool_ = PoolDeployer.createPool(address(this), asset_, name_, symbol_);
        admin = poolAdmin_; // Sets admin for Adminable
        asset = asset_;
        pool = pool_;

        emit Initialized(poolAdmin_, asset_, pool_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                        EXTERNAL NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolConfigurator
    function setValidBuyer(address buyer_, bool isValid_) external override whenNotPaused onlyAdmin {
        emit ValidBuyerSet(buyer_, isBuyer[buyer_] = isValid_);
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
    function setPoolLimit(uint256 poolLimit_) external override whenNotPaused onlyAdmin {
        emit PoolLimitSet(poolLimit = poolLimit_);
    }

    /// @inheritdoc IPoolConfigurator
    function setAdminFee(uint256 adminFee_) external override whenNotPaused onlyAdmin {
        emit AdminFeeSet(adminFee = adminFee_);
    }

    /// @inheritdoc IPoolConfigurator
    function setOpenToPublic(bool isOpenToPublic_) external override whenNotPaused onlyAdmin {
        openToPublic = isOpenToPublic_;
        emit OpenToPublicSet(isOpenToPublic_);
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
        if (!_hasSufficientCover(_globals())) {
            revert Errors.PoolConfigurator_InsufficientCover();
        }
        if (!IERC20(asset_).transferFrom(pool_, msg.sender, principal_)) {
            revert Errors.ERC20TransferFailed(asset_, pool_, msg.sender, principal_);
        }

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
    function requestRedeem(uint256 shares_, address owner_, address sender_) external override whenNotPaused onlyPool {
        address pool_ = pool;
        IWithdrawalManager withdrawalManager_ = _withdrawalManager();

        if (!IPool(pool_).approve(address(withdrawalManager_), shares_)) {
            revert Errors.PoolConfigurator_PoolApproveWithdrawalManagerFailed({ amount_: shares_ });
        }

        if (sender_ != owner_ && shares_ == 0) {
            revert Errors.PoolConfigurator_NoAllowance({ owner_: owner_, spender_: sender_ });
        }

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
        if (!IERC20(asset).transferFrom(msg.sender, address(this), amount_)) {
            revert Errors.PoolConfigurator_DepositCoverFailed({ caller_: msg.sender, amount_: amount_ });
        }
        poolCover += amount_;
        emit CoverDeposited(amount_);
    }

    /// @inheritdoc IPoolConfigurator
    function withdrawCover(uint256 amount_, address recipient_) external override whenNotPaused onlyAdmin {
        recipient_ = recipient_ == address(0) ? msg.sender : recipient_;

        if (!IERC20(asset).transfer(recipient_, amount_)) {
            revert Errors.PoolConfigurator_WithdrawCoverFailed({ recipient_: recipient_, amount_: amount_ });
        }

        poolCover -= amount_;

        if (!_hasSufficientCover(_globals())) {
            revert Errors.PoolConfigurator_InsufficientCover();
        }

        emit CoverWithdrawn(amount_);
    }

    /*//////////////////////////////////////////////////////////////////////////
                            EXTERNAL CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolConfigurator
    function convertToExitShares(uint256 assets_) external view override returns (uint256 shares_) {
        shares_ = IPool(pool).convertToExitShares(assets_);
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
        hasSufficientCover_ = _hasSufficientCover(_globals());
    }

    /// @inheritdoc IPoolConfigurator
    function unrealizedLosses() public view override returns (uint256 unrealizedLosses_) {
        // NOTE: Use minimum to prevent underflows in the case that `unrealizedLosses` includes late interest and
        // `totalAssets` does not.
        unrealizedLosses_ = _min(_loanManager().unrealizedLosses(), _totalAssets());
    }

    /*//////////////////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _totalAssets() internal view returns (uint256 totalAssets_) {
        totalAssets_ = IERC20(asset).balanceOf(address(pool)) + _loanManager().assetsUnderManagement();
    }

    function _revertIfPaused() internal view {
        if (_globals().isFunctionPaused(msg.sig)) {
            revert Errors.PoolConfigurator_Paused();
        }
    }

    function _revertIfNotAdminOrGovernor() internal view {
        if (msg.sender != admin && msg.sender != _globals().governor()) {
            revert Errors.PoolConfigurator_CallerNotPoolAdminOrGovernor(msg.sender);
        }
    }

    function _revertIfNotPool() internal view {
        if (msg.sender != pool) {
            revert Errors.InvalidCaller({ caller: msg.sender, expectedCaller: pool });
        }
    }

    function _hasSufficientCover(ILopoGlobals globals_) internal view returns (bool hasSufficientCover_) {
        uint256 minCover_ = globals_.minCover(address(this));
        hasSufficientCover_ = minCover_ != 0 && poolCover >= minCover_;
    }

    function _handleCover(uint256 losses_) internal {
        ILopoGlobals globals_ = ILopoGlobals(ADDRESSES_PROVIDER.getLopoGlobals());

        uint256 availableCover_ = (poolCover * globals_.maxCoverLiquidation(address(this))) / HUNDRED_PERCENT;

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
        bool depositAllowed_ = openToPublic || isLender[receiver_];
        uint256 poolLimit_ = poolLimit;
        maxAssets_ = poolLimit_ > totalAssets_ && depositAllowed_ ? poolLimit_ - totalAssets_ : 0;
    }

    function _globals() internal view returns (ILopoGlobals globals_) {
        globals_ = ILopoGlobals(ADDRESSES_PROVIDER.getLopoGlobals());
    }

    function _loanManager() internal view returns (ILoanManager loanManager_) {
        loanManager_ = ILoanManager(ADDRESSES_PROVIDER.getLoanManager());
    }

    function _withdrawalManager() internal view returns (IWithdrawalManager withdrawalManager_) {
        withdrawalManager_ = IWithdrawalManager(ADDRESSES_PROVIDER.getWithdrawalManager());
    }
}

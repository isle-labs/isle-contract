// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { ILopoGlobals } from "./interfaces/ILopoGlobals.sol";
import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";
import { ILoanManager } from "./interfaces/ILoanManager.sol";
import { IPool } from "./interfaces/IPool.sol";

import { Pool } from "./Pool.sol";
import { PoolConfiguratorStorage } from "./PoolConfiguratorStorage.sol";
import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { LoanManager } from "./LoanManager.sol";
import { WithdrawalManager } from "./WithdrawalManager.sol";
import { Errors } from "./libraries/Errors.sol";

contract PoolConfigurator is IPoolConfigurator, PoolConfiguratorStorage, VersionedInitializable {
    uint256 public constant HUNDRED_PERCENT = 100_0000; // Four decimal precision.
    uint256 public constant POOL_CONFIGURATOR_REVISION = 0x1;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /*//////////////////////////////////////////////////////////////////////////
                                MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier onlyIfNotConfigured() {
        _revertIfConfigured();
        _;
    }

    modifier whenNotPaused() {
        _revertIfPaused();
        _;
    }

    modifier onlyPoolAdmin() {
        _revertIfNotPoolAdmin();
        _;
    }

    modifier onlyPoolAdminOrGovernor() {
        _revertIfNotPoolAdminOrGovernor();
        _;
    }

    modifier onlyPoolAdminOrNotConfigured() {
        _revertIfNotPoolAdminAndConfigured();
        _;
    }

    modifier onlyPool() {
        _revertIfNotPool();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                INITIALIZERS
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    function initialize(
        IPoolAddressesProvider provider_,
        address asset_,
        address poolAdmin_,
        string memory name_,
        string memory symbol_
    ) external initializer {
        /* Checks */
        if (ADDRESSES_PROVIDER != provider_) {
            revert Errors.InvalidAddressProvider({
                expectedProvider: address(ADDRESSES_PROVIDER),
                provider: address(provider_)
            });
        }

        ILopoGlobals globals_ = ILopoGlobals(ADDRESSES_PROVIDER.getLopoGlobals());

        if (poolAdmin_ == address(0) || !globals_.isPoolAdmin(poolAdmin_)) {
            revert Errors.PoolConfigurator_InvalidPoolAdmin(poolAdmin_);
        }
        if (asset_ == address(0) || !globals_.isPoolAsset(asset_)) {
            revert Errors.PoolConfigurator_InvalidPoolAsset(asset_);
        }
        if (globals_.ownedPoolConfigurator(poolAdmin_) != address(0)) {
            revert Errors.PoolConfigurator_IsAlreadyPoolAdmin(poolAdmin_);
        }

        /* Effects */
        asset = asset_;
        poolAdmin = poolAdmin_;
        pool = address(new Pool(address(this), asset_, name_, symbol_));
        emit Initialized(poolAdmin_, asset_, pool);
    }

    function completeConfiguration() external override whenNotPaused onlyIfNotConfigured {
        configured = true;
        emit ConfigurationCompleted();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = POOL_CONFIGURATOR_REVISION;
    }

    /* Participants */
    function withdrawalManager() public view override returns (address withdrawalManager_) {
        withdrawalManager_ = ADDRESSES_PROVIDER.getWithdrawalManager();
    }

    function globals() public view override returns (address globals_) {
        globals_ = ADDRESSES_PROVIDER.getLopoGlobals();
    }

    function loanManager() public view override returns (address loanManager_) {
        loanManager_ = ADDRESSES_PROVIDER.getLoanManager();
    }

    function governor() public view override returns (address governor_) {
        governor_ = ILopoGlobals(globals()).governor();
    }

    /*//////////////////////////////////////////////////////////////////////////
                            NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /* Ownership Transfer functions */
    function acceptPoolAdmin() external override whenNotPaused {
        if (msg.sender != pendingPoolAdmin) {
            revert Errors.PoolConfigurator_CallerNotPendingPoolAdmin({
                pendingPoolAdmin: pendingPoolAdmin,
                caller: msg.sender
            });
        }

        ILopoGlobals(globals()).transferOwnedPoolConfigurator(poolAdmin, msg.sender);

        emit PendingPoolAdminAccepted(poolAdmin, pendingPoolAdmin);

        poolAdmin = pendingPoolAdmin;
        pendingPoolAdmin = address(0);
    }

    function setPendingPoolAdmin(address pendingPoolAdmin_) external override whenNotPaused onlyPoolAdmin {
        pendingPoolAdmin = pendingPoolAdmin_;

        emit PendingPoolAdminSet(poolAdmin, pendingPoolAdmin_);
    }

    /* Globals Admin Functions */
    function setActive(bool active_) external override whenNotPaused {
        address globals_ = globals();
        if (msg.sender != globals_) {
            revert Errors.InvalidCaller(msg.sender, globals_);
        }
        emit SetAsActive(active = active_);
    }

    /* Pool Admin Functions */
    function setAllowedLender(address lender_, bool isValid_) external override whenNotPaused onlyPoolAdmin {
        emit AllowedLenderSet(lender_, isValidLender[lender_] = isValid_);
    }

    function setLiquidityCap(uint256 liquidityCap_) external override whenNotPaused onlyPoolAdmin {
        emit LiquidityCapSet(liquidityCap = liquidityCap_);
    }

    function setOpenToPublic() external override whenNotPaused onlyPoolAdmin {
        openToPublic = true;
        emit OpenToPublic();
    }

    /* Funding Functions */
    function requestFunds(address destination_, uint256 principal_) external override whenNotPaused {
        address asset_ = asset;
        address pool_ = pool;
        address loanManager_ = ADDRESSES_PROVIDER.getLoanManager();
        address withdrawalManager_ = ADDRESSES_PROVIDER.getWithdrawalManager();

        ILopoGlobals globals_ = ILopoGlobals(globals());

        if (msg.sender != loanManager_) {
            revert Errors.PoolConfigurator_CallerNotLoanManager({ poolManager: loanManager_, caller: msg.sender });
        }
        if (IERC20(pool_).totalSupply() == 0) {
            revert Errors.PoolConfigurator_PoolZeroSupply();
        }
        if (!_hasSufficientCover(address(globals_), asset_)) {
            revert Errors.PoolConfigurator_InsufficientCover();
        }
        if (destination_ == address(0)) {
            revert Errors.PoolConfigurator_DestinationIsZero();
        }
        if (!IERC20(asset_).transferFrom(pool_, destination_, principal_)) {
            revert Errors.ERC20TransferFailed(asset_, pool_, destination_, principal_);
        }

        uint256 lockedLiquidity_ = IWithdrawalManager(withdrawalManager_).lockedLiquidity();

        if (IERC20(asset_).balanceOf(pool_) < lockedLiquidity_) {
            revert Errors.PoolConfigurator_InsufficientLiquidity();
        }
    }

    /* Loan Default Functions */
    function triggerDefault(uint16 loanId_) external override whenNotPaused onlyPoolAdmin {
        uint256 losses_ = ILoanManager(loanManager()).triggerDefault(loanId_);
        _handleCover(losses_);
    }

    /* Pool Exit Functions */
    function processRedeem(
        uint256 shares_,
        address owner_,
        address sender_
    ) external override whenNotPaused onlyPool returns (uint256 redeemableShares_, uint256 resultingAssets_) {
        if (owner_ != sender_ && IPool(pool).allowance(owner_, sender_) == 0) {
            revert Errors.PoolConfigurator_NoAllowance({ owner: owner_, spender: sender_ });
        }
        (redeemableShares_, resultingAssets_) = IWithdrawalManager(withdrawalManager()).processExit(shares_, owner_);
        emit RedeemProcessed(owner_, redeemableShares_, resultingAssets_);
    }

    function processWithdraw(
        uint256 assets_,
        address owner_,
        address sender_
    ) external view override whenNotPaused onlyPool returns (uint256 redeemableShares_, uint256 resultingAssets_) {
        assets_;
        owner_;
        sender_;
        redeemableShares_;
        resultingAssets_; // Silence compiler warnings
        revert Errors.PoolConfigurator_WithdrawalNotImplemented();
    }

    function removeShares(
        uint256 shares_,
        address owner_
    ) external override whenNotPaused onlyPool returns (uint256 sharesReturned_) {
        emit SharesRemoved(
            owner_,
            sharesReturned_ = IWithdrawalManager(withdrawalManager()).removeShares(shares_, owner_)
        );
    }

    function requestRedeem(uint256 shares_, address owner_, address sender_) external override whenNotPaused onlyPool {
        address pool_ = pool;
        address withdrawalManager_ = withdrawalManager();

        if (!IPool(pool_).approve(withdrawalManager_, shares_)) {
            revert Errors.PoolConfigurator_PoolApproveWithdrawalManagerFailed(shares_);
        }

        if (sender_ != owner_ && shares_ == 0) {
            revert Errors.PoolConfigurator_NoAllowance({ owner: owner_, spender: sender_ });
        }

        IWithdrawalManager(withdrawalManager_).addShares(shares_, owner_);

        emit RedeemRequested(owner_, shares_);
    }

    function requestWithdraw(
        uint256 shares_,
        uint256 assets_,
        address owner_,
        address sender_
    ) external view override whenNotPaused {
        shares_;
        assets_;
        owner_;
        sender_; // Silence compiler warnings
        require(false, "Pool Configurator: request withdraw not enabled");
    }

    /* Pool Delegate Cover Functions */
    function depositCover(uint256 amount_) external override whenNotPaused {
        require(
            IERC20(asset).transferFrom(msg.sender, address(this), amount_),
            "Pool Configurator: Deposit cover transfer failed"
        );
        poolCover += amount_;

        emit CoverDeposited(amount_);
    }

    function withdrawCover(uint256 amount_, address recipient_) external override whenNotPaused onlyPoolAdmin {
        recipient_ = recipient_ == address(0) ? msg.sender : recipient_;

        IERC20(asset).transferFrom(address(this), recipient_, amount_);

        require(
            poolCover >= ILopoGlobals(globals()).minCoverAmount(address(this)),
            "Pool Configurator: withdraw cover insufficient cover"
        );
        emit CoverWithdrawn(amount_);
    }

    /* View Functions */

    function hasSufficientCover() public view override returns (bool hasSufficientCover_) {
        hasSufficientCover_ = _hasSufficientCover(globals(), asset);
    }

    function implementation() external pure returns (address implementation_) {
        implementation_ = address(0); // TODO: not implemented
    }

    function totalAssets() public view override returns (uint256 totalAssets_) {
        totalAssets_ = IERC20(asset).balanceOf(pool) + ILoanManager(loanManager()).assetsUnderManagement();
    }

    /* LP Token View Functions */
    function convertToExitShares(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = IPool(pool).convertToExitShares(assets_);
    }

    function getEscrowParams(
        address,
        uint256 shares_
    ) external view override returns (uint256 escrowShares_, address destination_) {
        // NOTE: `owner_` param not named to avoid compiler warning.
        (escrowShares_, destination_) = (shares_, address(this));
    }

    function maxDeposit(address receiver_) external view virtual override returns (uint256 maxAssets_) {
        maxAssets_ = _getMaxAssets(receiver_, totalAssets());
    }

    function maxMint(address receiver_) external view virtual override returns (uint256 maxShares_) {
        uint256 totalAssets_ = totalAssets();
        uint256 maxAssets_ = _getMaxAssets(receiver_, totalAssets_);

        maxShares_ = IPool(pool).previewDeposit(maxAssets_);
    }

    function maxRedeem(address owner_) external view virtual override returns (uint256 maxShares_) {
        address withdrawalManager_ = withdrawalManager();

        uint256 lockedShares_ = IWithdrawalManager(withdrawalManager_).lockedShares(owner_);
        maxShares_ = IWithdrawalManager(withdrawalManager_).isInExitWindow(owner_) ? lockedShares_ : 0;
    }

    function maxWithdraw(address owner_) external view virtual override returns (uint256 maxAssets_) {
        owner_; // Silence compiler warning
        maxAssets_ = 0; // NOTE: always returns 0 as withdraw is not implemented
    }

    function previewRedeem(address owner_, uint256 shares_) external view virtual override returns (uint256 assets_) {
        (, assets_) = IWithdrawalManager(withdrawalManager()).previewRedeem(owner_, shares_);
    }

    function previewWithdraw(address owner_, uint256 assets_) external view virtual override returns (uint256 shares_) {
        (, shares_) = IWithdrawalManager(withdrawalManager()).previewWithdraw(owner_, assets_);
    }

    function unrealizedLosses() public view override returns (uint256 unrealizedLosses_) {
        // NOTE: Use minimum to prevent underflows in the case that `unrealizedLosses` includes late interest and `totalAssets` does not.
        unrealizedLosses_ = _min(ILoanManager(loanManager()).unrealizedLosses(), totalAssets());
    }

    /* Internal Functions */
    function _revertIfConfigured() internal view {
        if (configured) {
            revert Errors.PoolConfigurator_Configured();
        }
    }

    function _revertIfPaused() internal view {
        if (ILopoGlobals(globals()).isFunctionPaused(msg.sig)) {
            revert Errors.PoolConfigurator_Paused();
        }
    }

    function _revertIfNotPoolAdmin() internal view {
        if (msg.sender != poolAdmin) {
            revert Errors.InvalidCaller({ caller: msg.sender, expectedCaller: poolAdmin });
        }
    }

    function _revertIfNotPoolAdminOrGovernor() internal view {
        if (msg.sender != poolAdmin && msg.sender != governor()) {
            revert Errors.PoolConfigurator_NotPoolAdminOrGovernor();
        }
    }

    function _revertIfNotPool() internal view {
        if (msg.sender != pool) {
            revert Errors.InvalidCaller({ caller: msg.sender, expectedCaller: pool });
        }
    }

    function _revertIfNotPoolAdminAndConfigured() internal view {
        if (msg.sender != poolAdmin && configured) {
            revert Errors.PoolConfigurator_ConfiguredAndNotPoolAdmin();
        }
    }

    function _hasSufficientCover(address globals_, address asset_) internal view returns (bool hasSufficientCover_) {
        hasSufficientCover_ = poolCover >= ILopoGlobals(globals_).minCoverAmount(address(this));
    }

    function _handleCover(uint256 losses_) internal {
        address globals_ = globals();

        uint256 availableCover_ = (poolCover * ILopoGlobals(globals_).maxCoverLiquidationPercent(address(this))) /
            HUNDRED_PERCENT;

        uint256 toPool_ = _min(availableCover_, losses_);

        // Transfer funds to pool
        poolCover -= toPool_;
        IERC20(asset).transferFrom(address(this), pool, toPool_);

        emit CoverLiquidated(toPool_);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 min_) {
        min_ = a_ < b_ ? a_ : b_;
    }

    function _getMaxAssets(address receiver_, uint256 totalAssets_) internal view returns (uint256 maxAssets_) {
        bool depositAllowed_ = openToPublic || isValidLender[receiver_];
        uint256 liquidityCap_ = liquidityCap;
        maxAssets_ = liquidityCap_ > totalAssets_ && depositAllowed_ ? liquidityCap_ - totalAssets_ : 0;
    }
}

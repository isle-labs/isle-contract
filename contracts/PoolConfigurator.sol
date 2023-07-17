// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";
import { PoolConfiguratorStorage } from "./proxy/PoolConfiguratorStorage.sol";
import { IGlobalsLike, IERC20Like, IWithdrawalManagerLike, ILoanManagerLike, ILoanLike, IPoolAdminCoverLike, IPoolLike } from "./interfaces/Interfaces.sol";

contract PoolConfigurator is IPoolConfigurator, PoolConfiguratorStorage {

    uint256 public constant HUNDRED_PERCENT = 100_0000;  // Four decimal precision.

    /* Modifiers */
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

    /* Initial Configuration Problem */
    function completeConfiguration() external override whenNotPaused onlyIfNotConfigured {
        configured = true;

        emit PoolConfigurationComplete();
    }

    /* Ownership Transfer functions */
    function acceptPoolAdmin() external override whenNotPaused {
        require(msg.sender == pendingPoolAdmin, "Pool Configurator:Not pending pool admin");
        IGlobalsLike(globals()).transferOwnedPoolConfigurator(poolAdmin, msg.sender);

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
        require(msg.sender == globals(), "Pool Configurator:Not globals");
        emit SetAsActive(active = active_);
    }

    /* Pool Delegate Admin Functions */
    function addLoanManager(address loanManagerFactory_) external view override whenNotPaused onlyPoolAdminOrNotConfigured returns (address loanManager_) {
        loanManagerFactory_;
        loanManager_ = address(0); // TODO: Actually deploy loan manager
    }

    function setWithdrawalManager(address withdrawalManager_) external override whenNotPaused onlyIfNotConfigured {
        // TODO: Actually check if withdrawal manager is valid
        emit WithdrawalManagerSet(withdrawalManager = withdrawalManager_);
    }

    function setAllowedLender(address lender_, bool isValid_) external override whenNotPaused onlyPoolAdmin {
        emit AllowedLenderSet(lender_, isValidLender[lender_] = isValid_);
    }

    function setIsLoanManager(address loanManager_, bool isLoanManager_) external override whenNotPaused onlyPoolAdmin {
        emit IsLoanManagerSet(loanManager_, isLoanManager[loanManager_] = isLoanManager_);

        for (uint i_; i_ < loanManagerList.length; ++i_) {
            if (loanManagerList[i_] == loanManager_) return;
        }

        revert("Pool Configurator: Invalid loan manager");
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

        IGlobalsLike globals_ = IGlobalsLike(globals());

        require(principal_ != 0, "Pool Configurator: Principal is zero");
        require(isLoanManager[msg.sender], "Pool Configurator: Not loan manager");
        require(IERC20Like(pool_).totalSupply() != 0, "Pool Configurator: Zero supply");
        require(_hasSufficientCover(address(globals_), asset_), "Pool Configurator: Insufficient cover");

        uint256 lockedLiquidity_ = IWithdrawalManagerLike(withdrawalManager).lockedLiquidity();

        require(destination_ != address(0), "Pool Configurator:Destination is zero");
        require(IERC20Like(asset_).transferFrom(pool_, destination_, principal_), "Pool Configurator: Transfer failed");

        require(IERC20Like(asset_).balanceOf(pool_) >= lockedLiquidity_, "Pool Configurator: Locked liquidity");
    }

    /* Loan Default Functions */
    function triggerDefault(address loan_, address liquidatorFactory_) external override whenNotPaused onlyPoolAdmin {
        (bool liquidationComplete_, uint256 losses_, uint256 platformFees_) = ILoanManagerLike(_getLoanManager(loan_)).triggerDefault(loan_, liquidatorFactory_);

        if (!liquidationComplete_) {
            emit CollateralLiquidationTriggered(loan_);
            return;
        }

        _handleCover(losses_, platformFees_);

        emit CollateralLiquidationFinished(loan_, losses_);
    }

    /* Pool Exit Functions */
    function processRedeem(uint256 shares_, address owner_, address sender_) external override whenNotPaused onlyPool returns (uint256 redeemableShares_, uint256 resultingAssets_) {
        require(owner_ == sender_ || IPoolLike(pool).allowance(owner_, sender_) > 0, "Pool Configurator: No allowance");

        ( redeemableShares_, resultingAssets_ ) = IWithdrawalManagerLike(withdrawalManager).processExit(shares_, owner_);
        emit RedeemProcessed(owner_, redeemableShares_, resultingAssets_);
    }

    function processWithdraw(uint256 assets_, address owner_, address sender_) external view override whenNotPaused onlyPool returns (uint256 redeemableShares_, uint256 resultingAssets_) {
        assets_; owner_; sender_; redeemableShares_; resultingAssets_;  // Silence compiler warnings
        require(false, "Pool Configurator: Withdrawal not implemented");
    }

    function removeShares(uint256 shares_, address owner_) external override whenNotPaused onlyPool returns (uint256 sharesReturned_) {
        emit SharesRemoved(owner_, sharesReturned_ = IWithdrawalManagerLike(withdrawalManager).removeShares(shares_, owner_));
    }

    function requestRedeem(uint256 shares_, address owner_, address sender_) external override whenNotPaused onlyPool {
        address pool_ = pool;

        require(IPoolLike(pool_).approve(withdrawalManager, shares_), "Pool Configurator: Approve failed");

        if (sender_ != owner_ && shares_ == 0) {
            require(IPoolLike(pool_).allowance(owner_, sender_) > 0, "Pool Configurator: No allowance");
        }

        IWithdrawalManagerLike(withdrawalManager).addShares(shares_, owner_);

        emit RedeemRequested(owner_, shares_);
    }

    function requestWithdraw(uint256 shares_, uint256 assets_, address owner_, address sender_) external view override whenNotPaused {
        shares_; assets_; owner_; sender_;  // Silence compiler warnings
        require(false, "Pool Configurator: request withdraw not enabled");
    }

    /* Pool Delegate Cover Functions */
    function depositCover(uint256 amount_) external override whenNotPaused {
        require(IERC20Like(asset).transferFrom(msg.sender, poolAdminCover, amount_), "Pool Configurator: Deposit cover transfer failed");
        emit CoverDeposited(amount_);
    }

    function withdrawCover(uint256 amount_, address recipient_) external override whenNotPaused onlyPoolAdmin {
        recipient_ = recipient_ == address(0) ? msg.sender : recipient_;
        IPoolAdminCoverLike(poolAdminCover).moveFunds(amount_, recipient_);

        require(IERC20Like(asset).balanceOf(poolAdminCover) >= IGlobalsLike(globals()).minCoverAmount(address(this)), "Pool Configurator: withdraw cover insufficient cover");
        emit CoverWithdrawn(amount_);
    }

    /* View Functions */
    function factory() external pure returns (address factory_) {
        factory_ = address(0); // TODO: not implemented
    }

    function globals() public pure override returns (address globals_) {
        globals_ = address(0); // TODO: not implemented
    }

    function governor() public view override returns (address governor_) {
        governor_ = IGlobalsLike(globals()).governor();
    }

    function hasSufficientCover() public view override returns (bool hasSufficientCover_) {
        hasSufficientCover_ = _hasSufficientCover(globals(), asset);
    }

    function implementation() external pure returns (address implementation_) {
        implementation_ = address(0); // TODO: not implemented
    }

    function loanManagerListLength() external view override returns (uint256 loanManagerListLength_) {
        loanManagerListLength_ = loanManagerList.length;
    }

    function totalAssets() public view override returns (uint256 totalAssets_) {
        totalAssets_ = IERC20Like(asset).balanceOf(pool);

        uint256 length_ = loanManagerList.length;

        for (uint256 i_; i_ < length_;) {
            totalAssets_ += ILoanManagerLike(loanManagerList[i_]).assetsUnderManagement();
            unchecked { i_++; }
        }
    }

    /* LP Token View Functions */
    function convertToExitShares(uint256 assets_) public view override returns (uint256 shares_) {
        shares_ = IPoolLike(pool).convertToExitShares(assets_);
    }

    function getEscrowParams(address, uint256 shares_) external view override returns (uint256 escrowShares_, address destination_) {
        // NOTE: `owner_` param not named to avoid compiler warning.
        ( escrowShares_, destination_) = (shares_, address(this));
    }

    function maxDeposit(address receiver_) external view virtual override returns (uint256 maxAssets_) {
        maxAssets_ = _getMaxAssets(receiver_, totalAssets());
    }

    function maxMint(address receiver_) external view virtual override returns (uint256 maxShares_) {
        uint256 totalAssets_ = totalAssets();
        uint256 maxAssets_   = _getMaxAssets(receiver_, totalAssets_);

        maxShares_ = IPoolLike(pool).previewDeposit(maxAssets_);
    }

    function maxRedeem(address owner_) external view virtual override returns (uint256 maxShares_) {
        uint256 lockedShares_ = IWithdrawalManagerLike(withdrawalManager).lockedShares(owner_);
        maxShares_            = IWithdrawalManagerLike(withdrawalManager).isInExitWindow(owner_) ? lockedShares_ : 0;
    }

    function maxWithdraw(address owner_) external view virtual override returns (uint256 maxAssets_) {
        owner_;          // Silence compiler warning
        maxAssets_ = 0;  // NOTE: always returns 0 as withdraw is not implemented
    }

    function previewRedeem(address owner_, uint256 shares_) external view virtual override returns (uint256 assets_) {
        ( , assets_ ) = IWithdrawalManagerLike(withdrawalManager).previewRedeem(owner_, shares_);
    }

    function previewWithdraw(address owner_, uint256 assets_) external view virtual override returns (uint256 shares_) {
        ( , shares_ ) = IWithdrawalManagerLike(withdrawalManager).previewWithdraw(owner_, assets_);
    }

    function unrealizedLosses() public view override returns (uint256 unrealizedLosses_) {
        uint256 length_ = loanManagerList.length;

        for (uint256 i_; i_ < length_;) {
            unrealizedLosses_ += ILoanManagerLike(loanManagerList[i_]).unrealizedLosses();
            unchecked { ++i_; }
        }

        // NOTE: Use minimum to prevent underflows in the case that `unrealizedLosses` includes late interest and `totalAssets` does not.
        unrealizedLosses_ = _min(unrealizedLosses_, totalAssets());
    }


    /* Internal Functions */
    function _revertIfConfigured() internal view {
        require(!configured, "Pool Configurator:Pool already configured");
    }

    function _revertIfPaused() internal view {
        require(!IGlobalsLike(globals()).isFunctionPaused(msg.sig), "Pool Configurator:Function paused");
    }

    function _revertIfNotPoolAdmin() internal view {
        require(msg.sender == poolAdmin, "Pool Configurator:Not pool admin");
    }

    function _revertIfNotPoolAdminOrGovernor() internal view {
        require(msg.sender == poolAdmin || msg.sender == governor(), "Pool Configurator:Not pool admin or governor");
    }

    function _revertIfNotPool() internal view {
        require(msg.sender == pool, "Pool Configurator:Not pool");
    }

    function _revertIfNotPoolAdminAndConfigured() internal view {
        require(msg.sender == poolAdmin || !configured, "Pool Configurator:Not pool admin and configured");
    }

    function _getLoanManager(address loan_) internal view returns (address loanManager_) {
        loanManager_ = ILoanLike(loan_).lender();

        require(isLoanManager[loanManager_], "Pool Configurator: Not loan manager");
    }

    function _hasSufficientCover(address globals_, address asset_) internal view returns (bool hasSufficientCover_) {
        hasSufficientCover_ = IERC20Like(asset_).balanceOf(poolAdminCover) >= IGlobalsLike(globals_).minCoverAmount(address(this));
    }


    function _handleCover(uint256 losses_, uint256 platformFees_) internal {
        address globals_ = globals();

        uint256 availableCover_ = IERC20Like(asset).balanceOf(poolAdminCover) * IGlobalsLike(globals_).maxCoverLiquidationPercent(address(this)) / HUNDRED_PERCENT;

        uint256 toTreasury_ = _min(availableCover_, platformFees_);
        uint256 toPool_ = _min(availableCover_ - platformFees_, losses_);

        if (toTreasury_ != 0) {
            IPoolAdminCoverLike(poolAdminCover).moveFunds(toTreasury_, IGlobalsLike(globals_).lopoTreasury());
        }

        if (toPool_ != 0) {
            IPoolAdminCoverLike(poolAdminCover).moveFunds(toPool_, pool);
        }

        emit CoverLiquidated(toTreasury_, toPool_);
    }

    function _min(uint256 a_, uint256 b_) internal pure returns (uint256 min_) {
        min_ = a_ < b_ ? a_ : b_;
    }

    function _getMaxAssets(address receiver_, uint256 totalAssets_) internal view returns (uint256 maxAssets_) {
        bool    depositAllowed_ = openToPublic || isValidLender[receiver_];
        uint256 liquidityCap_   = liquidityCap;
        maxAssets_              = liquidityCap_ > totalAssets_ && depositAllowed_ ? liquidityCap_ - totalAssets_ : 0;
    }
}

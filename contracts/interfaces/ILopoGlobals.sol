// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ILopoGlobals {
    /*** Events ***/

    /**
     *  @dev   The governorship has been accepted.
     *  @param _previousGovernor The previous governor.
     *  @param _currentGovernor  The new governor.
     */
    event GovernorshipTransferred(address indexed _previousGovernor, address indexed _currentGovernor);

    /**
     *  @dev   The pending governor has been set.
     *  @param _pendingGovernor The new pending governor.
     */
    event PendingGovernorSet(address indexed _pendingGovernor);

    /**
     *  @dev   The address for the Maple treasury has been set.
     *  @param _previousLopoVault The previous vault.
     *  @param _currentLopoVault The new vault.
     */
    event LopoVaultSet(address indexed _previousLopoVault, address indexed _currentLopoVault);

    /**
     *  @dev   The migration admin has been set.
     *  @param _previousMigrationAdmin The previous migration admin.
     *  @param _currentMigrationAdmin The new migration admin.
     */
    event MigrationAdminSet(address indexed _previousMigrationAdmin, address indexed _currentMigrationAdmin);

    /**
     * @dev The risk free rate has been set.
     * @param _previousRiskFreeRate The previous risk free rate.
     * @param _currentRiskFreeRate The new risk free rate.
     */
    event RiskFreeRateSet(uint256 indexed _previousRiskFreeRate, uint256 indexed _currentRiskFreeRate);

    /**
     * @dev The minimum pool liquidity ratio has been set.
     * @param _previousMinPoolLiquidityRatio The previous minimum pool liquidity ratio.
     * @param _currentMinPoolLiquidityRatio The new minimum pool liquidity ratio.
     */
    event MinPoolLiquidityRatioSet(
        uint256 indexed _previousMinPoolLiquidityRatio, uint256 indexed _currentMinPoolLiquidityRatio
    );

    /**
     * @dev The protocol fee rate has been set.
     * @param _previousProtocolFeeRate The previous protocol fee rate.
     * @param _currentProtocolFeeRate The new protocol fee rate.
     */
    event ProtocolFeeRateSet(uint256 indexed _previousProtocolFeeRate, uint256 indexed _currentProtocolFeeRate);

    /**
     *  @dev   The protocol pause was set to a new state.
     *  @param _caller         The address of the security admin or governor that performed the action.
     *  @param _protocolPaused The protocol paused state.
     */
    event ProtocolPauseSet(address indexed _caller, bool _protocolPaused);

    /**
     * @dev The pool is enabled or disabled.
     * @param _poolManager The address of the pool manager.
     * @param _isEnabled The enabled state of the pool.
     */
    event IsEnabledSet(address indexed _poolManager, bool _isEnabled);

    /**
     *  @dev   A valid borrower was set.
     *  @param _borrower The address of the borrower.
     *  @param _isValid  The validity of the borrower.
     */
    event ValidBorrowerSet(address indexed _borrower, bool _isValid);

    /**
     *  @dev   A valid asset was set.
     *  @param _collateralAsset The address of the collateral asset.
     *  @param _isValid         The validity of the collateral asset.
     */
    event ValidCollateralAssetSet(address indexed _collateralAsset, bool _isValid);

    /**
     *  @dev   A valid asset was set.
     *  @param _poolAsset The address of the asset.
     *  @param _isValid   The validity of the asset.
     */
    event ValidPoolAssetSet(address indexed _poolAsset, bool _isValid);

    /**
     *  @dev   A valid pool delegate was set.
     *  @param _account The address the account.
     *  @param _isValid The validity of the asset.
     */
    event ValidPoolDelegateSet(address indexed _account, bool _isValid);

    /**
     * @dev The minimum deposit limit has been set.
     * @param _poolManager The address of the pool manager.
     * @param _previousMinDepositLimit The previous minimum deposit limit.
     * @param _currentMinDepositLimit The new minimum deposit limit.
     */
    event MinDepositLimitSet(
        address indexed _poolManager, uint256 indexed _previousMinDepositLimit, uint256 indexed _currentMinDepositLimit
    );

    /**
     * @dev The withdrawal duration in days has been set.
     * @param _poolManager The address of the pool manager.
     * @param _previousWithdrawalDurationInDays The previous withdrawal duration in days.
     * @param _currentWithdrawalDurationInDays The new withdrawal duration in days.
     */
    event WithdrawalDurationInDaysSet(
        address indexed _poolManager,
        uint256 indexed _previousWithdrawalDurationInDays,
        uint256 indexed _currentWithdrawalDurationInDays
    );

    /*** View Function ***/
    function lopoVault() external view returns (address _lopoVault);

    function governor() external view returns (address _governor);

    function migrationAdmin() external view returns (address _migrationAdmin);

    function pendingLopoGovernor() external view returns (address _pendingLopoGovernor);

    function protocolPaused() external view returns (bool _protocolPaused);

    function isBorrower(address _borrower) external view returns (bool _isBorrower);

    function isCollateralAsset(address _asset) external view returns (bool _isCollateralAsset);

    function isPoolAsset(address _asset) external view returns (bool _isPoolAsset);

    // function isPoolDelegate(address _delegate) external view returns (bool _isPoolDelegate);

    function poolDelegates(address _poolDelegate)
        external
        view
        returns (address ownedPoolManager, bool isPoolDelegate);


}

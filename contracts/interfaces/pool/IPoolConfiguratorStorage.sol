// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolControllerStorage {

    /**
     *  @dev    Returns whether or not a pool is active.
     *  @return active_ True if the pool is active.
     */
    function active() external view returns (bool active_);

    /**
     *  @dev    Gets the address of the funds asset.
     *  @return asset_ The address of the funds asset.
     */
    function asset() external view returns (address asset_);

    /**
     *  @dev    Returns whether or not a pool is configured.
     *  @return configured_ True if the pool is configured.
     */
    function configured() external view returns (bool configured_);

    /**
     *  @dev    Gets the manager management fee rate.
     *  @return managerManagementFeeRate_ The value for the manager management fee rate.
     */
    function managerManagementFeeRate() external view returns (uint256 managerManagementFeeRate_);

    /**
     *  @dev    Returns whether or not the given address is a loan Controller.
     *  @param  loan_          The address of the loan.
     *  @return isLoanController_ True if the address is a loan Controller.
     */
    function isLoanController(address loan_) external view returns (bool isLoanController_);

    /**
     *  @dev    Returns whether or not a pool is open to public deposits.
     *  @return openToPublic_ True if the pool is open to public deposits.
     */
    function openToPublic() external view returns (bool openToPublic_);

    /**
     *  @dev    Gets the address of the pending pool manager.
     *  @return pendingPoolManager_ The address of the pending pool manager.
     */
    function pendingPoolManager() external view returns (address pendingPoolManager_);

    /**
     *  @dev    Gets the address of the pool.
     *  @return pool_ The address of the pool.
     */
    function pool() external view returns (address pool_);

    /**
     *  @dev    Gets the address of the pool delegate.
     *  @return poolManager_ The address of the pool delegate.
     */
    function poolManager() external view returns (address poolManager_);

    /**
     *  @dev    Gets the address of the pool delegate cover.
     *  @return poolManagerCover_ The address of the pool delegate cover.
     */
    function poolManagerCover() external view returns (address poolManagerCover_);

    /**
     *  @dev    Gets the address of the withdrawal Controller.
     *  @return withdrawalController_ The address of the withdrawal Controller.
     */
    function withdrawalController() external view returns (address withdrawalController_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolConfiguratorStorage {
    function active() external view returns (bool active_);
    function asset() external view returns (address asset_);
    function configured() external view returns (bool configured_);
    function openToPublic() external view returns (bool openToPublic_);
    function pendingPoolAdmin() external view returns (address pendingPoolAdmin_);
    function pool() external view returns (address pool_);
    function poolAdmin() external view returns (address poolAdmin_);
    function liquidityCap() external view returns (uint256 liquidityCap_);
    function isValidLender(address lender_) external view returns (bool isValidLender_);
    function adminFeeRate() external view returns (uint256 adminFeeRate_);
}

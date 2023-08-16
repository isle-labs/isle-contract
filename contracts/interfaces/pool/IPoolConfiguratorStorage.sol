// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolConfiguratorStorage {

    function poolAdmin() external view returns (address poolAdmin_);
    function pendingPoolAdmin() external view returns (address pendingPoolAdmin_);

    function asset() external view returns (address asset_);
    function pool() external view returns (address pool_);

    function active() external view returns (bool active_);
    function configured() external view returns (bool configured_);
    function openToPublic() external view returns (bool openToPublic_);

    function poolCover() external view returns (uint256 poolCover_);
    function liquidityCap() external view returns (uint256 liquidityCap_);
    function adminFeeRate() external view returns (uint256 adminFeeRate_);

    function isBuyer(address buyer_) external view returns (bool isBuyer_);
    function isSeller(address seller_) external view returns (bool isSeller_);
    function isLender(address lender_) external view returns (bool isLender_);
}

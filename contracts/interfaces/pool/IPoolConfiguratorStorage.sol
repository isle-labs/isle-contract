// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolConfiguratorStorage {
    function asset() external view returns (address asset_);
    function pool() external view returns (address pool_);

    function openToPublic() external view returns (bool openToPublic_);

    function poolCover() external view returns (uint256 poolCover_);
    function poolLimit() external view returns (uint256 poolLimit_);
    function adminFee() external view returns (uint256 adminFee_);

    function isBuyer(address buyer_) external view returns (bool isBuyer_);
    function isSeller(address seller_) external view returns (bool isSeller_);
    function isLender(address lender_) external view returns (bool isLender_);
}

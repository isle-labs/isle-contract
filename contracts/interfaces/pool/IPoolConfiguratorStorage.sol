// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolConfiguratorStorage {
    function asset() external view returns (address asset_);
    function pool() external view returns (address pool_);
    function buyer() external view returns (address buyer_);

    function config()
        external
        view
        returns (bool openToPublic_, uint24 adminFee_, uint32 gracePeriod_, uint96 baseRate_);

    function poolCover() external view returns (uint256 poolCover_);

    function isSeller(address seller_) external view returns (bool isSeller_);
    function isLender(address lender_) external view returns (bool isLender_);
}

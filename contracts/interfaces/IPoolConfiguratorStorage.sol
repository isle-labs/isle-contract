// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface IPoolConfiguratorStorage {
    /// @notice Retrieves the ERC20 asset used for the poo
    /// @return asset_ The address of the asset
    function asset() external view returns (address asset_);

    /// @notice Retrieves the pool that is under the management of the pool configurator
    /// @return pool_ The address of the pool
    function pool() external view returns (address pool_);

    /// @notice Retrives the address of the buyer
    /// @return buyer_ The address of the buyer
    /// @dev Each pool only has one buyer but can have multiple suppliers
    function buyer() external view returns (address buyer_);

    /// @notice Retrieves the amount of pool cover in {PoolConfigurator}
    /// @return poolCover_ The amount of pool cover deposited by the pool admin
    function poolCover() external view returns (uint256 poolCover_);

    /// @notice Returns whether the seller is a valid seller
    /// @return isSeller_ Whether the seller is a valid seller
    function isSeller(address seller_) external view returns (bool isSeller_);

    /// @notice Returns whether the lender is a valid lender
    /// @return isLender_ Whether the lender is a valid lender
    /// @dev Only valid lenders can deposit when the pool is not open to public
    function isLender(address lender_) external view returns (bool isLender_);
}

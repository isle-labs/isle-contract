// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IPoolConfiguratorLike {
    function removeShares(uint256 shares_, address owner_) external returns (uint256 sharesReturned_);
    function getEscrowParams(address owner_, uint256 shares_) external view returns (uint256 escrowShares_, address destination_);
    function requestRedeem(uint256 escrowShares_, address owner_, address sender_) external;
    function requestWithdraw(uint256 escrowShares_, uint256 assets_, address owner_, address sender_) external;

    function maxDeposit(address receiver_) external view returns (uint256 maxAssets_);
    function maxMint(address receiver_) external view returns (uint256 maxShares_);
    function maxRedeem(address owner_) external view returns (uint256 maxShares_);
    function maxWithdraw(address owner_) external view returns (uint256 maxAssets_);

    function previewRedeem(uint256 assets_) external view returns (uint256 shares_);
    function previewWithdraw(uint256 shares_) external view returns (uint256 assets_);

    function unrealizedGains() external view returns (uint256 unrealizedGains_);
    function unrealizedLosses() external view returns (uint256 unrealizedLosses_);
}

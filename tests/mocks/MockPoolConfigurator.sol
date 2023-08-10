// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../contracts/PoolConfigurator.sol";

// Not inheriting from PoolConfigurator because we need to rewrite some non-virtual functions
contract MockPoolConfigurator {
    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    constructor(IPoolAddressesProvider provider_) {
        ADDRESSES_PROVIDER = provider_;
    }

    function maxDeposit(address receiver_) external pure returns (uint256) {
        receiver_; // avoid warning
        return type(uint256).max;
    }

    function maxMint(address receiver_) external pure returns (uint256) {
        receiver_; // avoid warning
        return type(uint256).max;
    }

    function maxWithdraw(address receiver_) external pure returns (uint256) {
        receiver_; // avoid warning
        return type(uint256).max;
    }

    function maxRedeem(address receiver_) external pure returns (uint256) {
        receiver_; // avoid warning
        return type(uint256).max;
    }

    function previewWithdraw(address owner_, uint256 assets_) external pure returns (uint256) {
        owner_; // avoid warning
        return assets_;
    }

    function previewRedeem(address receiver_, uint256 shares_) external pure returns (uint256) {
        receiver_; // avoid warning
        return shares_;
    }

    function removeShares(uint256 shares_, address owner_) external pure returns (uint256 sharesReturned_) {
        owner_; // avoid warning
        sharesReturned_ = shares_;
    }

    function unrealizedLosses() public pure returns (uint256 unrealizedLosses_) {
        unrealizedLosses_ = 5000e6;
    }
}

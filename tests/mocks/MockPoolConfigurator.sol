// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../contracts/PoolConfigurator.sol";

contract MockPoolConfigurator is PoolConfigurator {
    constructor(IPoolAddressesProvider provider_) PoolConfigurator(provider_) { }

    function maxDeposit(address receiver_) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address receiver_) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address receiver_) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function maxRedeem(address receiver_) external pure override returns (uint256) {
        return type(uint256).max;
    }

    function previewWithdraw(address owner_, uint256 assets_) external pure override returns (uint256) {
        return assets_;
    }

    function previewRedeem(address receiver_, uint256 shares_) external pure override returns (uint256) {
        return shares_;
    }
}

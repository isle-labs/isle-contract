// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ILopoGlobals {
    /*//////////////////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////////////////*/
    event Initialized();
    event PoolConfiguratorOwnershipTransferred(address indexed fromPoolAdmin_, address indexed toPoolAdmin_, address indexed PoolConfigurator_);

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/
    function isPoolAsset(address asset_) external view returns (bool isPoolAsset_);
    function poolAdmins(address poolAdmin_) external view returns (address ownedPoolConfigurator_, bool isPoolAdmin_);
    function isPoolAdmin(address account_) external view returns (bool isPoolAdmin_);
    function ownedPoolConfigurator(address account_) external view returns (address poolConfigurator_);
    function transferOwnedPoolConfigurator(address fromPoolAdmin_, address toPoolAdmin_) external;
    function governor() external view returns (address governor_);
    function maxCoverLiquidationPercent(address poolConfigurator_) external view returns (uint256 maxCoverLiquidationPercent_);
    function minCoverAmount(address poolConfigurator_) external view returns (uint256 minCover_);
    function isFunctionPaused(address contract_, bytes4 sig_) external view returns (bool isFunctionPaused_);
    function isFunctionPaused(bytes4 sig_) external view returns (bool isFunctionPaused_);

}

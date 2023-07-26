// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";
import { VersionedInitializable } from "./libraries/upgradability/VersionedInitializable.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { Errors } from "./libraries/Errors.sol";

contract WithdrawalManager is IWithdrawalManager, VersionedInitializable {

    uint256 public constant WITHDRAWAL_MANAGER_REVISION = 0x1;

    IPoolAddressesProvider public immutable ADDRESSES_PROVIDER;

    /*//////////////////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor(IPoolAddressesProvider provider) {
        ADDRESSES_PROVIDER = provider;
    }

    function initialize(IPoolAddressesProvider provider_) external initializer {
        if (ADDRESSES_PROVIDER != provider_) {
            revert Errors.InvalidAddressProvider({expectedProvider: address(ADDRESSES_PROVIDER), provider: address(provider_)});
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function getRevision() internal pure virtual override returns (uint256 revision_) {
        revision_ = WITHDRAWAL_MANAGER_REVISION;
    }

}

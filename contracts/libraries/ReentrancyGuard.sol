// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "./Errors.sol";
import { VersionedInitializable } from "./upgradability/VersionedInitializable.sol";

abstract contract ReentrancyGuardUpgradeable is VersionedInitializable {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.ReentrancyGuard")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant ReentrancyGuardStorageLocation =
        0x9b779b17422d0df92223018b32b4d1fa46e071723d6817e2486d003becc55f00;

    function _getReentrancyGuardStorage() private pure returns (ReentrancyGuardStorage storage $) {
        assembly {
            $.slot := ReentrancyGuardStorageLocation
        }
    }

    function __ReentrancyGuard_init() internal onlyInitializing {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        $._status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        ReentrancyGuardStorage storage $ = _getReentrancyGuardStorage();
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if ($._status == ENTERED) {
            revert Errors.ReentrancyGuardReentrantCall();
        }
        $._status = ENTERED;
        _;
        $._status = NOT_ENTERED;
    }
}

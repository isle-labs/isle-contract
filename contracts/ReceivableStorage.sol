// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Receivable } from "./libraries/types/DataTypes.sol";

contract ReceivableStorage {
    address public lopoGlobals;
    uint256 internal _tokenIdCounter;

    // The mapping of the token id to the receivable info
    mapping(uint256 => Receivable.Info) public idToReceivableInfo;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[100] private __gap;
}

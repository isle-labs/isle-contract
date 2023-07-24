// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

contract ReceivableStorage {
    uint256 internal _tokenIdCounter;

    struct ReceivableInfo {
        // The address of the buyer that's expected to pay for this receivable
        address buyer;
        // The address of the seller that's expected to receive payment for this receivable
        address seller;
        // The amount of the receivable
        UD60x18 faceAmount;
        // The timestamp when the receivable is expected to be repaid
        uint256 repaymentTimestamp;
        // The receivable is created or not
        bool isValid;
        // The currency code specified by ISO 4217 in which the receivable is expressed, e.g. 840 for USD
        uint16 currencyCode;
    }

    /**
     * Below should be implemented in loanManager **
     */
    // // The amount of the receivable that's been advanced to the seller
    // UD60x18 advanceAmount;
    // // The timestamp when the receivable was created
    // uint256 initialTimestamp;
    // // The receivable is withdrawn or not
    // bool isWithdrawn;
    // The receivable is repaid or not
    // bool isRepaid;

    // The mapping of the token id to the receivable info
    mapping(uint256 => ReceivableInfo) public idToReceivableInfo;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[100] private __gap;
}

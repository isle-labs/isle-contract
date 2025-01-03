// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Loan } from "contracts/libraries/types/DataTypes.sol";

import { IPoolAddressesProvider } from "contracts/interfaces/IPoolAddressesProvider.sol";

import { LoanManager } from "contracts/LoanManager.sol";

contract LoanManagerHarness is LoanManager {
    constructor(IPoolAddressesProvider provider_) LoanManager(provider_) { }

    function exposed_addPaymentToList(uint48 paymentDueDate_) external returns (uint24 paymentId_) {
        paymentId_ = _addPaymentToList(paymentDueDate_);
    }

    function exposed_removePaymentFromList(uint256 paymentId_) external {
        _removePaymentFromList(paymentId_);
    }

    function getSortedPayment(uint256 paymentId_) public view returns (Loan.SortedPayment memory sortedPayment_) {
        sortedPayment_ = sortedPayments[paymentId_];
    }
}

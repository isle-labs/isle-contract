// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { LoanManagerHarness } from "tests/mocks/LoanManagerHarness.sol";

import { Base_Test } from "../../../Base.t.sol";
import { LoanManager_Unit_Shared_Test } from "./LoanManager.t.sol";

abstract contract PaymentList_Unit_Shared_Test is LoanManager_Unit_Shared_Test {
    using SafeCast for uint256;

    LoanManagerHarness internal loanManagerHarness;

    function setUp() public virtual override {
        Base_Test.setUp();

        // Setup pool addresses provider
        changePrank(users.governor);
        isleGlobals = deployGlobals();
        poolAddressesProvider = deployPoolAddressesProvider(isleGlobals);
        setDefaultGlobals(poolAddressesProvider);

        loanManagerHarness = new LoanManagerHarness(poolAddressesProvider);
    }

    function addDefaultPayment(uint256 paymentDueDate_) internal returns (uint24 paymentId_) {
        paymentId_ = loanManagerHarness.exposed_addPaymentToList(SafeCast.toUint48(paymentDueDate_));
    }
}

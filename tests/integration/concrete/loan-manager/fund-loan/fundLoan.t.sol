// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/callable.t.sol";

contract FundLoan_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        isleGlobals.setContractPaused(address(loanManager), true);

        changePrank(users.poolAdmin);
        vm.expectRevert(abi.encodeWithSelector(Errors.FunctionPaused.selector, bytes4(keccak256("fundLoan(uint16)"))));
        loanManager.fundLoan(1);
    }

    function test_RevertWhen_CallerNotPoolAdmin() external whenNotPaused {
        changePrank(users.governor);
        vm.expectRevert(abi.encodeWithSelector(Errors.NotPoolAdmin.selector, address(users.governor)));
        loanManager.fundLoan(1);
    }

    function test_FundLoan() external whenNotPaused whenCallerPoolAdmin {
        uint256 receivableTokenId = createDefaultReceivable();

        changePrank(users.buyer);
        uint16 loanId = requestLoan(receivableTokenId, defaults.PRINCIPAL_REQUESTED());

        changePrank(users.poolAdmin);
        vm.expectEmit(true, true, true, true);
        emit PrincipalOutUpdated(uint128(defaults.PRINCIPAL_REQUESTED()));

        vm.expectEmit(true, true, true, true);
        emit PaymentAdded(1, 1, 0, 0, MAY_1_2023, defaults.MAY_31_2023(), defaults.NEW_RATE_ZERO_FEE_RATE());

        vm.expectEmit(true, true, true, true);
        emit IssuanceParamsUpdated(uint48(defaults.MAY_31_2023()), defaults.NEW_RATE_ZERO_FEE_RATE(), 0e6);

        loanManager.fundLoan(loanId);
    }
}

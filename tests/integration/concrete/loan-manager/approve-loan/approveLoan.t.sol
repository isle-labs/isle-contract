// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../loanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/Callable.t.sol";

contract ApproveLoan_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();
    }

    modifier WhenCallerReceivableBuyer() {
        _;
    }

    modifier WhenCollateralAssetAllowed() {
        _;
    }

    modifier WhenReceivableValid() {
        _;
    }

    modifier WhenPrincipalRequestedLessThanFaceAmount() {
        _;
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        lopoGlobals.setContractPause(address(loanManager), true);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.FunctionPaused.selector,
                bytes4(keccak256("approveLoan(address,uint256,uint256,uint256,uint256[2])"))
            )
        );
        loanManager.approveLoan(address(receivable), 0, 0, 0, [uint256(0), uint256(0)]);
    }

    function test_RevertWhen_CollateralAssetNotAllowed() external WhenNotPaused {
        changePrank(users.governor);
        lopoGlobals.setValidCollateralAsset(address(receivable), false);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LoanManager_CollateralAssetNotAllowed.selector, address(receivable))
        );
        loanManager.approveLoan(address(receivable), 0, 0, 0, [uint256(0), uint256(0)]);
    }

    function test_RevertWhen_CallerNotReceivableBuyer() external WhenNotPaused WhenCollateralAssetAllowed {
        createReceivable(defaults.FACE_AMOUNT());
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LoanManager_CallerNotReceivableBuyer.selector, address(users.buyer))
        );
        loanManager.approveLoan(address(receivable), 0, 0, 0, [uint256(0), uint256(0)]);
    }

    function test_RevertWhen_ReceivableInvalid()
        external
        WhenNotPaused
        WhenCollateralAssetAllowed
        WhenCallerReceivableBuyer
    {
        createReceivable(defaults.FACE_AMOUNT());

        changePrank(users.poolAdmin);
        poolConfigurator.setValidBuyer(users.buyer, false);

        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_InvalidReceivable.selector, 0));

        changePrank(users.buyer);
        loanManager.approveLoan(address(receivable), 0, 0, 0, [uint256(0), uint256(0)]);
    }

    function test_RevertWhen_PrincipalRequestedGreaterThanFaceAmount()
        external
        WhenNotPaused
        WhenCollateralAssetAllowed
        WhenCallerReceivableBuyer
        WhenReceivableValid
    {
        uint256 receivablesTokenId = createReceivable(defaults.FACE_AMOUNT());
        changePrank(users.buyer);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.LoanManager_PrincipalRequestedTooHigh.selector,
                defaults.FACE_AMOUNT() + 1,
                defaults.FACE_AMOUNT()
            )
        );
        loanManager.approveLoan(address(receivable), receivablesTokenId, 7, 100_000e6 + 1, [uint256(0), uint256(0)]);
    }

    function test_approveLoan()
        external
        WhenNotPaused
        WhenCollateralAssetAllowed
        WhenCallerReceivableBuyer
        WhenReceivableValid
        WhenPrincipalRequestedLessThanFaceAmount
    {
        uint256 receivablesTokenId = createReceivable(defaults.FACE_AMOUNT());
        changePrank(users.buyer);
        vm.expectEmit(true, true, true, true);
        emit LoanApproved(1);
        loanManager.approveLoan(
            address(receivable),
            receivablesTokenId,
            defaults.GRACE_PERIOD(),
            defaults.PRINCIPAL_REQUESTED(),
            [uint256(0), uint256(0)]
        );
    }
}

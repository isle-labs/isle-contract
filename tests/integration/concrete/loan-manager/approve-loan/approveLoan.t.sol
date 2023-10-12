// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { LoanManager_Integration_Concrete_Test } from "../LoanManager.t.sol";
import { Callable_Integration_Shared_Test } from "../../../shared/loan-manager/callable.t.sol";

contract ApproveLoan_Integration_Concrete_Test is
    LoanManager_Integration_Concrete_Test,
    Callable_Integration_Shared_Test
{
    function setUp() public virtual override(LoanManager_Integration_Concrete_Test, Callable_Integration_Shared_Test) {
        LoanManager_Integration_Concrete_Test.setUp();
        Callable_Integration_Shared_Test.setUp();
    }

    modifier whenCallerReceivableBuyer() {
        _;
    }

    modifier whenCollateralAssetAllowed() {
        _;
    }

    modifier whenReceivableValid() {
        _;
    }

    modifier whenPrincipalRequestedLessThanFaceAmount() {
        _;
    }

    function test_RevertWhen_FunctionPaused() external {
        changePrank(users.governor);
        isleGlobals.setContractPaused(address(loanManager), true);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.FunctionPaused.selector,
                bytes4(keccak256("approveLoan(address,uint256,uint256,uint256,uint256[2])"))
            )
        );
        loanManager.approveLoan(address(receivable), 0, 0, 0, [uint256(0), uint256(0)]);
    }

    function test_RevertWhen_CollateralAssetNotAllowed() external whenNotPaused {
        changePrank(users.governor);
        isleGlobals.setValidCollateralAsset(address(receivable), false);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.LoanManager_CollateralAssetNotAllowed.selector, address(receivable))
        );
        loanManager.approveLoan(address(receivable), 0, 0, 0, [uint256(0), uint256(0)]);
    }

    function test_RevertWhen_CallerNotReceivableBuyer() external whenNotPaused whenCollateralAssetAllowed {
        createDefaultReceivable();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.LoanManager_CallerNotReceivableBuyer.selector, address(users.buyer))
        );
        loanManager.approveLoan(address(receivable), 0, 0, 0, [uint256(0), uint256(0)]);
    }

    function test_RevertWhen_ReceivableInvalid()
        external
        whenNotPaused
        whenCollateralAssetAllowed
        whenCallerReceivableBuyer
    {
        createDefaultReceivable();

        changePrank(users.poolAdmin);
        // Hacky workaround: we should instead use receivables with a wrong buyer, not change the buyer of the
        // {PoolConfigurator}.
        poolConfigurator.setBuyer(users.caller);

        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_InvalidReceivable.selector, 0));

        changePrank(users.buyer);
        loanManager.approveLoan(address(receivable), 0, 0, 0, [uint256(0), uint256(0)]);
    }

    function test_RevertWhen_PrincipalRequestedGreaterThanFaceAmount()
        external
        whenNotPaused
        whenCollateralAssetAllowed
        whenCallerReceivableBuyer
        whenReceivableValid
    {
        uint256 receivablesTokenId = createDefaultReceivable();
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
        whenNotPaused
        whenCollateralAssetAllowed
        whenCallerReceivableBuyer
        whenReceivableValid
        whenPrincipalRequestedLessThanFaceAmount
    {
        uint256 receivablesTokenId = createDefaultReceivable();
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

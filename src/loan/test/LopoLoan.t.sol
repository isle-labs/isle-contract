// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { Address, TestUtils } from "contract-test-utils/test.sol";
import { MockERC20 }          from "../../erc20/test/mocks/MockERC20.sol";

import { ConstructableLopoLoan, LopoLoanHarness } from "./harnesses/LopoLoanHarnesses.sol";

import { EmptyContract, MockFactory, MockFeeManager, MockGlobals, MockLoanManager } from "./mocks/Mocks.sol";

contract LopoLoanTests is TestUtils {

    LopoLoanHarness internal loan;
    MockFactory      internal factory;
    MockFeeManager   internal feeManager;
    MockGlobals      internal globals;

    address internal borrower      = address(new Address());
    address internal governor      = address(new Address());
    address internal securityAdmin = address(new Address());
    address internal user          = address(new Address());

    address internal lender;

    bool internal locked;  // Helper state variable to avoid infinite loops when using the modifier.

    function setUp() external {
        feeManager = new MockFeeManager();
        globals    = new MockGlobals(governor);
        lender     = address(new MockLoanManager());
        loan       = new LopoLoanHarness();

        factory = new MockFactory(address(globals));

        loan.__setBorrower(borrower);
        loan.__setFactory(address(factory));
        loan.__setFeeManager(address(feeManager));
        loan.__setLender(lender);

        globals.__setIsInstanceOf(true);
        globals.__setSecurityAdmin(securityAdmin);
    }

    /***********************************/
    /*** Collateral Management Tests ***/
    /***********************************/

    function test_getAdditionalCollateralRequiredFor_varyAmount() external {
        loan.__setCollateralRequired(800_000);
        loan.__setDrawableFunds(1_000_000);
        loan.__setPrincipal(500_000);
        loan.__setPrincipalRequested(1_000_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(0),         0);
        assertEq(loan.getAdditionalCollateralRequiredFor(100_000),   0);
        assertEq(loan.getAdditionalCollateralRequiredFor(200_000),   0);
        assertEq(loan.getAdditionalCollateralRequiredFor(300_000),   0);
        assertEq(loan.getAdditionalCollateralRequiredFor(400_000),   0);
        assertEq(loan.getAdditionalCollateralRequiredFor(500_000),   0);
        assertEq(loan.getAdditionalCollateralRequiredFor(600_000),   80_000);
        assertEq(loan.getAdditionalCollateralRequiredFor(700_000),   160_000);
        assertEq(loan.getAdditionalCollateralRequiredFor(800_000),   240_000);
        assertEq(loan.getAdditionalCollateralRequiredFor(900_000),   320_000);
        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 400_000);
    }

    function test_getAdditionalCollateralRequiredFor_varyCollateralRequired() external {
        loan.__setDrawableFunds(1_000_000);
        loan.__setPrincipal(1_000_000);
        loan.__setPrincipalRequested(1_000_000);

        loan.__setCollateralRequired(0);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 0);

        loan.__setCollateralRequired(200_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 200_000);

        loan.__setCollateralRequired(1_000_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 1_000_000);

        loan.__setCollateralRequired(2_400_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 2_400_000);
    }

    function test_getAdditionalCollateralRequiredFor_varyDrawableFunds() external {
        loan.__setCollateralRequired(2_400_000);
        loan.__setPrincipal(1_000_000);
        loan.__setPrincipalRequested(1_000_000);

        loan.__setDrawableFunds(1_000_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 2_400_000);

        loan.__setDrawableFunds(1_200_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 1_920_000);

        loan.__setDrawableFunds(1_800_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 480_000);

        loan.__setDrawableFunds(2_000_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 0);

        loan.__setDrawableFunds(3_000_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(1_000_000), 0);
    }

    function test_getAdditionalCollateralRequiredFor_varyPrincipal() external {
        loan.__setCollateralRequired(2_000_000);
        loan.__setDrawableFunds(500_000);
        loan.__setPrincipalRequested(1_000_000);

        loan.__setPrincipal(0);

        assertEq(loan.getAdditionalCollateralRequiredFor(500_000), 0);

        loan.__setPrincipal(200_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(500_000), 400_000);

        loan.__setPrincipal(500_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(500_000), 1_000_000);

        loan.__setPrincipal(1_000_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(500_000), 2_000_000);

        loan.__setCollateral(1_000_000);

        assertEq(loan.getAdditionalCollateralRequiredFor(500_000), 1_000_000);
    }

    function test_excessCollateral_varyCollateral() external {
        loan.__setCollateralRequired(800_000);
        loan.__setPrincipal(500_000);
        loan.__setPrincipalRequested(1_000_000);

        loan.__setCollateral(0);

        assertEq(loan.excessCollateral(), 0);

        loan.__setCollateral(200_000);

        assertEq(loan.excessCollateral(), 0);

        loan.__setCollateral(400_000);

        assertEq(loan.excessCollateral(), 0);

        loan.__setCollateral(500_000);

        assertEq(loan.excessCollateral(), 100_000);

        loan.__setCollateral(1_000_000);

        assertEq(loan.excessCollateral(), 600_000);

        loan.__setDrawableFunds(1_000_000);
        loan.__setCollateral(0);

        assertEq(loan.excessCollateral(), 0);

        loan.__setCollateral(1_000_000);

        assertEq(loan.excessCollateral(), 1_000_000);
    }

    function test_excessCollateral_varyDrawableFunds() external {
        loan.__setCollateral(1_200_000);
        loan.__setCollateralRequired(2_400_000);
        loan.__setPrincipal(500_000);
        loan.__setPrincipalRequested(1_000_000);

        loan.__setDrawableFunds(0);

        assertEq(loan.excessCollateral(), 0);

        loan.__setDrawableFunds(200_000);

        assertEq(loan.excessCollateral(), 480_000);

        loan.__setDrawableFunds(500_000);

        assertEq(loan.excessCollateral(), 1_200_000);
    }

    function test_excessCollateral_varyPrincipal() external {
        loan.__setCollateral(1_200_000);
        loan.__setCollateralRequired(2_400_000);
        loan.__setPrincipalRequested(1_000_000);

        loan.__setPrincipal(1_000_000);

        assertEq(loan.excessCollateral(), 0);

        loan.__setPrincipal(500_000);

        assertEq(loan.excessCollateral(), 0);

        loan.__setPrincipal(200_000);

        assertEq(loan.excessCollateral(), 720_000);

        loan.__setPrincipal(0);

        assertEq(loan.excessCollateral(), 1_200_000);
    }

    /**************************************************************************************************************************************/
    /*** Access Control Tests                                                                                                           ***/
    /**************************************************************************************************************************************/

    function test_migrate_acl() external {
        address mockMigrator = address(new EmptyContract());

        vm.expectRevert("ML:M:NOT_FACTORY");
        loan.migrate(mockMigrator, new bytes(0));

        vm.prank(address(factory));
        loan.migrate(mockMigrator, new bytes(0));
    }

    function test_setImplementation_acl() external {
        address someContract = address(new EmptyContract());

        vm.expectRevert("ML:SI:NOT_FACTORY");
        loan.setImplementation(someContract);

        vm.prank(address(factory));
        loan.setImplementation(someContract);
    }

    function test_drawdownFunds_acl() external {
        MockERC20 fundsAsset = new MockERC20("Funds Asset", "FA", 18);

        fundsAsset.mint(address(loan), 1_000_000);

        loan.__setDrawableFunds(1_000_000);
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPrincipalRequested(1_000_000);  // Needed for the getAdditionalCollateralRequiredFor

        vm.expectRevert("ML:NOT_BORROWER");
        loan.drawdownFunds(1, borrower);

        vm.prank(borrower);
        loan.drawdownFunds(1, borrower);
    }

    function test_proposeNewTerms() external {
        address mockRefinancer = address(new EmptyContract());
        uint256 deadline       = block.timestamp + 10 days;
        bytes[] memory calls   = new bytes[](1);
        calls[0]               = new bytes(0);

        vm.prank(borrower);
        bytes32 refinanceCommitment = loan.proposeNewTerms(mockRefinancer, deadline, calls);

        assertEq(refinanceCommitment, bytes32(0x1e5d5a3131b2767db93add6039629037a11bd673fe4726b7e3afc4527f96aeaf));
    }

    function test_proposeNewTerms_acl() external {
        address mockRefinancer = address(new EmptyContract());
        uint256 deadline       = block.timestamp + 10 days;
        bytes[] memory calls   = new bytes[](1);
        calls[0]               = new bytes(0);

        vm.expectRevert("ML:NOT_BORROWER");
        loan.proposeNewTerms(mockRefinancer, deadline, calls);

        vm.prank(borrower);
        loan.proposeNewTerms(mockRefinancer, deadline, calls);
    }

    function test_proposeNewTerms_invalidDeadline() external {
        address mockRefinancer = address(new EmptyContract());
        bytes[] memory calls   = new bytes[](1);
        calls[0]               = new bytes(0);

        vm.startPrank(borrower);
        vm.expectRevert("ML:PNT:INVALID_DEADLINE");
        loan.proposeNewTerms(mockRefinancer, block.timestamp - 1, calls);

        loan.proposeNewTerms(mockRefinancer, block.timestamp, calls);
    }

    function test_rejectNewTerms_acl() external {
        address mockRefinancer = address(new EmptyContract());
        uint256 deadline       = block.timestamp + 10 days;
        bytes[] memory calls   = new bytes[](1);
        calls[0]               = new bytes(0);

        loan.__setRefinanceCommitment(keccak256(abi.encode(address(mockRefinancer), deadline, calls)));

        vm.expectRevert("ML:RNT:NO_AUTH");
        loan.rejectNewTerms(mockRefinancer, deadline, calls);

        vm.prank(borrower);
        loan.rejectNewTerms(mockRefinancer, deadline, calls);

        // Set again
        loan.__setRefinanceCommitment(keccak256(abi.encode(address(mockRefinancer), deadline, calls)));

        vm.expectRevert("ML:RNT:NO_AUTH");
        loan.rejectNewTerms(mockRefinancer, deadline, calls);

        vm.prank(lender);
        loan.rejectNewTerms(mockRefinancer, deadline, calls);
    }

    function test_removeCollateral_acl() external {
        MockERC20 collateralAsset = new MockERC20("Collateral Asset", "CA", 18);

        loan.__setCollateral(1);
        loan.__setCollateralAsset(address(collateralAsset));
        loan.__setPrincipalRequested(1); // Needed for the collateralMaintained check

        collateralAsset.mint(address(loan), 1);

        vm.expectRevert("ML:NOT_BORROWER");
        loan.removeCollateral(1, borrower);

        vm.prank(borrower);
        loan.removeCollateral(1, borrower);
    }

    function test_setPendingBorrower_acl() external {
        globals.setValidBorrower(address(1), true);

        vm.expectRevert("ML:NOT_BORROWER");
        loan.setPendingBorrower(address(1));

        vm.prank(borrower);
        loan.setPendingBorrower(address(1));
    }

    function test_acceptBorrower_acl() external {
        loan.__setPendingBorrower(user);

        vm.expectRevert("ML:AB:NOT_PENDING_BORROWER");
        loan.acceptBorrower();

        vm.prank(user);
        loan.acceptBorrower();
    }

    function test_acceptNewTerms_acl() external {
        MockERC20 token = new MockERC20("MockToken", "MA", 18);

        loan.__setCollateralAsset(address(token));                // Needed for the getUnaccountedAmount check
        loan.__setFundsAsset(address(token));                     // Needed for the getUnaccountedAmount check
        loan.__setNextPaymentDueDate(block.timestamp + 25 days);  // Needed for origination fee checks
        loan.__setPaymentInterval(30 days);                       // Needed for origination fee checks
        loan.__setPaymentsRemaining(3);                           // Needed for origination fee checks
        loan.__setPrincipalRequested(1);                          // Needed for the collateralMaintained check

        address mockRefinancer = address(new EmptyContract());
        uint256 deadline       = block.timestamp + 10 days;
        bytes[] memory calls   = new bytes[](1);
        calls[0]               = new bytes(0);

        loan.__setRefinanceCommitment(keccak256(abi.encode(mockRefinancer, deadline, calls)));

        vm.expectRevert("ML:NOT_LENDER");
        loan.acceptNewTerms(mockRefinancer, deadline, calls);

        vm.prank(lender);
        loan.acceptNewTerms(mockRefinancer, deadline, calls);
    }

    function test_removeLoanImpairment_acl() external {
        loan.__setOriginalNextPaymentDueDate(block.timestamp + 300);

        vm.expectRevert("ML:NOT_LENDER");
        loan.removeLoanImpairment();

        vm.prank(lender);
        loan.removeLoanImpairment();

        assertEq(loan.nextPaymentDueDate(), block.timestamp + 300);
    }

    function test_repossess_acl() external {
        MockERC20 asset = new MockERC20("Asset", "AST", 18);

        loan.__setCollateralAsset(address(asset));
        loan.__setFundsAsset(address(asset));
        loan.__setNextPaymentDueDate(1);

        vm.warp(loan.nextPaymentDueDate() + loan.gracePeriod() + 1);

        vm.expectRevert("ML:NOT_LENDER");
        loan.repossess(lender);

        vm.prank(lender);
        loan.repossess(lender);
    }

    function test_impairLoan_acl() external {
        uint256 start = 1 days;  // Non-zero start time.

        vm.warp(start);

        uint256 originalNextPaymentDate = start + 10 days;

        loan.__setNextPaymentDueDate(originalNextPaymentDate);

        vm.expectRevert("ML:NOT_LENDER");
        loan.impairLoan();

        vm.prank(lender);
        loan.impairLoan();
    }

    function test_setPendingLender_acl() external {
        vm.expectRevert("ML:NOT_LENDER");
        loan.setPendingLender(governor);

        vm.prank(lender);
        loan.setPendingLender(governor);
    }

    function test_acceptLender_acl() external {
        loan.__setPendingLender(address(1));

        vm.expectRevert("ML:AL:NOT_PENDING_LENDER");
        loan.acceptLender();

        vm.prank(address(1));
        loan.acceptLender();
    }

    function test_upgrade_acl_noAuth() external {
        address newImplementation = address(new LopoLoanHarness());

        vm.expectRevert("ML:U:NO_AUTH");
        loan.upgrade(1, abi.encode(newImplementation));
    }

    function test_upgrade_acl_noAuth_asBorrower() external {
        address newImplementation = address(new LopoLoanHarness());

        vm.prank(borrower);
        vm.expectRevert("ML:U:NO_AUTH");
        loan.upgrade(1, abi.encode(newImplementation));
    }

    function test_upgrade_acl_securityAdmin() external {
        address newImplementation = address(new LopoLoanHarness());

        vm.prank(securityAdmin);
        loan.upgrade(1, abi.encode(newImplementation));

        assertEq(loan.implementation(), newImplementation);
    }

    /**************************************************************************************************************************************/
    /*** Loan Transfer-Related Tests                                                                                                    ***/
    /**************************************************************************************************************************************/

    function test_acceptNewTerms() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        loan.__setFundsAsset(address(fundsAsset));
        loan.__setNextPaymentDueDate(block.timestamp + 25 days);  // Needed for origination fee checks
        loan.__setPaymentInterval(30 days);                       // Needed for origination fee checks
        loan.__setPaymentsRemaining(3);                           // Needed for origination fee checks
        loan.__setPrincipal(1);
        loan.__setPrincipalRequested(1);

        address refinancer = address(new EmptyContract());
        uint256 deadline = block.timestamp + 10 days;
        bytes[] memory calls = new bytes[](1);
        calls[0] = abi.encodeWithSignature("increasePrincipal(uint256)", 1);

        loan.__setRefinanceCommitment(keccak256(abi.encode(refinancer, deadline, calls)));

        fundsAsset.mint(address(loan), 1);

        // Mock refinancer increasing principal and drawable funds.
        loan.__setDrawableFunds(1);
        loan.__setPrincipal(2);

        vm.prank(lender);
        loan.acceptNewTerms(refinancer, deadline, calls);
    }

    function test_impairLoan() external {
        uint256 start = 1 days;  // Non-zero start time.

        vm.warp(start);

        uint256 originalNextPaymentDate = start + 10 days;

        loan.__setNextPaymentDueDate(originalNextPaymentDate);

        assertEq(loan.originalNextPaymentDueDate(), 0);
        assertEq(loan.nextPaymentDueDate(),         originalNextPaymentDate);

        vm.prank(lender);
        loan.impairLoan();

        assertEq(loan.originalNextPaymentDueDate(), originalNextPaymentDate);
        assertEq(loan.nextPaymentDueDate(),         start);
    }

    function test_impairLoan_lateLoan() external {
        uint256 start = 1 days;  // Non-zero start time.

        uint256 originalNextPaymentDate = start + 10 days;

        loan.__setNextPaymentDueDate(originalNextPaymentDate);

        vm.warp(originalNextPaymentDate + 1 days);

        assertEq(loan.originalNextPaymentDueDate(), 0);
        assertEq(loan.nextPaymentDueDate(),         originalNextPaymentDate);

        vm.prank(lender);
        loan.impairLoan();

        assertEq(loan.originalNextPaymentDueDate(), originalNextPaymentDate);
        assertEq(loan.nextPaymentDueDate(),         originalNextPaymentDate);
    }

    function test_removeLoanImpairment_notImpaired() external {
        vm.prank(lender);
        vm.expectRevert("ML:RLI:NOT_ILPAIRED");
        loan.removeLoanImpairment();
    }

    function test_removeLoanImpairment_pastDate() external {
        vm.warp(1 days);

        loan.__setOriginalNextPaymentDueDate(block.timestamp - 1);

        vm.prank(lender);
        vm.expectRevert("ML:RLI:PAST_DATE");
        loan.removeLoanImpairment();
    }

    function test_removeLoanImpairment_success() external {
        vm.warp(1 days);

        loan.__setNextPaymentDueDate(block.timestamp);
        loan.__setOriginalNextPaymentDueDate(block.timestamp + 1);

        assertEq(loan.nextPaymentDueDate(), block.timestamp);

        vm.prank(lender);
        loan.removeLoanImpairment();

        assertEq(loan.nextPaymentDueDate(), block.timestamp + 1);
    }

    function test_fundLoan_pushPattern() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 amount = 1_000_000;

        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(1);
        loan.__setPrincipalRequested(amount);

        // Fails without pushing funds
        vm.prank(lender);
        vm.expectRevert(ARITHMETIC_ERROR);
        loan.fundLoan();

        fundsAsset.mint(address(loan), amount);

        assertEq(fundsAsset.balanceOf(address(loan)), amount);
        assertEq(loan.principal(),                    0);

        vm.prank(lender);
        loan.fundLoan();

        assertEq(fundsAsset.balanceOf(address(loan)), amount);
        assertEq(loan.principal(),                    amount);
    }

    // TODO: Add overfund and overfund ANT test failure cases.

    function test_drawdownFunds_withoutAdditionalCollateralRequired() external {
        MockERC20 fundsAsset      = new MockERC20("FA", "FA", 18);
        MockERC20 collateralAsset = new MockERC20("CA", "CA", 18);

        uint256 amount = 1_000_000;

        loan.__setCollateralAsset(address(collateralAsset));
        loan.__setDrawableFunds(amount);
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPrincipal(amount);
        loan.__setPrincipalRequested(amount);

        // Send amount to loan
        fundsAsset.mint(address(loan), amount);

        assertEq(fundsAsset.balanceOf(borrower),      0);
        assertEq(fundsAsset.balanceOf(address(loan)), amount);
        assertEq(loan.drawableFunds(),                amount);

        vm.prank(borrower);
        loan.drawdownFunds(amount, borrower);

        assertEq(fundsAsset.balanceOf(borrower),      amount);
        assertEq(fundsAsset.balanceOf(address(loan)), 0);
        assertEq(loan.drawableFunds(),                0);
    }

    function test_drawdownFunds_pullPatternForCollateral() external {
        MockERC20 fundsAsset      = new MockERC20("FA", "FA", 18);
        MockERC20 collateralAsset = new MockERC20("CA", "CA", 18);

        uint256 fundsAssetAmount      = 1_000_000;
        uint256 collateralAssetAmount = 300_000;

        loan.__setCollateralAsset(address(collateralAsset));
        loan.__setCollateralRequired(collateralAssetAmount);
        loan.__setDrawableFunds(fundsAssetAmount);
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(1);
        loan.__setPrincipal(fundsAssetAmount);
        loan.__setPrincipalRequested(fundsAssetAmount);

        vm.startPrank(borrower);

        // Send amount to loan
        fundsAsset.mint(address(loan), fundsAssetAmount);
        collateralAsset.mint(borrower, collateralAssetAmount);

        // Fail without approval
        vm.expectRevert("ML:PC:TRANSFER_FROM_FAILED");
        loan.drawdownFunds(fundsAssetAmount, borrower);

        collateralAsset.approve(address(loan), collateralAssetAmount);

        assertEq(fundsAsset.balanceOf(borrower),           0);
        assertEq(fundsAsset.balanceOf(address(loan)),      fundsAssetAmount);
        assertEq(collateralAsset.balanceOf(borrower),      collateralAssetAmount);
        assertEq(collateralAsset.balanceOf(address(loan)), 0);
        assertEq(loan.collateral(),                        0);
        assertEq(loan.drawableFunds(),                     fundsAssetAmount);

        loan.drawdownFunds(fundsAssetAmount, borrower);

        assertEq(fundsAsset.balanceOf(borrower),           fundsAssetAmount);
        assertEq(fundsAsset.balanceOf(address(loan)),      0);
        assertEq(collateralAsset.balanceOf(borrower),      0);
        assertEq(collateralAsset.balanceOf(address(loan)), collateralAssetAmount);
        assertEq(loan.collateral(),                        collateralAssetAmount);
        assertEq(loan.drawableFunds(),                     0);
    }

    function test_drawdownFunds_pushPatternForCollateral() external {
        MockERC20 fundsAsset      = new MockERC20("FA", "FA", 18);
        MockERC20 collateralAsset = new MockERC20("CA", "CA", 18);

        uint256 fundsAssetAmount      = 1_000_000;
        uint256 collateralAssetAmount = 300_000;

        loan.__setCollateralAsset(address(collateralAsset));
        loan.__setCollateralRequired(collateralAssetAmount);
        loan.__setDrawableFunds(fundsAssetAmount);
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(1);
        loan.__setPrincipal(fundsAssetAmount);
        loan.__setPrincipalRequested(fundsAssetAmount);

        // Send amount to loan
        fundsAsset.mint(address(loan), fundsAssetAmount);

        // Fail without approval
        vm.startPrank(borrower);
        vm.expectRevert("ML:PC:TRANSFER_FROM_FAILED");
        loan.drawdownFunds(fundsAssetAmount, borrower);

        // "Transfer" funds into the loan
        collateralAsset.mint(address(loan), collateralAssetAmount);

        assertEq(fundsAsset.balanceOf(borrower),           0);
        assertEq(fundsAsset.balanceOf(address(loan)),      fundsAssetAmount);
        assertEq(collateralAsset.balanceOf(address(loan)), collateralAssetAmount);
        assertEq(loan.collateral(),                        0);
        assertEq(loan.drawableFunds(),                     fundsAssetAmount);

        loan.drawdownFunds(fundsAssetAmount, borrower);

        assertEq(fundsAsset.balanceOf(borrower),           fundsAssetAmount);
        assertEq(fundsAsset.balanceOf(address(loan)),      0);
        assertEq(collateralAsset.balanceOf(address(loan)), collateralAssetAmount);
        assertEq(loan.collateral(),                        collateralAssetAmount);
        assertEq(loan.drawableFunds(),                     0);
    }

    function test_closeLoan_pullPatternAsBorrower() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 amount = 1_000_000;

        loan.__setBorrower(address(borrower));
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPrincipal(amount);
        loan.__setPrincipalRequested(amount);
        loan.__setNextPaymentDueDate(block.timestamp + 1);

        fundsAsset.mint(address(borrower), amount);

        assertEq(fundsAsset.balanceOf(address(borrower)), amount);
        assertEq(fundsAsset.balanceOf(lender),   0);
        assertEq(loan.principal(),                        amount);

        vm.startPrank(borrower);
        vm.expectRevert("ML:CL:TRANSFER_FROM_FAILED");
        loan.closeLoan(amount);

        fundsAsset.approve(address(loan), amount);

        loan.closeLoan(amount);

        assertEq(fundsAsset.balanceOf(address(borrower)), 0);
        assertEq(fundsAsset.balanceOf(lender),   amount);
        assertEq(loan.paymentsRemaining(),                0);
        assertEq(loan.principal(),                        0);
    }

    function test_closeLoan_pushPatternAsBorrower() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 amount = 1_000_000;

        loan.__setBorrower(address(borrower));
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPrincipal(amount);
        loan.__setPrincipalRequested(amount);
        loan.__setNextPaymentDueDate(block.timestamp + 1);

        fundsAsset.mint(address(borrower), amount);

        assertEq(fundsAsset.balanceOf(address(borrower)), amount);
        assertEq(fundsAsset.balanceOf(lender),   0);
        assertEq(loan.principal(),                        amount);

        vm.startPrank(borrower);
        vm.expectRevert(ARITHMETIC_ERROR);
        loan.closeLoan(0);

        fundsAsset.transfer(address(loan), amount);

        loan.closeLoan(0);

        assertEq(fundsAsset.balanceOf(address(borrower)), 0);
        assertEq(fundsAsset.balanceOf(lender),   amount);
        assertEq(loan.paymentsRemaining(),                0);
        assertEq(loan.principal(),                        0);
    }

    function test_closeLoan_pullPatternAsNonBorrower() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 amount = 1_000_000;

        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPrincipal(amount);
        loan.__setPrincipalRequested(amount);
        loan.__setNextPaymentDueDate(block.timestamp + 1);

        fundsAsset.mint(address(user), amount);

        assertEq(fundsAsset.balanceOf(address(user)),   amount);
        assertEq(fundsAsset.balanceOf(lender), 0);
        assertEq(loan.principal(),                      amount);

        vm.startPrank(user);
        vm.expectRevert("ML:CL:TRANSFER_FROM_FAILED");
        loan.closeLoan(amount);

        fundsAsset.approve(address(loan), amount);

        loan.closeLoan(amount);

        assertEq(fundsAsset.balanceOf(address(user)),   0);
        assertEq(fundsAsset.balanceOf(lender), amount);
        assertEq(loan.paymentsRemaining(),              0);
        assertEq(loan.principal(),                      0);
    }

    function test_closeLoan_pushPatternAsNonBorrower() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 amount = 1_000_000;

        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPrincipal(amount);
        loan.__setPrincipalRequested(amount);
        loan.__setNextPaymentDueDate(block.timestamp + 1);

        fundsAsset.mint(address(user), amount);

        assertEq(fundsAsset.balanceOf(address(user)),   amount);
        assertEq(fundsAsset.balanceOf(lender), 0);
        assertEq(loan.principal(),                      amount);

        vm.startPrank(user);
        vm.expectRevert(ARITHMETIC_ERROR);
        loan.closeLoan(0);

        fundsAsset.transfer(address(loan), amount);

        loan.closeLoan(0);

        assertEq(fundsAsset.balanceOf(address(user)),   0);
        assertEq(fundsAsset.balanceOf(lender), amount);
        assertEq(loan.paymentsRemaining(),              0);
        assertEq(loan.principal(),                      0);
    }

    function test_closeLoan_pullPatternUsingDrawable() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 amount = 1_000_000;

        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPrincipal(amount);
        loan.__setPrincipalRequested(amount);
        loan.__setNextPaymentDueDate(block.timestamp + 1);

        ( uint256 principal, uint256 interest, ) = loan.getClosingPaymentBreakdown();
        uint256 totalPayment = principal + interest;

        fundsAsset.mint(address(loan), 1);
        loan.__setDrawableFunds(1);

        fundsAsset.mint(address(user), totalPayment - 1);

        vm.startPrank(user);
        fundsAsset.approve(address(loan), totalPayment - 1);

        // This should fail since it will require 1 from drawableFunds.
        vm.expectRevert("ML:CANNOT_USE_DRAWABLE");
        loan.closeLoan(totalPayment - 1);
        vm.stopPrank();

        fundsAsset.mint(address(borrower), totalPayment - 1);

        vm.startPrank(borrower);
        fundsAsset.approve(address(loan), totalPayment - 1);

        // This should succeed since it the borrower can use drawableFunds.
        loan.closeLoan(totalPayment - 1);
    }

    function test_closeLoan_pushPatternUsingDrawable() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 amount = 1_000_000;

        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPrincipal(amount);
        loan.__setPrincipalRequested(amount);
        loan.__setNextPaymentDueDate(block.timestamp + 1);

        ( uint256 principal, uint256 interest, ) = loan.getClosingPaymentBreakdown();
        uint256 totalPayment = principal + interest;

        fundsAsset.mint(address(loan), 1);
        loan.__setDrawableFunds(1);

        fundsAsset.mint(address(user), totalPayment - 1);

        vm.startPrank(user);
        fundsAsset.transfer(address(loan), totalPayment - 1);

        // This should fail since it will require 1 from drawableFunds.
        vm.expectRevert("ML:CANNOT_USE_DRAWABLE");
        loan.closeLoan(0);
        vm.stopPrank();

        // This should succeed since the borrower can use drawableFunds,
        // and there is already unaccounted amount thanks to the previous user transfer.
        vm.prank(borrower);
        loan.closeLoan(0);
    }

    function test_makePayment_pullPatternAsBorrower() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 startingPrincipal = 1_000_000;

        loan.__setEndingPrincipal(uint256(0));
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(3);
        loan.__setPrincipal(startingPrincipal);
        loan.__setPrincipalRequested(startingPrincipal);

        ( uint256 principal, uint256 interest, ) = loan.getNextPaymentBreakdown();
        uint256 totalPayment = principal + interest;

        fundsAsset.mint(address(borrower), totalPayment);

        assertEq(fundsAsset.balanceOf(address(borrower)), totalPayment);
        assertEq(fundsAsset.balanceOf(lender),   0);
        assertEq(loan.paymentsRemaining(),                3);
        assertEq(loan.principal(),                        startingPrincipal);

        vm.startPrank(borrower);
        vm.expectRevert("ML:LP:TRANSFER_FROM_FAILED");
        loan.makePayment(totalPayment);

        fundsAsset.approve(address(loan), totalPayment);

        loan.makePayment(totalPayment);

        assertEq(fundsAsset.balanceOf(address(borrower)), 0);
        assertEq(fundsAsset.balanceOf(lender),   totalPayment);
        assertEq(loan.paymentsRemaining(),                2);
        assertEq(loan.principal(),                        startingPrincipal - principal);
    }

    function test_makePayment_pushPatternAsBorrower() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 startingPrincipal = 1_000_000;

        loan.__setEndingPrincipal(uint256(0));
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(3);
        loan.__setPrincipal(startingPrincipal);
        loan.__setPrincipalRequested(startingPrincipal);

        ( uint256 principal, uint256 interest, ) = loan.getNextPaymentBreakdown();
        uint256 totalPayment = principal + interest;

        fundsAsset.mint(address(borrower), totalPayment);

        assertEq(fundsAsset.balanceOf(address(borrower)), totalPayment);
        assertEq(fundsAsset.balanceOf(lender),   0);
        assertEq(loan.paymentsRemaining(),                3);
        assertEq(loan.principal(),                        startingPrincipal);

        vm.startPrank(borrower);
        vm.expectRevert(ARITHMETIC_ERROR);
        loan.makePayment(0);

        fundsAsset.transfer(address(loan), totalPayment);

        loan.makePayment(0);

        assertEq(fundsAsset.balanceOf(address(borrower)), 0);
        assertEq(fundsAsset.balanceOf(lender),   totalPayment);
        assertEq(loan.paymentsRemaining(),                2);
        assertEq(loan.principal(),                        startingPrincipal - principal);
    }

    function test_makePayment_pullPatternAsNonBorrower() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 startingPrincipal = 1_000_000;

        loan.__setEndingPrincipal(uint256(0));
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(3);
        loan.__setPrincipal(startingPrincipal);
        loan.__setPrincipalRequested(startingPrincipal);

        ( uint256 principal, uint256 interest, ) = loan.getNextPaymentBreakdown();
        uint256 totalPayment = principal + interest;

        fundsAsset.mint(address(user), totalPayment);

        assertEq(fundsAsset.balanceOf(address(user)),   totalPayment);
        assertEq(fundsAsset.balanceOf(lender), 0);
        assertEq(loan.paymentsRemaining(),              3);
        assertEq(loan.principal(),                      startingPrincipal);

        vm.startPrank(user);
        vm.expectRevert("ML:LP:TRANSFER_FROM_FAILED");
        loan.makePayment(totalPayment);

        fundsAsset.approve(address(loan), totalPayment);

        loan.makePayment(totalPayment);

        assertEq(fundsAsset.balanceOf(address(user)),   0);
        assertEq(fundsAsset.balanceOf(lender), totalPayment);
        assertEq(loan.paymentsRemaining(),              2);
        assertEq(loan.principal(),                      startingPrincipal - principal);
    }

    function test_makePayment_pushPatternAsNonBorrower() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 startingPrincipal = 1_000_000;

        loan.__setEndingPrincipal(uint256(0));
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(3);
        loan.__setPrincipal(startingPrincipal);
        loan.__setPrincipalRequested(startingPrincipal);

        ( uint256 principal, uint256 interest, ) = loan.getNextPaymentBreakdown();
        uint256 totalPayment = principal + interest;

        fundsAsset.mint(address(user), totalPayment);

        assertEq(fundsAsset.balanceOf(address(user)),   totalPayment);
        assertEq(fundsAsset.balanceOf(lender), 0);
        assertEq(loan.paymentsRemaining(),              3);
        assertEq(loan.principal(),                      startingPrincipal);

        vm.startPrank(user);
        vm.expectRevert(ARITHMETIC_ERROR);
        loan.makePayment(0);

        fundsAsset.transfer(address(loan), totalPayment);

        loan.makePayment(0);

        assertEq(fundsAsset.balanceOf(address(user)),   0);
        assertEq(fundsAsset.balanceOf(lender), totalPayment);
        assertEq(loan.paymentsRemaining(),              2);
        assertEq(loan.principal(),                      startingPrincipal - principal);
    }

    function test_makePayment_pullPatternUsingDrawable() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 startingPrincipal = 1_000_000;

        loan.__setEndingPrincipal(uint256(0));
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(3);
        loan.__setPrincipal(startingPrincipal);
        loan.__setPrincipalRequested(startingPrincipal);

        ( uint256 principal, uint256 interest, ) = loan.getNextPaymentBreakdown();
        uint256 totalPayment = principal + interest;

        fundsAsset.mint(address(loan), 1);
        loan.__setDrawableFunds(1);

        fundsAsset.mint(address(user), totalPayment - 1);

        vm.startPrank(user);
        fundsAsset.approve(address(loan), totalPayment - 1);

        // This should fail since it will require 1 from drawableFunds.
        vm.expectRevert("ML:CANNOT_USE_DRAWABLE");
        loan.makePayment(totalPayment - 1);
        vm.stopPrank();

        fundsAsset.mint(address(borrower), totalPayment - 1);

        vm.startPrank(borrower);
        fundsAsset.approve(address(loan), totalPayment - 1);

        // This should succeed since it the borrower can use drawableFunds.
        loan.makePayment(totalPayment - 1);
    }

    function test_makePayment_pushPatternUsingDrawable() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        uint256 startingPrincipal = 1_000_000;

        loan.__setEndingPrincipal(uint256(0));
        loan.__setFundsAsset(address(fundsAsset));
        loan.__setPaymentsRemaining(3);
        loan.__setPrincipal(startingPrincipal);
        loan.__setPrincipalRequested(startingPrincipal);

        ( uint256 principal, uint256 interest, ) = loan.getNextPaymentBreakdown();
        uint256 totalPayment = principal + interest;

        fundsAsset.mint(address(loan), 1);
        loan.__setDrawableFunds(1);

        fundsAsset.mint(address(user), totalPayment - 1);

        vm.startPrank(user);
        fundsAsset.transfer(address(loan), totalPayment - 1);

        // This should fail since it will require 1 from drawableFunds.
        vm.expectRevert("ML:CANNOT_USE_DRAWABLE");
        loan.makePayment(0);
        vm.stopPrank();

        // This should succeed since the borrower can use drawableFunds,
        // and there is already unaccounted amount thanks to the previous user transfer.
        vm.prank(borrower);
        loan.makePayment(0);
    }

    function test_postCollateral_pullPattern() external {
        MockERC20 collateralAsset = new MockERC20("CA", "CA", 18);

        loan.__setCollateralAsset(address(collateralAsset));

        uint256 amount = 1_000_000;

        collateralAsset.mint(borrower, amount);

        vm.startPrank(borrower);
        vm.expectRevert("ML:PC:TRANSFER_FROM_FAILED");
        loan.postCollateral(amount);

        collateralAsset.approve(address(loan), amount);

        assertEq(collateralAsset.balanceOf(borrower),      amount);
        assertEq(collateralAsset.balanceOf(address(loan)), 0);
        assertEq(loan.collateral(),                        0);

        loan.postCollateral(amount);

        assertEq(collateralAsset.balanceOf(borrower),      0);
        assertEq(collateralAsset.balanceOf(address(loan)), amount);
        assertEq(loan.collateral(),                        amount);
    }

    function test_postCollateral_pushPattern() external {
        MockERC20 collateralAsset = new MockERC20("CA", "CA", 18);

        loan.__setCollateralAsset(address(collateralAsset));

        uint256 amount = 1_000_000;

        collateralAsset.mint(address(loan), amount);

        assertEq(collateralAsset.balanceOf(address(loan)), amount);
        assertEq(loan.collateral(),                        0);

        loan.postCollateral(0);

        assertEq(collateralAsset.balanceOf(address(loan)), amount);
        assertEq(loan.collateral(),                        amount);
    }

    function test_returnFunds_pullPattern() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        loan.__setFundsAsset(address(fundsAsset));

        uint256 amount = 1_000_000;

        fundsAsset.mint(borrower, amount);

        vm.startPrank(borrower);
        vm.expectRevert("ML:RF:TRANSFER_FROM_FAILED");
        loan.returnFunds(amount);

        fundsAsset.approve(address(loan), amount);

        assertEq(fundsAsset.balanceOf(borrower),      amount);
        assertEq(fundsAsset.balanceOf(address(loan)), 0);
        assertEq(loan.drawableFunds(),                0);

        loan.returnFunds(amount);

        assertEq(fundsAsset.balanceOf(borrower),      0);
        assertEq(fundsAsset.balanceOf(address(loan)), amount);
        assertEq(loan.drawableFunds(),                amount);
    }

    function test_returnFunds_pushPattern() external {
        MockERC20 fundsAsset = new MockERC20("FA", "FA", 18);

        loan.__setFundsAsset(address(fundsAsset));

        uint256 amount = 1_000_000;

        fundsAsset.mint(address(loan), amount);

        assertEq(fundsAsset.balanceOf(address(loan)), amount);
        assertEq(loan.drawableFunds(),                0);

        loan.returnFunds(0);  // No try catch since returnFunds can pass with zero amount

        assertEq(fundsAsset.balanceOf(address(loan)), amount);
        assertEq(loan.drawableFunds(),                amount);
    }

    /**************************************************************************************************************************************/
    /*** Pause Tests                                                                                                                    ***/
    /**************************************************************************************************************************************/

    function test_migrate_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.migrate(address(0), bytes(""));
    }

    function test_setImplementation_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.setImplementation(address(0));
    }

    function test_acceptBorrower_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.acceptBorrower();
    }

    function test_acceptLender_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.acceptLender();
    }

    function test_acceptNewTerms_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.acceptNewTerms(address(0), 0, new bytes[](0));
    }

    function test_closeLoan_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.closeLoan(uint256(0));
    }

    function test_drawdownFunds_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.drawdownFunds(0, address(0));
    }

    function test_fundLoan_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.fundLoan();
    }

    function test_impairLoan_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.impairLoan();
    }

    function test_makePayment_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.makePayment(0);
    }

    function test_postCollateral_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.postCollateral(0);
    }

    function test_proposeNewTerms_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.proposeNewTerms(address(0), 0, new bytes[](0));
    }

    function test_rejectNewTerms_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.rejectNewTerms(address(0), 0, new bytes[](0));
    }

    function test_removeCollateral_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.removeCollateral(0, address(0));
    }

    function test_removeLoanImpairment_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.removeLoanImpairment();
    }

    function test_repossess_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.repossess(address(0));
    }

    function test_returnFunds_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.returnFunds(0);
    }

    function test_setPendingBorrower_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.setPendingBorrower(address(0));
    }

    function test_setPendingLender_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.setPendingLender(address(0));
    }

    function test_skim_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.skim(address(0), address(0));
    }

    function test_upgrade_failWhenPaused() external {
        globals.__setFunctionPaused(true);

        vm.expectRevert("L:PAUSED");
        loan.upgrade(0, "");
    }

}

contract LopoLoanRoleTests is TestUtils {

    address borrower = address(new Address());
    address governor = address(new Address());
    address lender;

    ConstructableLopoLoan loan;
    MockERC20              token;
    MockFactory            factory;
    MockFeeManager         feeManager;
    MockGlobals            globals;

    function setUp() public {
        feeManager = new MockFeeManager();
        globals    = new MockGlobals(governor);
        lender     = address(new MockLoanManager());
        token      = new MockERC20("Token", "T", 0);

        factory = new MockFactory(address(globals));

        MockLoanManager(lender).__setFundsAsset(address(token));

        address[2] memory assets      = [address(token), address(token)];
        uint256[3] memory termDetails = [uint256(10 days), uint256(365 days / 6), uint256(6)];
        uint256[3] memory amounts     = [uint256(300_000), uint256(1_000_000), uint256(0)];
        uint256[4] memory rates       = [uint256(0.12e18), uint256(0), uint256(0), uint256(0)];
        uint256[2] memory fees        = [uint256(0), uint256(0)];

        globals.setValidBorrower(borrower,              true);
        globals.setValidCollateralAsset(address(token), true);
        globals.setValidPoolAsset(address(token),       true);

        globals.__setIsInstanceOf(true);

        vm.prank(address(factory));
        loan = new ConstructableLopoLoan(address(factory), borrower, lender, address(feeManager), assets, termDetails, amounts, rates, fees);
    }

    function test_transferBorrowerRole_failIfInvalidBorrower() public {
        address newBorrower = address(new Address());

        vm.prank(address(borrower));
        vm.expectRevert("ML:SPB:INVALID_BORROWER");
        loan.setPendingBorrower(address(newBorrower));
    }

    function test_transferBorrowerRole() public {
        address newBorrower = address(new Address());

        // Set addresse used in this test case as valid borrowers.
        globals.setValidBorrower(address(newBorrower), true);
        globals.setValidBorrower(address(1),           true);

        assertEq(loan.pendingBorrower(), address(0));
        assertEq(loan.borrower(),        borrower);

        // Only borrower can call setPendingBorrower
        vm.prank(newBorrower);
        vm.expectRevert("ML:NOT_BORROWER");
        loan.setPendingBorrower(newBorrower);

        vm.prank(borrower);
        loan.setPendingBorrower(newBorrower);

        assertEq(loan.pendingBorrower(), newBorrower);

        // Pending borrower can't call setPendingBorrower
        vm.prank(newBorrower);
        vm.expectRevert("ML:NOT_BORROWER");
        loan.setPendingBorrower(address(1));

        vm.prank(borrower);
        loan.setPendingBorrower(address(1));

        assertEq(loan.pendingBorrower(), address(1));

        // Can be reset if mistake is made
        vm.prank(borrower);
        loan.setPendingBorrower(newBorrower);

        assertEq(loan.pendingBorrower(), newBorrower);
        assertEq(loan.borrower(),        borrower);

        // Pending borrower is the only one who can call acceptBorrower
        vm.prank(borrower);
        vm.expectRevert("ML:AB:NOT_PENDING_BORROWER");
        loan.acceptBorrower();

        vm.prank(newBorrower);
        loan.acceptBorrower();

        // Pending borrower is set to zero
        assertEq(loan.pendingBorrower(), address(0));
        assertEq(loan.borrower(),        newBorrower);
    }

    function test_transferLenderRole() public {
        // Fund the loan to set the lender
        token.mint(address(loan), 1_000_000);

        vm.prank(lender);
        loan.fundLoan();

        address newLender = address(new Address());

        assertEq(loan.pendingLender(), address(0));
        assertEq(loan.lender(),        lender);

        // Only lender can call setPendingLender
        vm.prank(newLender);
        vm.expectRevert("ML:NOT_LENDER");
        loan.setPendingLender(newLender);

        vm.prank(lender);
        loan.setPendingLender(newLender);

        assertEq(loan.pendingLender(), newLender);

        // Pending lender can't call setPendingLender
        vm.prank(newLender);
        vm.expectRevert("ML:NOT_LENDER");
        loan.setPendingLender(address(1));

        vm.prank(lender);
        loan.setPendingLender(address(1));

        assertEq(loan.pendingLender(), address(1));

        // Can be reset if mistake is made
        vm.prank(lender);
        loan.setPendingLender(newLender);

        assertEq(loan.pendingLender(), newLender);
        assertEq(loan.lender(),        lender);

        // Pending lender is the only one who can call acceptLender
        vm.prank(lender);
        vm.expectRevert("ML:AL:NOT_PENDING_LENDER");
        loan.acceptLender();

        vm.prank(newLender);
        loan.acceptLender();

        // Pending lender is set to zero
        assertEq(loan.pendingLender(), address(0));
        assertEq(loan.lender(),        newLender);
    }

}

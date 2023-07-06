// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { Address, TestUtils } from "contract-test-utils/test.sol";
import { MockERC20 }          from "../../erc20/test/mocks/MockERC20.sol";

import { ConstructableLopoLoan } from "./harnesses/LopoLoanHarnesses.sol";

import { EmptyContract, MockFactory, MockFeeManager, MockGlobals, MockLoanManager } from "./mocks/Mocks.sol";

// TODO: Add fees
contract LopoLoanScenariosTests is TestUtils {

    MockERC20       internal token;
    MockFactory     internal factory;
    MockFeeManager  internal feeManager;
    MockGlobals     internal globals;
    MockLoanManager internal lender;

    address internal borrower = address(new Address());
    address internal governor = address(new Address());

    function setUp() external {
        feeManager = new MockFeeManager();
        globals    = new MockGlobals(governor);
        lender     = new MockLoanManager();
        token      = new MockERC20("Test", "TST", 0);

        factory = new MockFactory(address(globals));

        lender.__setFundsAsset(address(token));

        globals.setValidBorrower(borrower,              true);
        globals.setValidCollateralAsset(address(token), true);
        globals.setValidPoolAsset(address(token),       true);

        globals.__setIsInstanceOf(true);
    }

    function test_scenario_fullyAmortized() external {
        token.mint(borrower,        1_000_000);
        token.mint(address(lender), 1_000_000);

        address[2] memory assets      = [address(token), address(token)];
        uint256[3] memory termDetails = [uint256(10 days), uint256(365 days / 6), uint256(6)];
        uint256[3] memory amounts     = [uint256(300_000), uint256(1_000_000), uint256(0)];
        uint256[4] memory rates       = [uint256(0.12e6), uint256(0), uint256(0), uint256(0)];
        uint256[2] memory fees        = [uint256(0), uint256(0)];

        vm.prank(address(factory));
        ConstructableLopoLoan loan = new ConstructableLopoLoan(
            address(factory),
            borrower,
            address(lender),
            address(feeManager),
            assets,
            termDetails,
            amounts,
            rates,
            fees
        );

        // Fund via a 1M transfer
        vm.startPrank(address(lender));
        token.transfer(address(loan), 1_000_000);
        loan.fundLoan();
        vm.stopPrank();

        assertEq(loan.drawableFunds(), 1_000_000, "Different drawable funds");

        vm.startPrank(borrower);
        token.transfer(address(loan), 150_000);
        token.approve(address(loan), 150_000);
        loan.postCollateral(150_000);
        loan.drawdownFunds(1_000_000, borrower);

        assertEq(loan.drawableFunds(), 0, "Different drawable funds");

        // Check details for upcoming payment #1
        ( uint256 principalPortion, uint256 interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         158_525,   "Different principal");
        assertEq(interestPortion,          20_000,    "Different interest");
        assertEq(loan.paymentsRemaining(), 6,         "Different payments remaining");
        assertEq(loan.principal(),         1_000_000, "Different payments remaining");

        // Warp to 1 second before payment #1 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #1
        token.transfer(address(loan), 78_526);
        token.approve(address(loan), 100_000);
        loan.makePayment(100_000);

        // Check details for upcoming payment #2
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         161_696, "Different principal");
        assertEq(interestPortion,          16_829,  "Different interest");
        assertEq(loan.paymentsRemaining(), 5,       "Different payments remaining");
        assertEq(loan.principal(),         841_475, "Different payments remaining");

        // Warp to 1 second before payment #2 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #2
        token.transfer(address(loan), 178_526);
        loan.makePayment(0);

        // Check details for upcoming payment #3
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         164_930, "Different principal");
        assertEq(interestPortion,          13_595,  "Different interest");
        assertEq(loan.paymentsRemaining(), 4,       "Different payments remaining");
        assertEq(loan.principal(),         679_779, "Different payments remaining");

        // Warp to 1 second before payment #3 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #3
        token.transfer(address(loan), 178_525);
        loan.makePayment(0);

        // Remove some collateral
        vm.expectRevert("ML:RC:INSUFFICIENT_COLLATERAL");
        loan.removeCollateral(145_546, borrower);
        loan.removeCollateral(145_545, borrower);

        assertEq(loan.collateral(), 154_455, "Different collateral");

        // Check details for upcoming payment #4
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         168_230, "Different principal");
        assertEq(interestPortion,          10_296,  "Different interest");
        assertEq(loan.paymentsRemaining(), 3,       "Different payments remaining");
        assertEq(loan.principal(),         514_849, "Different payments remaining");

        // Warp to 1 second before payment #4 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #4
        token.transfer(address(loan), 178_525);
        loan.makePayment(0);

        // Return some funds and remove some collateral
        token.transfer(address(loan), 75_000);
        token.approve(address(loan), 75_000);
        loan.returnFunds(75_000);

        assertEq(loan.drawableFunds(), 150_001, "Different drawable funds");

        vm.expectRevert("ML:RC:INSUFFICIENT_COLLATERAL");
        loan.removeCollateral(95_470, borrower);
        loan.removeCollateral(95_469, borrower);

        assertEq(loan.collateral(), 58_986, "Different collateral");

        // Check details for upcoming payment #5
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         171_593, "Different principal");
        assertEq(interestPortion,          6_932,   "Different interest");
        assertEq(loan.paymentsRemaining(), 2,       "Different payments remaining");
        assertEq(loan.principal(),         346_619, "Different payments remaining");

        // Warp to 1 second before payment #5 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #5
        token.transfer(address(loan), 178_525);
        loan.makePayment(0);

        // Check details for upcoming payment #6
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         175_026, "Different principal");
        assertEq(interestPortion,          3_500,   "Different interest");
        assertEq(loan.paymentsRemaining(), 1,       "Different payments remaining");
        assertEq(loan.principal(),         175_026, "Different payments remaining");

        // Warp to 1 second before payment #6 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #6
        token.transfer(address(loan), 178_525);
        loan.makePayment(0);

        // Check details for upcoming payment which should not be necessary
        assertEq(loan.paymentsRemaining(), 0, "Different payments remaining");
        assertEq(loan.principal(),         0, "Different payments remaining");

        // Remove rest of available funds and collateral
        loan.drawdownFunds(150_000, borrower);

        vm.expectRevert(ARITHMETIC_ERROR);
        loan.removeCollateral(58_987, borrower);
        loan.removeCollateral(58_986, borrower);

        assertEq(loan.collateral(), 0, "Different collateral");
    }

    function test_scenario_interestOnly() external {
        token.mint(borrower,        1_000_000);
        token.mint(address(lender), 1_000_000);

        address[2] memory assets      = [address(token), address(token)];
        uint256[3] memory termDetails = [uint256(10 days), uint256(365 days / 6), uint256(6)];
        uint256[3] memory amounts     = [uint256(300_000), uint256(1_000_000), uint256(1_000_000)];
        uint256[4] memory rates       = [uint256(0.12e6),  uint256(0), uint256(0), uint256(0)];
        uint256[2] memory fees        = [uint256(0), uint256(0)];

        vm.prank(address(factory));
        ConstructableLopoLoan loan = new ConstructableLopoLoan(address(factory), borrower, address(lender), address(feeManager), assets, termDetails, amounts, rates, fees);

        // Fund via a 1M transfer
        vm.startPrank(address(lender));
        token.transfer(address(loan), 1_000_000);
        loan.fundLoan();
        vm.stopPrank();

        assertEq(loan.drawableFunds(), 1_000_000, "Different drawable funds");

        vm.startPrank(borrower);
        token.transfer(address(loan), 150_000);
        token.approve(address(loan), 150_000);
        loan.postCollateral(150_000);
        loan.drawdownFunds(1_000_000, borrower);

        assertEq(loan.drawableFunds(), 0, "Different drawable funds");

        // Check details for upcoming payment #1
        ( uint256 principalPortion, uint256 interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         0,         "Different principal");
        assertEq(interestPortion,          20_000,    "Different interest");
        assertEq(loan.paymentsRemaining(), 6,         "Different payments remaining");
        assertEq(loan.principal(),         1_000_000, "Different payments remaining");

        // Warp to 1 second before payment #1 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #1
        token.transfer(address(loan), 10_000);
        token.approve(address(loan), 10_000);
        loan.makePayment(10_000);

        // Check details for upcoming payment #2
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         0,         "Different principal");
        assertEq(interestPortion,          20_000,    "Different interest");
        assertEq(loan.paymentsRemaining(), 5,         "Different payments remaining");
        assertEq(loan.principal(),         1_000_000, "Different payments remaining");

        // Warp to 1 second before payment #2 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #2
        token.transfer(address(loan), 20_000);
        loan.makePayment(0);

        // Check details for upcoming payment #3
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         0,         "Different principal");
        assertEq(interestPortion,          20_000,    "Different interest");
        assertEq(loan.paymentsRemaining(), 4,         "Different payments remaining");
        assertEq(loan.principal(),         1_000_000, "Different payments remaining");

        // Warp to 1 second before payment #3 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #3
        token.transfer(address(loan), 20_000);
        loan.makePayment(0);

        // Check details for upcoming payment #4
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         0,         "Different principal");
        assertEq(interestPortion,          20_000,    "Different interest");
        assertEq(loan.paymentsRemaining(), 3,         "Different payments remaining");
        assertEq(loan.principal(),         1_000_000, "Different payments remaining");

        // Warp to 1 second before payment #4 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #4
        token.transfer(address(loan), 20_000);
        loan.makePayment(0);

        // Return some funds and remove some collateral
        token.transfer(address(loan), 250_000);
        token.approve(address(loan), 250_000);
        loan.returnFunds(250_000);

        assertEq(loan.drawableFunds(), 500_000, "Different drawable funds");

        loan.removeCollateral(150_000, borrower);

        assertEq(loan.collateral(), 150_000, "Different collateral");

        // Check details for upcoming payment #5
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         0,         "Different principal");
        assertEq(interestPortion,          20_000,    "Different interest");
        assertEq(loan.paymentsRemaining(), 2,         "Different payments remaining");
        assertEq(loan.principal(),         1_000_000, "Different payments remaining");

        // Warp to 1 second before payment #5 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #5
        token.transfer(address(loan), 20_000);
        loan.makePayment(0);

        // Check details for upcoming payment #6
        ( principalPortion, interestPortion, ) = loan.getNextPaymentBreakdown();

        assertEq(principalPortion,         1_000_000, "Different principal");
        assertEq(interestPortion,          20_000,    "Different interest");
        assertEq(loan.paymentsRemaining(), 1,         "Different payments remaining");
        assertEq(loan.principal(),         1_000_000, "Different payments remaining");

        // Warp to 1 second before payment #6 becomes late
        vm.warp(loan.nextPaymentDueDate() - 1);

        // Make payment #6
        token.transfer(address(loan), 1_020_000);
        loan.makePayment(0);

        // Check details for upcoming payment which should not be necessary
        assertEq(loan.paymentsRemaining(), 0, "Different payments remaining");
        assertEq(loan.principal(),         0, "Different payments remaining");

        // Remove rest of available funds and collateral
        loan.drawdownFunds(150_000, borrower);
        loan.removeCollateral(150_000, borrower);

        assertEq(loan.collateral(), 0, "Different collateral");
    }

    function test_scenario_lateLoanRefinanceInterest() external {
        uint256 start = block.timestamp;

        token.mint(address(lender), 1_000_000);

        address[2] memory assets      = [address(token), address(token)];
        uint256[3] memory termDetails = [uint256(12 hours), uint256(30 days), uint256(3)];
        uint256[3] memory amounts     = [uint256(0), uint256(1_000_000), uint256(1_000_000)];
        uint256[4] memory rates       = [uint256(0.1e6), uint256(0), uint256(0), uint256(0.1e6)];
        uint256[2] memory fees        = [uint256(0), uint256(0)];

        vm.prank(address(factory));
        ConstructableLopoLoan loan = new ConstructableLopoLoan(address(factory), borrower, address(lender), address(feeManager), assets, termDetails, amounts, rates, fees);

        // Fund via a 1M transfer
        vm.startPrank(address(lender));
        token.transfer(address(loan), 1_000_000);
        loan.fundLoan();
        vm.stopPrank();

        assertEq(loan.drawableFunds(), 1_000_000);

        // 4 days late on payment #1
        vm.warp(start + 34 days);

        address mockRefinancer = address(new EmptyContract());

        uint256 deadline = start + 45 days;

        bytes[] memory emptyCalls = new bytes[](1);

        emptyCalls[0] = "";

        // Borrower proposes new terms
        vm.prank(borrower);
        loan.proposeNewTerms(mockRefinancer, deadline, emptyCalls);  // No calls required

        assertEq(loan.refinanceInterest(), 0);

        // Lender accepts new terms
        vm.warp(start + 35 days);
        vm.prank(address(lender));
        loan.acceptNewTerms(mockRefinancer, deadline, emptyCalls);

        uint256 normalInterest = 30 days * uint256(1_000_000) * 0.1e18 / 1e18 / 365 days;  // at 10% interest annualized
        uint256 lateInterest   =  5 days * uint256(1_000_000) * 0.2e18 / 1e18 / 365 days;  // at 20% interest annualized

        assertEq(normalInterest,           8_219);
        assertEq(lateInterest,             2_739);
        assertEq(loan.refinanceInterest(), 10_958);
        assertEq(loan.refinanceInterest(), normalInterest + lateInterest);
    }

}

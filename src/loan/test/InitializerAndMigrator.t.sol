// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { Address, TestUtils } from "contract-test-utils/test.sol";
import { MockERC20 }          from "../../erc20/test/mocks/MockERC20.sol";

import { LopoLoan }            from "../LopoLoan.sol";
import { LopoLoanFactory}      from "../LopoLoanFactory.sol";
import { LopoLoanInitializer } from "../LopoLoanInitializer.sol";
import { LopoLoanMigrator }  from "../LopoLoanMigrator.sol";

import { MockGlobals, MockFeeManager, MockLoanManager, MockLoanManagerFactory } from "./mocks/Mocks.sol";

contract LopoLoanInitializerAndMigratorTests is TestUtils {

    address internal governor      = address(new Address());
    address internal securityAdmin = address(new Address());
    address internal implementation4;
    address internal implementation5;
    address internal initializer;

    LopoLoan              loan;
    LopoLoanFactory       factory;
    LopoLoanMigrator    migrator;
    MockERC20              asset;
    MockFeeManager         feeManager;
    MockGlobals            globals;
    MockLoanManager        lender;
    MockLoanManagerFactory loanManagerFactory;

    function setUp() external {
        asset           = new MockERC20("Asset", "ASSET", 18);
        globals         = new MockGlobals(governor);
        feeManager      = new MockFeeManager();
        implementation4 = address(new LopoLoan());
        implementation5 = address(new LopoLoan());
        initializer     = address(new LopoLoanInitializer());
        lender          = new MockLoanManager();
        migrator        = new LopoLoanMigrator();

        factory            = new LopoLoanFactory(address(globals));
        loanManagerFactory = MockLoanManagerFactory(lender.factory());

        lender.__setFundsAsset(address(asset));

        globals.setValidBorrower(address(1),            true);
        globals.setValidCollateralAsset(address(asset), true);
        globals.setValidPoolAsset(address(asset),       true);
        globals.__setIsInstanceOf(true);
        globals.__setSecurityAdmin(securityAdmin);

        vm.startPrank(governor);
        factory.registerImplementation(1, implementation4, initializer);
        factory.setDefaultVersion(1);
        factory.registerImplementation(2, implementation5, initializer);
        factory.enableUpgradePath(1, 2, address(migrator));
        vm.stopPrank();

        address[2] memory assets      = [address(asset),    address(asset)];
        uint256[3] memory termDetails = [uint256(12 hours), uint256(365 days),    uint256(1)];
        uint256[3] memory amounts     = [uint256(0),        uint256(1_000_000e6), uint256(1_000_000e6)];
        uint256[4] memory rates       = [uint256(0.1e18),   uint256(0.02e18),     uint256(0.03e18), uint256(0.04e18)];
        uint256[2] memory fees        = [uint256(0),        uint256(0)];

        bytes memory arguments = LopoLoanInitializer(initializer).encodeArguments(
            address(1),
            address(lender),
            address(feeManager),
            assets,
            termDetails,
            amounts,
            rates,
            fees
        );

        loan = LopoLoan(factory.createInstance(arguments, "SALT"));

        asset.mint(address(loan), 1_000_000e6);

        vm.prank(address(lender));
        loan.fundLoan();
    }

    function test_initializer_setters() external {
        // Failure modes are tested on the LopoLoanFactory.t.sol, so this is just test that state is properly set.

        // Check addresses
        assertEq(loan.borrower(),        address(1));
        assertEq(loan.collateralAsset(), address(asset));
        assertEq(loan.factory(),         address(factory));
        assertEq(loan.feeManager(),      address(feeManager));
        assertEq(loan.fundsAsset(),      address(asset));
        assertEq(loan.lender(),          address(lender));
        assertEq(loan.pendingBorrower(), address(0));
        assertEq(loan.pendingLender(),   address(0));

        // Check amounts
        assertEq(loan.collateral(),         0);
        assertEq(loan.collateralRequired(), 0);
        assertEq(loan.endingPrincipal(),    1_000_000e6);
        assertEq(loan.principal(),          1_000_000e6);
        assertEq(loan.principalRequested(), 1_000_000e6);

        // Check term details
        assertEq(loan.gracePeriod(),       12 hours);
        assertEq(loan.paymentInterval(),   365 days);
        assertEq(loan.paymentsRemaining(), 1);

        // Check rates
        assertEq(loan.interestRate(),            0.1e18);
        assertEq(loan.closingRate(),             0.02e18);
        assertEq(loan.lateFeeRate(),             0.03e18);
        assertEq(loan.lateInterestPremiumRate(), 0.04e18);

        assertEq(loan.HUNDRED_PERCENT(), 1e6);
    }

    function test_migration_ratesChange() external {
        assertEq(loan.interestRate(),            0.1e18);
        assertEq(loan.closingRate(),             0.02e18);
        assertEq(loan.lateFeeRate(),             0.03e18);
        assertEq(loan.lateInterestPremiumRate(), 0.04e18);

        // Upgrade
        vm.prank(securityAdmin);
        loan.upgrade(2, new bytes(0));

        assertEq(loan.interestRate(),            0.1e6);
        assertEq(loan.closingRate(),             0.02e6);
        assertEq(loan.lateFeeRate(),             0.03e6);
        assertEq(loan.lateInterestPremiumRate(), 0.04e6);
    }

}

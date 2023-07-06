// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { Address, TestUtils } from "contract-test-utils/test.sol";
import { MockERC20 }          from "../../erc20/test/mocks/MockERC20.sol";

import { LopoLoan }            from "../LopoLoan.sol";
import { LopoLoanFactory }     from "../LopoLoanFactory.sol";
import { LopoLoanInitializer } from "../LopoLoanInitializer.sol";
import { LopoLoanFeeManager }  from "../LopoLoanFeeManager.sol";

import { MockGlobals, MockLoanManager, MockPoolManager } from "./mocks/Mocks.sol";

contract FeeManagerBase is TestUtils {

    address internal BORROWER = address(new Address());
    address internal GOVERNOR = address(new Address());
    address internal PD       = address(new Address());
    address internal TREASURY = address(new Address());

    address internal implementation;
    address internal initializer;

    LopoLoanFactory    internal factory;
    LopoLoanFeeManager internal feeManager;
    MockERC20           internal collateralAsset;
    MockERC20           internal fundsAsset;
    MockGlobals         internal globals;
    MockLoanManager     internal lender;
    MockPoolManager     internal poolManager;

    address[2] internal defaultAssets;
    uint256[3] internal defaultTermDetails;
    uint256[3] internal defaultAmounts;
    uint256[4] internal defaultRates;
    uint256[2] internal defaultFees;

    function setUp() public virtual {
        implementation = address(new LopoLoan());
        initializer    = address(new LopoLoanInitializer());

        collateralAsset = new MockERC20("MockCollateral", "MC", 18);
        fundsAsset      = new MockERC20("MockAsset", "MA", 18);
        poolManager     = new MockPoolManager(PD);

        globals = new MockGlobals(GOVERNOR);
        lender  = new MockLoanManager();

        lender.__setFundsAsset(address(fundsAsset));

        factory    = new LopoLoanFactory(address(globals));
        feeManager = new LopoLoanFeeManager(address(globals));

        lender.__setPoolManager(address(poolManager));

        vm.startPrank(GOVERNOR);
        factory.registerImplementation(1, implementation, initializer);
        factory.setDefaultVersion(1);

        globals.setLopoTreasury(TREASURY);
        globals.__setIsInstanceOf(true);
        globals.setValidBorrower(BORROWER,                        true);
        globals.setValidCollateralAsset(address(collateralAsset), true);
        globals.setValidPoolAsset(address(fundsAsset),            true);
        vm.stopPrank();

        defaultAssets      = [address(collateralAsset), address(fundsAsset)];
        defaultTermDetails = [uint256(10 days), uint256(365 days / 12), uint256(3)];
        defaultAmounts     = [uint256(0), uint256(1_000_000e18), uint256(1_000_000e18)];
        defaultRates       = [uint256(0.12e6), uint256(0.02e6), uint256(0), uint256(0.02e6)];
        defaultFees        = [uint256(25_000e18), uint256(500e18)];
    }

    function _createLoan(
        address borrower_,
        address lender_,
        address feeManager_,
        address[2] memory assets_,
        uint256[3] memory termDetails_,
        uint256[3] memory amounts_,
        uint256[4] memory rates_,
        uint256[2] memory fees_,
        bytes32 salt_
    )
        internal returns (address loan_)
    {
        loan_ = factory.createInstance({
            arguments_: LopoLoanInitializer(initializer).encodeArguments(
                borrower_,
                lender_,
                feeManager_,
                assets_,
                termDetails_,
                amounts_,
                rates_,
                fees_
            ),
            salt_: keccak256(abi.encodePacked(salt_))
        });
    }

    function _fundLoan(address loan_, address lender_, uint256 amount_) internal {
        fundsAsset.mint(address(loan_), amount_);

        vm.prank(lender_);
        LopoLoan(loan_).fundLoan();
    }

    function _drawdownLoan(address loan_, address borrower_) internal {
        uint256 drawableFunds = LopoLoan(loan_).drawableFunds();
        vm.prank(BORROWER);
        LopoLoan(loan_).drawdownFunds(drawableFunds, borrower_);
    }

}

contract PayClosingFeesTests is FeeManagerBase {

    LopoLoan loan;

    function setUp() public override {
        super.setUp();

        loan = LopoLoan(
            _createLoan(BORROWER, address(lender), address(feeManager), defaultAssets, defaultTermDetails, defaultAmounts, defaultRates, defaultFees, "salt")
        );

        globals.setPlatformServiceFeeRate(address(poolManager), 3000);  // 0.3%

        _fundLoan(address(loan), address(lender), loan.principalRequested());

        _drawdownLoan(address(loan), BORROWER);
    }

    // TODO: These tests cannot be done due to lack of Mocked Loan
    // function test_payClosingServiceFees_insufficientFunds_poolDelegate() external {}
    // function test_payClosingServiceFees_insufficientFunds_treasury() external {}

    function test_payClosingServiceFees() external {
        ( uint256 principal, uint256 interest, uint256 fees ) = loan.getClosingPaymentBreakdown();

        assertEq(principal, 1_000_000e18);
        assertEq(interest,  20_000e18);
        assertEq(fees,      2_250e18);  // 1m * (0.3% + 0.6%) / 12 * 3 = 1000 + 750

        fundsAsset.mint(BORROWER, 47_250e18);  // 25k + 20k + 2.25k = 47.25k

        vm.startPrank(BORROWER);

        fundsAsset.approve(address(loan), 1_022_250e18);  // 1m + 20k + 2.25k = 1_022_250

        assertEq(fundsAsset.balanceOf(BORROWER),        1_022_250e18);  // 1m + 20k + 2.25k + = 1_022_250
        assertEq(fundsAsset.balanceOf(address(lender)), 0);
        assertEq(fundsAsset.balanceOf(PD),              25_000e18);     // Origination fees
        assertEq(fundsAsset.balanceOf(TREASURY),        0);

        loan.closeLoan(1_022_250e18);

        assertEq(fundsAsset.balanceOf(BORROWER),        0);
        assertEq(fundsAsset.balanceOf(address(lender)), 1_020_000e18);          // Principal + interest
        assertEq(fundsAsset.balanceOf(PD),              25_000e18 + 1_500e18);
        assertEq(fundsAsset.balanceOf(TREASURY),        750e18);
    }

}

contract PayOriginationFeesTests is FeeManagerBase {

    LopoLoan loan;

    uint256 originationFee = 50_000e18;

    function setUp() public override {
        super.setUp();

        loan = LopoLoan(
            _createLoan(BORROWER, address(lender), address(feeManager), defaultAssets, defaultTermDetails, defaultAmounts, defaultRates, defaultFees, "salt")
        );

        globals.setPlatformOriginationFeeRate(address(poolManager), 3000);  // 0.3%
    }

    function test_payOriginationFees_insufficientFunds_poolDelegate() external {
        fundsAsset.mint(address(loan), 50_00e18 - 1);

        vm.prank(address(lender));
        vm.expectRevert("MLFM:POF:PD_TRANSFER");
        loan.fundLoan();
    }

    function test_payOriginationFees_insufficientFunds_treasury() external {
        fundsAsset.mint(address(loan), 25_750e18 - 1);  // 50k + (1m * 0.3% / 12 * 3) = 50_750

        vm.prank(address(lender));
        vm.expectRevert("MLFM:POF:TREASURY_TRANSFER");
        loan.fundLoan();
    }

    function test_payOriginationFees_zeroTreasury() external {
        vm.prank(GOVERNOR);
        globals.setLopoTreasury(address(0));

        fundsAsset.mint(address(loan), 1_000_000e18);  // 1m + 50k + (1m * 0.3% = 3_000) = 1_053_000

        vm.prank(address(lender));
        vm.expectRevert("MLFM:TT:ZERO_DESTINATION");
        loan.fundLoan();
    }

    function test_payOriginationFees() external {
        fundsAsset.mint(address(loan), 1_000_000e18);  // 1m + 50k + (1m * 0.3% = 3_000) = 1_053_000

        assertEq(fundsAsset.balanceOf(address(loan)), 1_000_000e18);
        assertEq(fundsAsset.balanceOf(PD),            0);
        assertEq(fundsAsset.balanceOf(TREASURY),      0);

        vm.prank(address(lender));
        loan.fundLoan();

        assertEq(fundsAsset.balanceOf(address(loan)), 974_250e18);  // Principal - both origination fees
        assertEq(fundsAsset.balanceOf(PD),            25_000e18);   // 25k origination fee to PD
        assertEq(fundsAsset.balanceOf(TREASURY),      750e18);      // (1m * 0.3% / 12 * 3) = 750 to treasury
    }

}

contract PayServiceFeesTests is FeeManagerBase {

    LopoLoan loan;

    uint256 platformServiceFeeRate = 3000;  // 0.3%

    function setUp() public override {
        super.setUp();

        loan = LopoLoan(
            _createLoan(BORROWER, address(lender), address(feeManager), defaultAssets, defaultTermDetails, defaultAmounts, defaultRates, defaultFees, "salt")
        );

        globals.setPlatformServiceFeeRate(address(poolManager), platformServiceFeeRate);

        _fundLoan(address(loan), address(lender), loan.principalRequested());
        _drawdownLoan(address(loan), BORROWER);
    }

    // TODO: These tests cannot be done due to lack of Mocked Loan
    // function test_payServiceFees_insufficientFunds_poolDelegate() external {}
    // function test_payServiceFees_insufficientFunds_treasury() external {}

    function test_payServiceFees_zeroTreasury() external {
        ( uint256 principal, uint256 interest, uint256 fees ) = loan.getNextPaymentBreakdown();

        assertEq(principal, 0);
        assertEq(interest,  10_000e18);
        assertEq(fees,      750e18);     // 1m * (0.3% + 0.6%) / 12 = 250 + 500

        vm.prank(GOVERNOR);
        globals.setLopoTreasury(address(0));

        vm.startPrank(BORROWER);

        fundsAsset.approve(address(loan), 10_750e18);

        vm.expectRevert("MLFM:TT:ZERO_DESTINATION");
        loan.makePayment(10_750e18);
    }

    function test_payServiceFees() external {
        ( uint256 principal, uint256 interest, uint256 fees ) = loan.getNextPaymentBreakdown();

        assertEq(principal, 0);
        assertEq(interest,  10_000e18);
        assertEq(fees,      750e18);     // 1m * (0.3% + 0.6%) / 12 = 250 + 500

        vm.startPrank(BORROWER);

        fundsAsset.approve(address(loan), 10_750e18);

        assertEq(fundsAsset.balanceOf(BORROWER),        975_000e18);
        assertEq(fundsAsset.balanceOf(address(lender)), 0);
        assertEq(fundsAsset.balanceOf(PD),              25_000e18);  // Origination fees
        assertEq(fundsAsset.balanceOf(TREASURY),        0);

        loan.makePayment(10_750e18);

        assertEq(fundsAsset.balanceOf(BORROWER),        964_250e18);          // 950k - 10.75k
        assertEq(fundsAsset.balanceOf(address(lender)), 10_000e18);           // Interest
        assertEq(fundsAsset.balanceOf(PD),              25_000e18 + 500e18);
        assertEq(fundsAsset.balanceOf(TREASURY),        250e18);
    }

}

contract UpdatePlatformServiceFeeTests is FeeManagerBase {

    function test_updatePlatformServiceFee() external {
        address loan1 = _createLoan(
            BORROWER,
            address(lender),
            address(feeManager),
            defaultAssets,
            defaultTermDetails,
            defaultAmounts,
            defaultRates,
            defaultFees,
            "salt1"
        );

        address loan2 = _createLoan(
            BORROWER,
            address(lender),
            address(feeManager),
            defaultAssets,
            defaultTermDetails,
            defaultAmounts,
            defaultRates,
            defaultFees,
            "salt2"
        );

        _fundLoan(loan1, address(lender), 1_000_000e18);
        _fundLoan(loan2, address(lender), 1_000_000e18);

        assertEq(feeManager.platformServiceFee(loan1), 0);
        assertEq(feeManager.platformServiceFee(loan2), 0);

        globals.setPlatformServiceFeeRate(address(poolManager), 3000);  // 0.3%

        vm.prank(loan1);
        feeManager.updatePlatformServiceFee(1_000_000e18, 365 days / 12);

        assertEq(feeManager.platformServiceFee(loan1), 250e18);  // Updated from globals (1m * 0.3% / 12)
        assertEq(feeManager.platformServiceFee(loan2), 0);       // Unchanged from globals

        globals.setPlatformServiceFeeRate(address(poolManager), 6000);  // 0.6%

        vm.prank(loan2);
        feeManager.updatePlatformServiceFee(1_000_000e18, 365 days / 12);

        assertEq(feeManager.platformServiceFee(loan1), 250e18);  // Unchanged from globals
        assertEq(feeManager.platformServiceFee(loan2), 500e18);  // Updated from globals (1m * 0.6% / 12)
    }

}

contract UpdateFeeTerms_SetterTests is FeeManagerBase {

    function test_updateDelegateFeeTerms() external {
        address someContract = address(new Address());

        assertEq(feeManager.delegateOriginationFee(someContract), 0);
        assertEq(feeManager.delegateServiceFee(someContract),     0);

        vm.prank(someContract);
        feeManager.updateDelegateFeeTerms(50_000e18, 1000e18);

        assertEq(feeManager.delegateOriginationFee(someContract), 50_000e18);
        assertEq(feeManager.delegateServiceFee(someContract),     1000e18);
    }

}

contract FeeManager_Getters is FeeManagerBase {

    function setUp() public override {
        super.setUp();
    }

    function test_getDelegateServiceFeesForPeriod() external {
        defaultTermDetails = [uint256(10 days), uint256(10 days), uint256(3)];

        address loan1 = _createLoan(
            BORROWER,
            address(lender),
            address(feeManager),
            defaultAssets,
            defaultTermDetails,
            defaultAmounts,
            defaultRates,
            defaultFees,
            "salt1"
        );

        vm.prank(loan1);
        feeManager.updateDelegateFeeTerms(50_000e18, 1000e18);

        // The loan interval is 10 days. So this tests should return the proportional amount
        assertEq(feeManager.getDelegateServiceFeesForPeriod(loan1, 0 days),  0);
        assertEq(feeManager.getDelegateServiceFeesForPeriod(loan1, 1 days),  100e18);   // 10% of the full fee
        assertEq(feeManager.getDelegateServiceFeesForPeriod(loan1, 5 days),  500e18);   // 50% of the full fee
        assertEq(feeManager.getDelegateServiceFeesForPeriod(loan1, 10 days), 1000e18);  // 100% of the full fee
        assertEq(feeManager.getDelegateServiceFeesForPeriod(loan1, 11 days), 1100e18);  // 110% of the full fee
        assertEq(feeManager.getDelegateServiceFeesForPeriod(loan1, 15 days), 1500e18);  // 150% of the full fee
        assertEq(feeManager.getDelegateServiceFeesForPeriod(loan1, 20 days), 2000e18);  // 200% of the full fee
    }

    function test_getPlatformServiceFeeForPeriod() external {
        defaultTermDetails = [uint256(10 days), uint256(365 days), uint256(3)];

        address loan1 = _createLoan(
            BORROWER,
            address(lender),
            address(feeManager),
            defaultAssets,
            defaultTermDetails,
            defaultAmounts,
            defaultRates,
            defaultFees,
            "salt1"
        );

        _fundLoan(loan1, address(lender), 1_000_000e18);

        globals.setPlatformServiceFeeRate(address(poolManager), 1_0000);

        vm.prank(loan1);
        feeManager.updatePlatformServiceFee(1_000_000e18, 365 days);

        // The loan interval is 10 days. So this tests should return the proportional amount
        assertEq(feeManager.getPlatformServiceFeeForPeriod(loan1, 1_000_000e18, 0 days),  0);
        assertEq(feeManager.getPlatformServiceFeeForPeriod(loan1, 1_000_000e18, 365 days / 10), 1_000e18);   // 10% of the full fee (1_000_000 * 0.001 / 10)
        assertEq(feeManager.getPlatformServiceFeeForPeriod(loan1, 1_000_000e18, 365 days / 2 ), 5_000e18);   // 50% of the full fee
        assertEq(feeManager.getPlatformServiceFeeForPeriod(loan1, 1_000_000e18, 365 days),      10_000e18);  // 100% of the full fee
        assertEq(feeManager.getPlatformServiceFeeForPeriod(loan1, 1_000_000e18, 365 days * 2),  20_000e18);  // 200% of the full fee
        assertEq(feeManager.getPlatformServiceFeeForPeriod(loan1, 1_000_000e18, 365 days * 3),  30_000e18);  // 300% of the full fee
    }

}

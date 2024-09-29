// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Loan } from "contracts/libraries/types/DataTypes.sol";

import { MintableERC20WithPermit } from "../mocks/MintableERC20WithPermit.sol";
import { MockImplementation } from "../mocks/MockImplementation.sol";

import { WithdrawalManager, Receivable } from "contracts/libraries/types/DataTypes.sol";

import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    uint256 public constant DELTA = 1e6;

    uint256 public constant POOL_SHARES = 1_000_000e6;
    uint256 public constant POOL_ASSETS = 1_500_000e6; // note: must be larger than POOL_SHARES, see initializePool()

    uint8 public constant UNDERLYING_DECIMALS = 6;
    uint8 public constant DECIMALS_OFFSET = 4;
    uint256 public immutable DEADLINE; // for erc20 permit

    uint256 public constant DEPOSIT_AMOUNT = 1000e6;
    uint256 public constant MINT_AMOUNT = 100_000e6;
    uint256 public constant COVER_AMOUNT = 10_000e6;
    uint256 public constant WITHDRAW_COVER_AMOUNT = 100e6;
    uint256 public constant REDEEM_SHARES = 100e6;
    uint24 public constant ADMIN_FEE_RATE = 0.1e6; // 10%
    uint24 public constant PROTOCOL_FEE_RATE = 0.005e6; // 0.5%

    // Isle Globals
    uint24 public constant MAX_COVER_LIQUIDATION = 0.5e6; // 50%
    uint104 public constant MIN_COVER_AMOUNT = 10e6;
    uint104 public constant POOL_LIMIT = 5_000_000e6;

    // Pool Configurator
    uint96 public constant BASE_RATE = 0.1e6; // 10%
    uint32 public constant GRACE_PERIOD = 7 days;
    bool public constant OPEN_TO_PUBLIC = true;

    // Pool
    string public constant POOL_NAME = "BSOS Green Share";
    string public constant POOL_SYMBOL = "BGS";

    // Receivable
    uint256 public constant RECEIVABLE_TOKEN_ID = 0;
    uint256 public constant FACE_AMOUNT = 100_000e6;
    uint256 public immutable REPAYMENT_TIMESTAMP;
    uint256 public immutable START_DATE;
    uint16 public constant CURRENCY_CODE = 804;
    uint256 public constant MAY_31_2023 = MAY_1_2023 + 30 days;
    uint256 public immutable PERIOD;

    // Note: For convertTo.t.sol (can change if decimals offset, pool shares, pool assets are modified)
    uint256 public constant ASSETS = 1_000_000;
    uint256 public constant EXPECTED_SHARES = 666_666; // ASSETS * (POOL_SHARES + 1) / (POOL_ASSETS + 1) Round down
    // ASSETS * (POOL_SHARES + 1) / (POOL_ASSETS - unrealizedLosses + 1) Round down
    uint256 public constant EXPECTED_EXIT_SHARES = 714_285;
    uint256 public constant SHARES = 1_000_000;
    uint256 public constant EXPECTED_ASSETS = 1_499_999; // SHARES * (POOL_ASSETS + 1) / (POOL_SHARES + 1) Round down
    // SHARES * (POOL_ASSETS - unrealizedLosses + 1) / (POOL_SHARES + 1) Round down
    uint256 public constant EXPECTED_EXIT_ASSETS = 1_399_999;

    // For withdrawal manager
    uint64 public constant WINDOW_DURATION = 2 days;
    uint64 public constant CYCLE_DURATION = 7 days;

    uint64 public immutable WINDOW_1;
    uint64 public immutable WINDOW_3;
    uint64 public immutable WINDOW_4;
    uint64 public immutable WINDOW_5;

    uint64 public constant NEW_WINDOW_DURATION = 4 days;
    uint64 public constant NEW_CYCLE_DURATION = 14 days;

    uint256 public constant ADD_SHARES = 10e6;
    uint256 public constant REMOVE_SHARES = 5e6; // must be smaller than ADD_SHARES

    // For PoolAddressesProvider
    bytes32 public constant ID = "CONTRACT";
    address public constant NEW_ADDRESS = address(0x2);
    string public constant MARKET_ID = "BSOS Green Finance";
    string public constant NEW_MARKET_ID = "BSOS Green Finance 2";
    address public immutable NEW_IMPLEMENTATION;

    // For loan manager
    uint256 public constant PRINCIPAL_REQUESTED = 100_000e6;
    uint256 public constant INTEREST_RATE = 0.12e6;
    uint256 public constant LATE_INTEREST_PREMIUM_RATE = 0.2e6;
    Loan.Info public EMPTY_LOAN_INFO;

    // e6 * e18 / e6 = e18
    uint256 public constant PERIODIC_INTEREST_RATE = uint256(INTEREST_RATE) * (1e18 / 1e6) * 30 days / 365 days;
    // e6 * e18 / e18 = e6
    uint256 public constant INTEREST = PRINCIPAL_REQUESTED * PERIODIC_INTEREST_RATE / 1e18;
    // e6 * e6 / e6 = e6
    uint256 public constant NET_INTEREST_ZERO_FEE_RATE = INTEREST * (1e6 - 0e6) / 1e6;
    // e6 * e27 / seconds = e33 / seconds
    uint256 public constant NEW_RATE_ZERO_FEE_RATE = NET_INTEREST_ZERO_FEE_RATE * 1e27 / 30 days;

    // ((MAY_31_2023 + 9 days + 1 - MAY_31_2023 + (1 days - 1)) / 1 days) * 1 days
    uint256 public constant FULL_DAYS_LATE = 10 days;
    uint256 public constant LATE_PERIODIC_INTEREST_RATE =
        uint256(INTEREST_RATE + LATE_INTEREST_PREMIUM_RATE) * (1e18 / 1e6) * FULL_DAYS_LATE / 365 days;
    uint256 public constant LATE_INTEREST = PRINCIPAL_REQUESTED * LATE_PERIODIC_INTEREST_RATE / 1e18;

    uint256 public constant ADMIN_FEE = INTEREST * ADMIN_FEE_RATE / 1e6;
    uint256 public constant PROTOCOL_FEE = INTEREST * PROTOCOL_FEE_RATE / 1e6;
    uint256 public constant NET_INTEREST = INTEREST - ADMIN_FEE - PROTOCOL_FEE;

    // For function paused tests
    address public constant PAUSED_CONTRACT = address(0x1);
    bytes4 public constant PAUSED_FUNCTION_SIG = bytes4(keccak256("paused()"));

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    MintableERC20WithPermit private asset;
    Users private users;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        DEADLINE = MAY_1_2023 + 10 days;
        WINDOW_1 = MAY_1_2023;
        WINDOW_3 = WINDOW_1 + CYCLE_DURATION * 2;
        WINDOW_4 = WINDOW_1 + CYCLE_DURATION * 3;
        WINDOW_5 = WINDOW_1 + CYCLE_DURATION * 4;
        START_DATE = MAY_1_2023;
        REPAYMENT_TIMESTAMP = MAY_31_2023;
        PERIOD = REPAYMENT_TIMESTAMP - START_DATE;
        NEW_IMPLEMENTATION = address(new MockImplementation());
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function setAsset(MintableERC20WithPermit asset_) public {
        asset = asset_;
    }

    function setUsers(Users memory users_) public {
        users = users_;
    }

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    function receivableInfo() public view returns (Receivable.Info memory) {
        return Receivable.Info({
            buyer: users.buyer,
            seller: users.seller,
            faceAmount: FACE_AMOUNT,
            repaymentTimestamp: REPAYMENT_TIMESTAMP,
            currencyCode: CURRENCY_CODE,
            isValid: true
        });
    }

    /*//////////////////////////////////////////////////////////////
                                 PARAMS
    //////////////////////////////////////////////////////////////*/

    function createReceivable() public view returns (Receivable.Create memory) {
        return Receivable.Create({
            buyer: users.buyer,
            seller: users.seller,
            faceAmount: FACE_AMOUNT,
            repaymentTimestamp: REPAYMENT_TIMESTAMP,
            currencyCode: CURRENCY_CODE
        });
    }
}

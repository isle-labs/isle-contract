// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { MintableERC20WithPermit } from "../mocks/MintableERC20WithPermit.sol";

import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant DELTA = 1e6;

    uint256 public constant POOL_LIMIT = 1_000_000e6;
    uint256 public constant POOL_SHARES = 1000e6;
    uint256 public constant POOL_ASSETS = 1500e6; // note: must be larger than POOL_SHARES, see setupPool() in
        // Base.t.sol

    uint8 public constant UNDERLYING_DECIMALS = 18;
    uint8 public constant DECIMALS_OFFSET = 0;

    uint256 public immutable DEADLINE; // for erc20 permit
    uint256 public constant DEPOSIT_AMOUNT = 1000e6;
    uint256 public constant MINT_AMOUNT = 100_000e6;
    uint256 public constant COVER_AMOUNT = 10_000e6;
    uint256 public constant WITHDRAW_COVER_AMOUNT = 100e6;
    uint104 public constant MIN_COVER_AMOUNT = 10e6;
    uint256 public constant REDEEM_AMOUNT = 1000e6;
    uint256 public constant PRINCIPAL = 100e6;

    uint256 public constant ADMIN_FEE = 1000; // 10%

    // Receivable
    uint256 public constant FACE_AMOUNT = 100e6;
    uint256 public immutable REPAYMENT_TIMESTAMP;
    uint16 public constant CURRENCY_CODE = 804;

    // Note: For convertTo.t.sol (can change if decimals offset, pool shares, pool assets is modified)
    uint256 public constant ASSETS = 1_000_000;
    uint256 public constant EXPECTED_SHARES = 666_666; // ASSETS * (POOL_SHARES + 1) / (POOL_ASSETS + 1) Round down
    uint256 public constant EXPECTED_EXIT_SHARES = 100_000e6;
    uint256 public constant SHARES = 1_000_000;
    uint256 public constant EXPECTED_ASSETS = 1_499_999; // SHARES * (POOL_ASSETS + 1) / (POOL_SHARES + 1) Round down
    uint256 public constant EXPECTED_EXIT_ASSETS = 100_000e6;

    // For withdrawal manager
    uint256 public constant WINDOW_DURATION = 2 days;
    uint256 public constant CYCLE_DURATION = 7 days;
    uint256 public immutable WINDOW_1;
    uint256 public immutable CYCLE_1;
    uint256 public immutable WINDOW_3;
    uint256 public immutable CYCLE_3;

    // For function paused tests
    address public constant PAUSED_CONTRACT = address(0x1);
    bytes4 public constant PAUSED_FUNCTION_SIG = bytes4(keccak256("paused()"));

    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    MintableERC20WithPermit private asset;
    Users private users;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEADLINE = MAY_1_2023 + 10 days;
        WINDOW_1 = MAY_1_2023;
        CYCLE_1 = MAY_1_2023 + WINDOW_DURATION;
        WINDOW_3 = WINDOW_1 + CYCLE_DURATION * 2;
        CYCLE_3 = CYCLE_1 + CYCLE_DURATION * 2;
        REPAYMENT_TIMESTAMP = MAY_1_2023 + 30 days;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function setAsset(MintableERC20WithPermit asset_) public {
        asset = asset_;
    }

    function setUsers(Users memory users_) public {
        users = users_;
    }
}

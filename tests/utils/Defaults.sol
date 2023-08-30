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
    uint256 public constant LIQUIDITY_CAP = 1_000_000e6;
    uint256 public constant DEPOSIT_AMOUNT = 100_000;
    uint256 public constant MINT_AMOUNT = 10_000;
    uint256 public DEADLINE;

    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    MintableERC20WithPermit private asset;
    Users private users;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEADLINE = block.timestamp + 10 days;
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

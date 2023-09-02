// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { StdCheats } from "@forge-std/StdCheats.sol";

struct Users {
    // Default governor for all Lopo contracts
    address payable governor;
    // Default pool admin for the pools
    address payable poolAdmin;
    // Default seller
    address payable seller;
    // Default buyer
    address payable buyer;
    // Default deposit/mint/redeem/withdraw caller
    address payable caller;
    // Default depositWithPermit/mintWithPermit staker
    StdCheats.Account staker;
    // Default depositWithPermit/mintWithPermit fake staker
    StdCheats.Account notStaker;
    // Default deposit/mint/redeem/withdraw receiver
    address payable receiver;
    // Default deposit/mint/redeem/withdraw unwhitelisted receiver
    address payable notWhitelistedReceiver;
    // Default null user that is used
    address payable nullUser;
}

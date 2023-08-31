// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { StdCheats } from "@forge-std/StdCheats.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";
import { UUPSProxy } from "../../contracts/libraries/upgradability/UUPSProxy.sol";

import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";
import { ILoanManager } from "../../contracts/interfaces/ILoanManager.sol";
import { IWithdrawalManager } from "../../contracts/interfaces/IWithdrawalManager.sol";
import { IPoolConfigurator } from "../../contracts/interfaces/IPoolConfigurator.sol";
import { IReceivable } from "../../contracts/interfaces/IReceivable.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";

import { Receivable } from "../../contracts/Receivable.sol";
import { PoolAddressesProvider } from "../../contracts/PoolAddressesProvider.sol";
import { PoolConfigurator } from "../../contracts/PoolConfigurator.sol";
import { LoanManager } from "../../contracts/LoanManager.sol";
import { WithdrawalManager } from "../../contracts/WithdrawalManager.sol";

import { Base_Test } from "../Base.t.sol";

contract Integration_Test is Base_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Base_Test.setUp();

        // set up test contracts
        deployContracts();

        approveProtocol();

        // Make the pool admin the default caller in the test suite
        changePrank(users.poolAdmin);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function approveProtocol() internal {
        changePrank(users.caller);
        usdc.approve(address(pool), type(uint256).max);

        changePrank(users.receiver);
        usdc.approve(address(pool), type(uint256).max);
    }
}

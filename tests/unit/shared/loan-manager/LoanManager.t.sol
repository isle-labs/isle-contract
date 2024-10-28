// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Base_Test } from "../../../Base.t.sol";

abstract contract LoanManager_Unit_Shared_Test is Base_Test {
    function setUp() public virtual override {
        Base_Test.setUp();
        deployContract();
    }

    function deployContract() internal {
        changePrank(users.governor);
        isleGlobals = deployGlobals();
        poolAddressesProvider = deployPoolAddressesProvider(isleGlobals);
        setDefaultGlobals(poolAddressesProvider);
        loanManager = deployLoanManager(poolAddressesProvider, address(usdc));
    }
}

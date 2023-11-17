// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { LoanManager } from "contracts/LoanManager.sol";

import { ILoanManager } from "contracts/interfaces/ILoanManager.sol";
import { ILoanManagerEvents } from "contracts/interfaces/ILoanManagerEvents.sol";

import { Errors } from "contracts/libraries/Errors.sol";

import { Base_Test } from "../../../../Base.t.sol";
import { LoanManager_Unit_Shared_Test } from "../../../shared/loan-manager/LoanManager.t.sol";

contract Initialize_LoanManager_Unit_Concrete_Test is LoanManager_Unit_Shared_Test {
    function setUp() public virtual override {
        Base_Test.setUp();

        // Setup pool addresses provider
        changePrank(users.governor);
        isleGlobals = deployGlobals();
        poolAddressesProvider = deployPoolAddressesProvider(isleGlobals);
        setDefaultGlobals(poolAddressesProvider);
    }

    function test_initialize_RevertWhen_AssetZeroAddress() external {
        address loanManagerImpl_ = address(new LoanManager(poolAddressesProvider));
        bytes memory params = abi.encodeWithSelector(ILoanManager.initialize.selector, address(0));
        vm.expectRevert(abi.encodeWithSelector(Errors.LoanManager_AssetZeroAddress.selector));
        poolAddressesProvider.setLoanManagerImpl(loanManagerImpl_, params);
    }

    function test_initialize() external whenAssetNotZeroAddress {
        vm.expectEmit(true, true, true, true);
        emit LoanManagerInitialized({ poolAddressesProvider_: address(poolAddressesProvider), asset_: address(usdc) });
        deployLoanManager(poolAddressesProvider, address(usdc));
    }

    modifier whenAssetNotZeroAddress() {
        _;
    }
}

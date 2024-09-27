// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { WithdrawalManager } from "contracts/WithdrawalManager.sol";
import { IPoolAddressesProvider } from "contracts/interfaces/IPoolAddressesProvider.sol";

import { WithdrawalManager_Integration_Shared_Test } from "../../../shared/withdrawal-manager/WithdrawalManager.t.sol";

contract Constructor_WithdrawalManager_Integration_Concrete_Test is WithdrawalManager_Integration_Shared_Test {
    function setUp() public virtual override(WithdrawalManager_Integration_Shared_Test) {
        WithdrawalManager_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_AddressesProviderIsZeroAddress() external {
        vm.expectRevert(Errors.AddressesProviderZeroAddress.selector);
        new WithdrawalManager(IPoolAddressesProvider(address(0)));
    }
}

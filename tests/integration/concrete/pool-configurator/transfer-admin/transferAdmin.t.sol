// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { Errors } from "contracts/libraries/Errors.sol";

import { IAdminable } from "contracts/interfaces/IAdminable.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract TransferAdmin_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    IAdminable poolConfigurator_;

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();
        poolConfigurator_ = IAdminable(address(poolConfigurator));
    }

    modifier whenNewAdminVallid() {
        _;
    }

    function test_RevertWhen_CallerNotGovernor() external {
        changePrank(users.caller);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.PoolConfigurator_CallerNotGovernor.selector, address(users.caller))
        );
        poolConfigurator_.transferAdmin(users.eve);
    }

    function test_RevertWhen_InvalidNewAdmin() external whenCallerGovernor {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InvalidPoolAdmin.selector, address(0)));
        poolConfigurator_.transferAdmin(address(0));

        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InvalidPoolAdmin.selector, users.eve));
        poolConfigurator_.transferAdmin(users.eve);
    }

    function test_TransferAdmin() external whenCallerGovernor whenNewAdminVallid {
        isleGlobals.setValidPoolAdmin(users.caller, true);

        poolConfigurator_.transferAdmin(users.caller);
        assertEq(poolConfigurator_.admin(), users.caller);
    }
}

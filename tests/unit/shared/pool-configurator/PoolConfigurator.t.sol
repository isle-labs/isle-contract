// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { Base_Test } from "../../../Base.t.sol";

import { PoolConfigurator } from "contracts/PoolConfigurator.sol";

abstract contract PoolConfigurator_Unit_Shared_Test is Base_Test {
    struct Params {
        uint24 adminFee;
        uint32 gracePeriod;
        bool openToPublic;
    }

    Params private _params;

    function setUp() public virtual override {
        Base_Test.setUp();

        _params.adminFee = defaults.ADMIN_FEE_RATE();
        _params.gracePeriod = defaults.GRACE_PERIOD();
        _params.openToPublic = defaults.OPEN_TO_PUBLIC();

        deployContract();

        changePrank(users.poolAdmin);
    }

    function deployContract() internal {
        changePrank(users.governor);
        isleGlobals = deployGlobals();
        poolAddressesProvider = deployPoolAddressesProvider(isleGlobals);
        setDefaultGlobals(poolAddressesProvider);
        poolConfigurator = deployPoolConfigurator(poolAddressesProvider);
    }

    function setDefaultAdminFee() internal {
        poolConfigurator.setAdminFee(_params.adminFee);
    }

    function setDefaultOpenToPublic() internal {
        poolConfigurator.setOpenToPublic(_params.openToPublic);
    }

    modifier whenCallerPoolAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        changePrank({ msgSender: users.poolAdmin });
        _;
    }
}

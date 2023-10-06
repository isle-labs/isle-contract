// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "../../../Base.t.sol";

import { PoolConfigurator } from "contracts/PoolConfigurator.sol";

abstract contract PoolConfigurator_Unit_Shared_Test is Base_Test {
    struct Params {
        uint96 baseRate;
        uint24 adminFee;
        uint32 gracePeriod;
        bool openToPublic;
    }

    Params private _params;

    function setUp() public virtual override {
        Base_Test.setUp();

        _params.baseRate = defaults.BASE_RATE();
        _params.adminFee = defaults.ADMIN_FEE_RATE();
        _params.gracePeriod = defaults.GRACE_PERIOD();
        _params.openToPublic = defaults.OPEN_TO_PUBLIC();

        deployContract();

        changePrank(users.poolAdmin);
    }

    function deployContract() internal {
        changePrank(users.governor);
        poolAddressesProvider = deployPoolAddressesProvider();
        isleGlobals = deployGlobals();
        setDefaultGlobals(poolAddressesProvider);
        poolConfigurator = deployPoolConfigurator(poolAddressesProvider);
    }

    function setDefaultBaseRate() internal {
        poolConfigurator.setBaseRate(_params.baseRate);
    }

    function setDefaultAdminFee() internal {
        poolConfigurator.setAdminFee(_params.adminFee);
    }

    function setDefaultGracePeriod() internal {
        poolConfigurator.setGracePeriod(_params.gracePeriod);
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

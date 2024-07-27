// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "../../../Base.t.sol";
import { MockGovernable } from "../../../mocks/MockGovernable.sol";

abstract contract Governable_Test is Base_Test {
    MockGovernable public mockGovernable;

    function setUp() public virtual override {
        Base_Test.setUp();
        mockGovernable = new MockGovernable(users.governor);
    }

    modifier whenCallerGovernor() {
        changePrank(users.governor);
        _;
    }
}

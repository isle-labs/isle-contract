// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Base_Test } from "../../../Base.t.sol";
import { Governable } from "../../../../contracts/abstracts/Governable.sol";

abstract contract Governable_Test is Base_Test {
    WrapGovernable public wrapGovernable;

    function setUp() public virtual override {
        Base_Test.setUp();
        wrapGovernable = new WrapGovernable(users.governor);
    }

    modifier whenCallerGovernor() {
        changePrank(users.governor);
        _;
    }
}

contract WrapGovernable is Governable {
    constructor(address governor_) {
        governor = governor_;
    }
}

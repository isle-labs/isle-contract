// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { PRBMathAssertions } from "@prb/math/test/Assertions.sol";
import { PRBTest } from "@prb/test/PRBTest.sol";

import { WithdrawalManager } from "contracts/libraries/types/DataTypes.sol";

abstract contract Assertions is PRBTest, PRBMathAssertions {
    /// @dev Compares two {WithdrawalManager.CycleConfig} struct entities.
    function assertEq(WithdrawalManager.CycleConfig memory a, WithdrawalManager.CycleConfig memory b) internal {
        assertEq(a.initialCycleId, b.initialCycleId, "config.initialCycleId");
        assertEq(a.initialCycleTime, b.initialCycleTime, "config.initialCycleTime");
        assertEq(a.cycleDuration, b.cycleDuration, "config.cycleDuration");
        assertEq(a.windowDuration, b.windowDuration, "config.windowDuration");
    }
}

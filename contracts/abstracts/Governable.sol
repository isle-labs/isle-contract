// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { IGovernable } from "../interfaces/IGovernable.sol";
import { Errors } from "../libraries/Errors.sol";

/// @title Governable
/// @notice See the documentation in {IGovernable}.
abstract contract Governable is IGovernable {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IGovernable
    address public override governor;

    /// @inheritdoc IGovernable
    address public override pendingGovernor;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Reverts if called by any account other than the governor.
    modifier onlyGovernor() virtual {
        if (msg.sender != governor) {
            revert Errors.CallerNotGovernor({ governor_: governor, caller_: msg.sender });
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                         NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IGovernable
    function nominateGovernor(address newGovernor_) external virtual override onlyGovernor {
        if (newGovernor_ == address(0)) {
            revert Errors.GovernorZeroAddress();
        }

        pendingGovernor = newGovernor_;

        emit NominateGovernor({ governor: governor, pendingGovernor: newGovernor_ });
    }

    function acceptGovernor() external virtual override {
        if (msg.sender != pendingGovernor) {
            revert Errors.Globals_CallerNotPendingGovernor(pendingGovernor);
        }
        address oldGovernor_ = governor;
        governor = pendingGovernor;

        emit AcceptGovernor({ oldGovernor: oldGovernor_, newGovernor: governor });
    }

    function cancelPendingGovenor() external virtual override onlyGovernor {
        address oldPendingGovernor_ = pendingGovernor;
        pendingGovernor = address(0);
        emit CancelPendingGovernor({ oldPendingGovernor: oldPendingGovernor_ });
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

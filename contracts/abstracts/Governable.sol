// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

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
    function transferGovernor(address newGovernor) external virtual override onlyGovernor {
        if (newGovernor == address(0)) {
            revert Errors.GovernorZeroAddress();
        }
        // Effects: update the governor.
        governor = newGovernor;

        // Log the transfer of the governor.
        emit IGovernable.TransferGovernor({ oldGovernor: msg.sender, newGovernor: newGovernor });
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { Script } from "@forge-std/Script.sol";

import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

import { IsleGlobals } from "../contracts/IsleGlobals.sol";
import { Receivable } from "../contracts/Receivable.sol";

abstract contract BaseScript is Script {
    /// @dev included to enable the compilation of the script without a $MNEMONIC environment variable
    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";

    /// @dev needed for deterministic deployments
    bytes32 internal constant ZERO_SALT = bytes32(0);

    /// @dev Used to derive the addresses if environment variables are not defined.
    string internal mnemonic;

    /// @dev address of the participants
    address internal deployer;
    address internal poolAdmin;
    address internal buyer;
    address internal seller;
    address internal governor;
    address internal lender;

    /// @dev Initializes the participants like this:
    ///
    /// - If ${PARTICIPANT} is defined, use it.
    /// - Otherwise, derive the participant address from $MNEMONIC.
    /// - If $MNEMONIC is not defined, default to a test mnemonic.
    constructor() {
        address governor_ = vm.envOr({ name: "GOVERNOR", defaultValue: address(0) });

        if (governor_ != address(0)) {
            governor = governor_;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (governor,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
        }

        address poolAdmin_ = vm.envOr({ name: "POOL_ADMIN", defaultValue: address(0) });

        if (poolAdmin_ != address(0)) {
            poolAdmin = poolAdmin_;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (poolAdmin,) = deriveRememberKey({ mnemonic: mnemonic, index: 1 });
        }

        address deployer_ = vm.envOr({ name: "DEPLOYER", defaultValue: address(0) });

        if (deployer_ != address(0)) {
            deployer = deployer_;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (deployer,) = deriveRememberKey({ mnemonic: mnemonic, index: 2 });
        }

        address buyer_ = vm.envOr({ name: "BUYER", defaultValue: address(0) });

        if (buyer_ != address(0)) {
            buyer = buyer_;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (buyer,) = deriveRememberKey({ mnemonic: mnemonic, index: 3 });
        }

        address seller_ = vm.envOr({ name: "SELLER", defaultValue: address(0) });

        if (seller_ != address(0)) {
            seller = seller_;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (seller,) = deriveRememberKey({ mnemonic: mnemonic, index: 4 });
        }

        address lender_ = vm.envOr({ name: "LENDER", defaultValue: address(0) });

        if (lender_ != address(0)) {
            lender = lender_;
        } else {
            mnemonic = vm.envOr({ name: "MNEMONIC", defaultValue: TEST_MNEMONIC });
            (lender,) = deriveRememberKey({ mnemonic: mnemonic, index: 5 });
        }
    }

    modifier broadcast(address broadcaster_) {
        vm.startBroadcast(broadcaster_);
        _;
        vm.stopBroadcast();
    }

    function deployGlobals() internal broadcast(deployer) returns (IsleGlobals globals_) {
        globals_ = IsleGlobals(address(new UUPSProxy(address(new IsleGlobals()), "")));
        globals_.initialize(governor);
    }

    function deployReceivable() internal broadcast(deployer) returns (Receivable receivable_) {
        receivable_ = Receivable(address(new UUPSProxy(address(new Receivable()), "")));
        receivable_.initialize(governor);
    }
}

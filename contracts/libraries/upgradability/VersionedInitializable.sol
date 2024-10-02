// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.19;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 * @notice Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * @dev WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
abstract contract VersionedInitializable {
    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    struct VersionedInitializableStorage {
        /**
         * @dev Indicates the current contract version.
         */
        uint256 lastInitializedRevision;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool initializing;
    }

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        uint256 revision = getRevision();

        VersionedInitializableStorage storage $ = _getInitializableStorage();
        uint256 lastInitializedRevision = $.lastInitializedRevision;
        bool initializing = $.initializing;

        require(
            initializing || isConstructor() || revision > lastInitializedRevision,
            "Contract instance has already been initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            $.initializing = true;
            $.lastInitializedRevision = revision;
        }

        _;

        if (isTopLevelCall) {
            $.initializing = false;
        }
    }

    /**
     * @dev Modifier to use when a function is restricted to the initialization phase.
     */
    modifier onlyInitializing() {
        require(_getInitializing(), "Already Initialized");
        _;
    }

    /**
     * @notice Returns the revision number of the contract
     * @dev Needs to be defined in the inherited class as a constant.
     * @return The revision number
     */
    function getRevision() public pure virtual returns (uint256);

    /**
     * @notice Returns true if and only if the function is running in the constructor
     * @return True if the function is running in the constructor
     */
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        uint256 cs;
        //solium-disable-next-line
        assembly {
            cs := extcodesize(address())
        }
        return cs == 0;
    }

    function _getInitializableStorage() private pure returns (VersionedInitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }

    function _getLastInitializedRevision() internal view returns (uint256) {
        return _getInitializableStorage().lastInitializedRevision;
    }

    function _getInitializing() internal view returns (bool) {
        return _getInitializableStorage().initializing;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

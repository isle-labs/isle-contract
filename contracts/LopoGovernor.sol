// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// contract LopoGovernor is AccessControlUpgradeable, Initializable {
//     /**
//      * @dev Initializer that sets the default admin and dao member roles
//      */
//     function initialize() public initializer {
//         __AccessControl_init();

//         _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // By default, the admin role for all roles is
// `DEFAULT_ADMIN_ROLE`
//         _grantRole(DAO_MEMBER_ROLE, msg.sender);
//     }

// /**
//  * @dev Grant DAO_MEMBER_ROLE to a given address
//  * @param _member The address to be granted DAO_MEMBER_ROLE
//  * @notice This function can only be called by the default admin
//  */
// function grantDAOMember(address _member) public onlyRole(DEFAULT_ADMIN_ROLE) {
//     _grantRole(DAO_MEMBER_ROLE, _member);
// }

// /**
//  * @dev Revoke DAO_MEMBER_ROLE from a given address
//  * @param _member The address to be revoked DAO_MEMBER_ROLE
//  * @notice This function can only be called by the default admin
//  */
// function revokeDAOMember(address _member) public onlyRole(DEFAULT_ADMIN_ROLE) {
//     _revokeRole(DAO_MEMBER_ROLE, _member);
// }

// function

// /**
//  * @dev This empty reserved space is put in place to allow future versions to add new
//  * variables without shifting down storage in the inheritance chain.
//  * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
//  */
// uint256[50] private __gap;
// }

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import { TransparentUpgradeableProxy } from
// "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

// contract UUPSProxy is TransparentUpgradeableProxy {
//     constructor(
//         address implementation_,
//         address admin_,
//         bytes memory data_
//     )
//         TransparentUpgradeableProxy(implementation_, admin_, data_)
//     { }
// }

contract UUPSProxy is ERC1967Proxy {
    constructor(address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) { }
}

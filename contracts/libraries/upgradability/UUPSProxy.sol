// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { TransparentUpgradeableProxy } from "@openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

contract UUPSProxy is TransparentUpgradeableProxy {
    constructor(
        address implementation_,
        address admin_,
        bytes memory data_
    )
        TransparentUpgradeableProxy(implementation_, admin_, data_)
    { }
}

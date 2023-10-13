// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { console2 } from "@forge-std/console2.sol";

import { BaseScript } from "./Base.s.sol";

contract GetBalance is BaseScript {
    function run() public broadcast(deployer) {
        uint256 deployerBalance = deployer.balance;
        console2.log("Deployer balance: %e", deployerBalance);

        uint256 buyerBalance = buyer.balance;
        console2.log("Buyer balance: %e", buyerBalance);

        uint256 sellerBalance = seller.balance;
        console2.log("Seller balance: %e", sellerBalance);

        uint256 poolAdmin = poolAdmin.balance;
        console2.log("Pool Admin balance: %e", poolAdmin);

        uint256 governor = governor.balance;
        console2.log("Governor balance: %e", governor);
    }
}

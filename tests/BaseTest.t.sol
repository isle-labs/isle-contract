// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { StdCheats } from "@forge-std/StdCheats.sol";
import { PRBTest } from "@prb-test/PRBTest.sol";
import { console } from "@forge-std/console.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ERC20 } from "../contracts/ERC20.sol";
import { IERC20 } from "../contracts/interfaces/IERC20.sol";
import { LopoGlobals } from "../contracts/LopoGlobals.sol";
import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";
import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

abstract contract BaseTest is PRBTest, StdCheats {
    struct Users {
        address payable governor;
        address payable pool_admin;
        address payable seller;
        address payable buyer;
        address payable sender;
        address payable receiver;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    ERC20 internal usdc;
    LopoGlobals internal globalsV1;
    UUPSProxy internal LopoProxy;
    LopoGlobals internal wrappedLopoProxyV1;

    function setUp() public virtual {
        usdc = new ERC20("USDC", "USDC", 6);

        // create users for testing
        users = Users({
            governor: createUser("Governor"),
            pool_admin: createUser("PoolAdmin"),
            seller: createUser("Seller"),
            buyer: createUser("Buyer"),
            sender: createUser("Sender"),
            receiver: createUser("Receiver")
        });

        // Deploy the base test contracts
        globalsV1 = new LopoGlobals();
        // deploy LopoProxy and point it to the implementation
        LopoProxy = new UUPSProxy(address(globalsV1), "");
        // wrap in ABI to support easier calls
        wrappedLopoProxyV1 = LopoGlobals(address(LopoProxy));
        // initialize the LopoProxy, assign the governor
        wrappedLopoProxyV1.initialize(users.governor);

        // label the base test contracts
        vm.label(address(usdc), "USDC");
        vm.label(address(globalsV1), "globalsV1");
        vm.label(address(LopoProxy), "LopoProxy");
        vm.label(address(wrappedLopoProxyV1), "wrappedLopoProxyV1");

        // onboard users
        onboardUser();
    }

    function test_setUpStateBase() public {
        assertEq(wrappedLopoProxyV1.governor(), users.governor);
        assertEq(address(wrappedLopoProxyV1), address(LopoProxy));
        assertEq(address(users.governor).balance, 100 ether);
        assertEq(usdc.balanceOf(address(users.seller)), 1_000_000e6);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(usdc), to: user, give: 1_000_000e6 });
        return user;
    }

    function onboardUser() internal {
        vm.startPrank(users.governor);
        wrappedLopoProxyV1.setValidBuyer(users.buyer, true);
        wrappedLopoProxyV1.setValidPoolAdmin(users.pool_admin, true);
        vm.stopPrank();
        // TODO: onboard seller (borrower) in poolConfigurator
    }

    function _printReceivableInfo(ReceivableStorage.ReceivableInfo memory RECVInfo) internal view {
        console.log("# ReceivableInfo ---------------------------------");
        console.log("-> buyer: %s", RECVInfo.buyer);
        console.log("-> seller: %s", RECVInfo.seller);
        // notice that faceAmount is UD60x18
        console.log("-> faceAmount: %s", RECVInfo.faceAmount.intoUint256());
        console.log("-> repaymentTimestamp: %s", RECVInfo.repaymentTimestamp);
        console.log("-> isValid: %s", RECVInfo.isValid);
        console.log("-> currencyCode: %s", RECVInfo.currencyCode);
        console.log(""); // for layout
    }
}

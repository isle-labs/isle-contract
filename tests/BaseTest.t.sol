// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { StdCheats } from "@forge-std/StdCheats.sol";
import { console } from "@forge-std/console.sol";
import { PRBTest } from "@prb-test/PRBTest.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

import { ILopoGlobals } from "../contracts/interfaces/ILopoGlobals.sol";

import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";
import { LopoGlobals } from "../contracts/LopoGlobals.sol";

abstract contract BaseTest is PRBTest, StdCheats {
    struct Users {
        address payable governor;
        address payable pool_admin;
        address payable seller;
        address payable buyer;
        address payable caller;
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
    ILopoGlobals internal globalsV1;
    ILopoGlobals internal lopoGlobalsProxy;

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        usdc = new ERC20("Circle USD", "USDC");

        // create users for testing
        users = Users({
            governor: _createUser("Governor"),
            pool_admin: _createUser("PoolAdmin"),
            seller: _createUser("Seller"),
            buyer: _createUser("Buyer"),
            caller: _createUser("Sender"),
            receiver: _createUser("Receiver")
        });

        _setUpGlobals();

        // label the base test contracts
        _labelBaseContracts();

        // onboard users
        _onboardUsersAndAssetsToGlobals();
    }

    function test_setUpStateBase() public {
        assertEq(lopoGlobalsProxy.governor(), users.governor);
        assertEq(address(users.governor).balance, 100 ether);
        assertEq(usdc.balanceOf(address(users.seller)), 1_000_000e6);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function _setUpGlobals() internal {
        // Deploy the base test contracts
        globalsV1 = new LopoGlobals();
        // deploy LopoGlobalsProxy and point it to the implementation
        lopoGlobalsProxy = ILopoGlobals(address(new UUPSProxy(address(globalsV1), "")));
        // initialize the LopoGlobalsProxy, assign the governor
        lopoGlobalsProxy.initialize(users.governor);
    }

    function _labelBaseContracts() internal {
        vm.label(address(usdc), "USDC");
        vm.label(address(globalsV1), "globalsV1");
        vm.label(address(lopoGlobalsProxy), "lopoGlobalsProxy");
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function _createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(usdc), to: user, give: 1_000_000e6 });
        return user;
    }

    function _onboardUsersAndAssetsToGlobals() internal {
        vm.startPrank(users.governor);
        lopoGlobalsProxy.setValidPoolAsset(address(usdc), true);
        lopoGlobalsProxy.setValidBuyer(users.buyer, true);
        lopoGlobalsProxy.setValidPoolAdmin(users.pool_admin, true);
        vm.stopPrank();
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

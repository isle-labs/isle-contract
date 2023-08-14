// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { StdCheats } from "@forge-std/StdCheats.sol";
import { PRBTest } from "@prb-test/PRBTest.sol";
import { console } from "@forge-std/console.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { LopoGlobals } from "../contracts/LopoGlobals.sol";
import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";
import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";

abstract contract BaseTest is PRBTest, StdCheats {
    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address payable governor;
    address payable pool_admin;
    address payable seller;
    address payable buyer;
    address payable sender;
    address payable receiver;

    /*//////////////////////////////////////////////////////////////////////////
                                TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/
    ERC20 usdc;
    LopoGlobals globalsV1;
    UUPSProxy LopoProxy;
    LopoGlobals wrappedLopoProxyV1;

    function setUp() public virtual {
        // create users for testing
        governor = createUser("Governor");
        pool_admin = createUser("PoolAdmin");
        seller = createUser("Seller");
        buyer = createUser("Buyer");
        sender = createUser("Sender");
        receiver = createUser("Receiver");

        // Deploy the base test contracts
        usdc = new ERC20("USDC", "USDC");
        globalsV1 = new LopoGlobals();
        // deploy LopoProxy and point it to the implementation
        LopoProxy = new UUPSProxy(address(globalsV1), "");
        // wrap in ABI to support easier calls
        wrappedLopoProxyV1 = LopoGlobals(address(LopoProxy));
        // initialize the LopoProxy, assign the governor
        wrappedLopoProxyV1.initialize(governor);

        // label the base test contracts
        vm.label(address(usdc), "USDC");
        vm.label(address(globalsV1), "globalsV1");
        vm.label(address(LopoProxy), "LopoProxy");
        vm.label(address(wrappedLopoProxyV1), "wrappedLopoProxyV1");
    }

    function test_setUpState() public {
        assertEq(wrappedLopoProxyV1.governor(), governor);
        assertEq(address(wrappedLopoProxyV1), address(LopoProxy));
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name) internal returns (address payable) {
        address payable user = payable(makeAddr(name));
        vm.deal({account: user, newBalance: 100 ether});
        // deal({token: address(usdc), to: user, give: 1_000_000e6});
        return user;
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

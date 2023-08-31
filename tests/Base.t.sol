// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { StdCheats } from "@forge-std/StdCheats.sol";
import { console } from "@forge-std/console.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";
import { Events } from "./utils/Events.sol";
import { Defaults } from "./utils/Defaults.sol";
import { Utils } from "./utils/Utils.sol";
import { Users } from "./utils/Types.sol";

import { ILopoGlobals } from "../contracts/interfaces/ILopoGlobals.sol";

import { MintableERC20WithPermit } from "./mocks/MintableERC20WithPermit.sol";

import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";
import { LopoGlobals } from "../contracts/LopoGlobals.sol";

abstract contract Base_Test is StdCheats, Events, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    MintableERC20WithPermit internal usdc;
    Defaults internal defaults;
    ILopoGlobals internal globalsV1;
    ILopoGlobals internal lopoGlobalsProxy;

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        usdc = new MintableERC20WithPermit("Circle USD", "USDC", 6);

        // create users for testing
        users = Users({
            governor: createUser("Governor"),
            poolAdmin: createUser("PoolAdmin"),
            seller: createUser("Seller"),
            buyer: createUser("Buyer"),
            caller: createUser("Caller"),
            staker: createAccount("Staker"),
            notStaker: createAccount("NotStaker"),
            receiver: createUser("Receiver")
        });

        // Deploy the defaults contract
        defaults = new Defaults();
        defaults.setAsset(usdc);
        defaults.setUsers(users);

        setUpGlobals();

        // label the base test contracts
        labelBaseContracts();

        // onboard users
        onboardUsersAndAssetsToGlobals();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    function setUpGlobals() internal {
        // Deploy the base test contracts
        globalsV1 = new LopoGlobals();
        // deploy LopoGlobalsProxy and point it to the implementation
        lopoGlobalsProxy = ILopoGlobals(address(new UUPSProxy(address(globalsV1), "")));
        // initialize the LopoGlobalsProxy, assign the governor
        lopoGlobalsProxy.initialize(users.governor);
    }

    function labelBaseContracts() internal {
        vm.label(address(usdc), "USDC");
        vm.label(address(globalsV1), "globalsV1");
        vm.label(address(lopoGlobalsProxy), "lopoGlobalsProxy");
    }

    /// @dev Generates a user, labels its address, and funds it with test assets.
    function createUser(string memory name_) internal returns (address payable user_) {
        StdCheats.Account memory account_ = createAccount(name_);
        user_ = payable(account_.addr);
    }

    /// @dev Generates a user with private key, labels its address, and funds it with test assets.
    function createAccount(string memory name_) internal returns (StdCheats.Account memory account_) {
        account_ = makeAccount(name_);
        vm.deal({ account: account_.addr, newBalance: 100 ether });
        deal({ token: address(usdc), to: account_.addr, give: 1_000_000e18 });
    }

    function onboardUsersAndAssetsToGlobals() internal {
        vm.startPrank(users.governor);
        lopoGlobalsProxy.setValidPoolAsset(address(usdc), true);
        lopoGlobalsProxy.setValidBuyer(users.buyer, true);
        lopoGlobalsProxy.setValidPoolAdmin(users.poolAdmin, true);
        vm.stopPrank();
    }

    function printReceivableInfo(ReceivableStorage.ReceivableInfo memory RECVInfo) internal view {
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

    function airdropTo(address recipient_, uint256 amount_) internal {
        usdc.mint({ recipient_: recipient_, amount_: amount_ });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CALL EXPECTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(address to, uint256 amount) internal {
        vm.expectCall({ callee: address(usdc), data: abi.encodeCall(IERC20.transfer, (to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transfer}.
    function expectCallToTransfer(IERC20 asset, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transfer, (to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(usdc), data: abi.encodeCall(IERC20.transferFrom, (from, to, amount)) });
    }

    /// @dev Expects a call to {IERC20.transferFrom}.
    function expectCallToTransferFrom(IERC20 asset, address from, address to, uint256 amount) internal {
        vm.expectCall({ callee: address(asset), data: abi.encodeCall(IERC20.transferFrom, (from, to, amount)) });
    }
}

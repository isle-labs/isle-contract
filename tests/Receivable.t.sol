// // SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./BaseTest.t.sol";
import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";
import { Receivable } from "../contracts/Receivable.sol";
import { MockReceivableV2 } from "./mocks/MockReceivableV2.sol";

contract ReceivableTest is BaseTest {
    Receivable receivableV1;
    MockReceivableV2 receivableV2;

    UUPSProxy ReceivableProxy;
    Receivable wrappedReceivableProxyV1;
    MockReceivableV2 wrappedReceivableProxyV2;

    event AssetCreated(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 faceAmount,
        uint256 repaymentTimestamp
    );

    event LopoGlobalsSet(address indexed previousLopoGlobals_, address indexed currentLopoGlobals_);

    function setUp() public virtual override {
        super.setUp();
        receivableV1 = new Receivable();

        // deploy ReceivableProxy and point it to the implementation
        ReceivableProxy = new UUPSProxy(address(receivableV1), "");

        // wrap in ABI to support easier calls
        wrappedReceivableProxyV1 = Receivable(address(ReceivableProxy));

        // initialize the ReceivableProxy, assign the globals
        wrappedReceivableProxyV1.initialize(address(wrappedLopoProxyV1));

        // onboard buyer
        vm.prank(GOVERNOR);
        wrappedLopoProxyV1.setValidBorrower(DEFAULT_BUYER, true);
    }

    function test_getImplementation() public {
        assertEq(wrappedReceivableProxyV1.getImplementation(), address(receivableV1));
    }

    function test_createReceivable() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(DEFAULT_BUYER, DEFAULT_SELLER, 0, 1000e18, block.timestamp + 1 days);

        // caller of createReceivable() should be buyer
        vm.prank(DEFAULT_BUYER);
        wrappedReceivableProxyV1.createReceivable(DEFAULT_SELLER, ud(1000e18), block.timestamp + 1 days, 804);

        uint256 tokenId = wrappedReceivableProxyV1.tokenOfOwnerByIndex(address(DEFAULT_SELLER), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = wrappedReceivableProxyV1.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);
        assertEq(wrappedReceivableProxyV1.ownerOf(tokenId), DEFAULT_SELLER);
        assertEq(wrappedReceivableProxyV1.balanceOf(DEFAULT_SELLER), 1);
        assertEq(wrappedReceivableProxyV1.totalSupply(), 1);
        assertEq(wrappedReceivableProxyV1.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, DEFAULT_BUYER);
        assertEq(RECVInfo.seller, DEFAULT_SELLER);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);
    }

    function test_canUpgrade_readDataFromV1() public {
        vm.expectEmit(true, true, true, true);
        emit AssetCreated(DEFAULT_BUYER, DEFAULT_SELLER, 0, 1000e18, block.timestamp + 1 days);

        // caller of createReceivable() should be buyer
        vm.prank(DEFAULT_BUYER);
        wrappedReceivableProxyV1.createReceivable(DEFAULT_SELLER, ud(1000e18), block.timestamp + 1 days, 804);

        receivableV2 = new MockReceivableV2();

        vm.prank(wrappedReceivableProxyV1.governor());
        wrappedReceivableProxyV1.upgradeTo(address(receivableV2));

        // re-wrap the proxy to the new implementation
        wrappedReceivableProxyV2 = MockReceivableV2(address(ReceivableProxy));

        // @notice Receivable is already initialized, so we cannot call initialize() again
        string memory text = wrappedReceivableProxyV2.upgradeV2Test();
        assertEq(text, "ReceivableV2");

        uint256 tokenId = wrappedReceivableProxyV2.tokenOfOwnerByIndex(address(DEFAULT_SELLER), 0);

        // RecevableInfo
        ReceivableStorage.ReceivableInfo memory RECVInfo = wrappedReceivableProxyV2.getReceivableInfoById(tokenId);

        // assertions
        assertEq(tokenId, 0);
        assertEq(wrappedReceivableProxyV2.ownerOf(tokenId), DEFAULT_SELLER);
        assertEq(wrappedReceivableProxyV2.balanceOf(DEFAULT_SELLER), 1);
        assertEq(wrappedReceivableProxyV2.totalSupply(), 1);
        assertEq(wrappedReceivableProxyV2.tokenByIndex(0), tokenId);

        assertEq(RECVInfo.buyer, DEFAULT_BUYER);
        assertEq(RECVInfo.seller, DEFAULT_SELLER);
        assertEq(RECVInfo.faceAmount.intoUint256(), 1000e18);
        assertEq(RECVInfo.repaymentTimestamp, block.timestamp + 1 days);
        assertEq(RECVInfo.isValid, true);
        assertEq(RECVInfo.currencyCode, 804);

        // test getImplementation() in V2
        assertEq(wrappedReceivableProxyV2.getImplementation(), address(receivableV2));
    }

    function test_setLopoGlobals() public {
        assertEq(wrappedReceivableProxyV1.lopoGlobals(), address(wrappedLopoProxyV1));

        // since Receivable also have governor(), we use ReceivableV1 to pretend new LopoGlobals
        address mockLopoGlobals = address(wrappedReceivableProxyV1);
        vm.expectEmit(true, true, true, true);
        emit LopoGlobalsSet(address(wrappedLopoProxyV1), mockLopoGlobals);
        vm.prank(wrappedReceivableProxyV1.governor());
        wrappedReceivableProxyV1.setLopoGlobals(mockLopoGlobals);
        assertEq(wrappedReceivableProxyV1.lopoGlobals(), mockLopoGlobals);
    }

    function test_governor() public {
        assertEq(wrappedReceivableProxyV1.governor(), GOVERNOR);
    }
}

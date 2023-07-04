// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { PRBTest } from "@prb/test/PRBTest.sol";
import { console2 } from "forge-std/console2.sol";
import { StdCheats } from "forge-std/StdCheats.sol";

import { IERC20 } from "../interfaces/IERC20.sol";
import { ERC20 } from "../ERC20.sol";
import { MockERC20 } from "./mocks/MockERC20.sol";

contract ERC20BaseTest is PRBTest {
    address internal immutable self = address(this);

    bytes internal constant ARITHMETIC_ERROR = abi.encodeWithSignature("Panic(uint256)", 0x11);

    MockERC20 internal _token;

    function setUp() public virtual {
        _token = new MockERC20("Token", "TKN", 18);
    }

    function test_metadata() public {
        assertEq(_token.name(), "Token");
        assertEq(_token.symbol(), "TKN");
        assertEq(_token.decimals(), 18);
    }

    function testFuzz_metadata(string memory name_, string memory symbol_, uint8 decimals_) public {
        // vm.assume(bytes(name_).length > 0 && bytes(name_).length <= 256);
        // vm.assume(bytes(symbol_).length > 0 && bytes(symbol_).length <= 256);
        // vm.assume(decimals_ > 0 && decimals_ <= 18);

        MockERC20 token = new MockERC20(name_, symbol_, decimals_);

        assertEq(token.name(), name_);
        assertEq(token.symbol(), symbol_);
        assertEq(token.decimals(), decimals_);
    }

    function testFuzz_mint(address recipient_, uint256 amount_) public {
        vm.assume(recipient_ != address(0));

        _token.mint(recipient_, amount_);

        assertEq(_token.balanceOf(recipient_), amount_);
        assertEq(_token.totalSupply(), amount_);
    }

    function testFuzz_burn(address owner_, uint256 amount0_, uint256 amount1_) public {
        vm.assume(amount0_ > amount1_);
        vm.assume(owner_ != address(0));

        _token.mint(owner_, amount0_);
        _token.burn(owner_, amount1_);

        assertEq(_token.balanceOf(owner_), amount0_ - amount1_);
        assertEq(_token.totalSupply(), amount0_ - amount1_);
    }

    function testFuzz_approve(address account_, uint256 amount_) public {


    }

}









/*

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract FooTest is PRBTest, StdCheats {
    Foo internal foo;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Instantiate the contract-under-test.
        foo = new Foo();
    }

    /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    function test_Example() external {
        console2.log("Hello World");
        uint256 x = 42;
        assertEq(foo.id(x), x, "value mismatch");
    }

    /// @dev Fuzz test that provides random values for an unsigned integer, but which rejects zero as an input.
    /// If you need more sophisticated input validation, you should use the `bound` utility instead.
    /// See https://twitter.com/PaulRBerg/status/1622558791685242880
    function testFuzz_Example(uint256 x) external {
        vm.assume(x != 0); // or x = bound(x, 1, 100)
        assertEq(foo.id(x), x, "value mismatch");
    }

    /// @dev Fork test that runs against an Ethereum Mainnet fork. For this to work, you need to set `API_KEY_ALCHEMY`
    /// in your environment You can get an API key for free at https://alchemy.com.
    function testFork_Example() external {
        // Silently pass this test if there is no API key.
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        if (bytes(alchemyApiKey).length == 0) {
            return;
        }

        // Otherwise, run the test against the mainnet fork.
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 16_428_000 });
        address usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        address holder = 0x7713974908Be4BEd47172370115e8b1219F4A5f0;
        uint256 actualBalance = IERC20(usdc).balanceOf(holder);
        uint256 expectedBalance = 196_307_713.810457e6;
        assertEq(actualBalance, expectedBalance);
    }
}

*/

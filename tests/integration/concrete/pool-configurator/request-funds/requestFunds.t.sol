// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { Errors } from "contracts/libraries/Errors.sol";

import { PoolConfigurator_Integration_Shared_Test } from "../../../shared/pool-configurator/PoolConfigurator.t.sol";

contract RequestFunds_Integration_Concrete_Test is PoolConfigurator_Integration_Shared_Test {
    uint256 private _principal;

    modifier whenCoverIsSufficient() {
        changePrank(users.poolAdmin);
        poolConfigurator.depositCover(defaults.COVER_AMOUNT());
        _;
    }

    modifier whenPoolSupplyIsSufficient() {
        _;
    }

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        _principal = defaults.PRINCIPAL_REQUESTED();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ProtocolPaused() external {
        pauseProtoco();
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ContractPaused() external {
        pauseContract();
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_PoolConfiguratorPaused_FunctionPaused() external {
        pauseFunction(bytes4(keccak256("requestFunds(uint256)")));
        expectPoolConfiguratorPauseRevert();
    }

    function test_RevertWhen_CallerNotLoanManager() external whenFunctionNotPause {
        changePrank(users.eve);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.PoolConfigurator_CallerNotLoanManager.selector, address(loanManager), users.eve
            )
        );
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_RevertWhen_PoolSupplyZero() external whenFunctionNotPause {
        _drainThePool();

        changePrank({ msgSender: address(loanManager) });
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_PoolSupplyZero.selector));
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_RevertWhen_InsufficientCover()
        external
        whenFunctionNotPause
        whenCallerLoanManager
        whenPoolSupplyIsSufficient
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InsufficientCover.selector));
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_RevertWhen_InsufficientLiquidity()
        external
        whenFunctionNotPause
        whenCoverIsSufficient
        whenPoolSupplyIsSufficient
    {
        _createInsufficientLiquidityPool();

        changePrank({ msgSender: address(loanManager) });
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InsufficientLiquidity.selector));
        poolConfigurator.requestFunds({ principal_: 1 });
    }

    function test_requestFunds()
        external
        whenCoverIsSufficient
        whenFunctionNotPause
        whenCallerLoanManager
        whenPoolSupplyIsSufficient
    {
        expectCallToTransferFrom({ from: address(pool), to: address(loanManager), amount: _principal });
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function expectPoolConfiguratorPauseRevert() private {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_Paused.selector));
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function _drainThePool() internal {
        changePrank(users.receiver);
        pool.requestRedeem(defaults.POOL_SHARES(), users.receiver);
        vm.warp(defaults.WINDOW_3());
        pool.redeem(defaults.POOL_SHARES(), users.receiver, users.receiver);
    }

    /// @dev To create a insufficient liquidity pool
    /// step 1: Down size the pool, make the pool supply as default principal
    ///      2: Create loan, the default face amount is same as default principal
    ///      3: Seller withdraw fund
    ///      4: Receiver request redeem to increase locked shares
    function _createInsufficientLiquidityPool() internal {
        uint256 amount_ = defaults.POOL_SHARES() - _principal;

        // down size the pool
        changePrank(users.receiver);
        pool.requestRedeem(amount_, users.receiver);
        vm.warp(defaults.WINDOW_3());
        pool.redeem(amount_, users.receiver, users.receiver);

        // create loan
        createDefaultLoan();

        // seller withdraw fund
        changePrank(users.seller);
        IERC721(address(receivable)).approve(address(loanManager), defaults.RECEIVABLE_TOKEN_ID());
        loanManager.withdrawFunds(1, address(users.seller), _principal);

        // receiver request redeem
        changePrank(users.receiver);
        pool.requestRedeem(_principal, users.receiver);

        // move to the next redeemable window
        vm.warp(defaults.WINDOW_3() + 15 days);
    }
}

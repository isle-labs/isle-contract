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

    modifier whenLockedLiquidityIsSufficient() {
        _;
    }

    function setUp() public virtual override(PoolConfigurator_Integration_Shared_Test) {
        PoolConfigurator_Integration_Shared_Test.setUp();

        _principal = defaults.PRINCIPAL_REQUESTED();
    }

    function test_RevertWhen_PoolConfiguratorPaused_ProtocolPaused() external {
        pauseProtoco();
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_RevertWhen_PoolConfiguratorPaused_ContractPaused() external {
        pauseContract();
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_RevertWhen_PoolConfiguratorPaused_FunctionPaused() external {
        pauseFunction(bytes4(keccak256("requestFunds(uint256)")));
        poolConfigurator.requestFunds({ principal_: _principal });
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

    function test_RevertWhen_PoolSupplyIsZero() external whenFunctionNotPause {
        _defaultWithdraw(defaults.POOL_SHARES());

        changePrank({ msgSender: address(loanManager) });
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_PoolSupplyZero.selector));
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_RevertWhen_PoolCoverInsufficient()
        external
        whenFunctionNotPause
        whenCallerLoanManager
        whenPoolSupplyIsSufficient
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InsufficientCover.selector));
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function test_RevertWhen_LockedLiquidityInsufficient()
        external
        whenFunctionNotPause
        whenCoverIsSufficient
        whenPoolSupplyIsSufficient
    {
        _createInsufficientLockedLiquidity();

        changePrank({ msgSender: address(loanManager) });
        vm.expectRevert(abi.encodeWithSelector(Errors.PoolConfigurator_InsufficientLiquidity.selector));
        poolConfigurator.requestFunds({ principal_: 1 });
    }

    function test_RequestFunds()
        external
        whenCoverIsSufficient
        whenFunctionNotPause
        whenCallerLoanManager
        whenPoolSupplyIsSufficient
        whenLockedLiquidityIsSufficient
    {
        expectCallToTransferFrom({ from: address(pool), to: address(loanManager), amount: _principal });
        poolConfigurator.requestFunds({ principal_: _principal });
    }

    function _defaultWithdraw(uint256 withdrawAmount_) private {
        changePrank(users.receiver);
        pool.requestRedeem(withdrawAmount_, users.receiver);
        vm.warp(defaults.WINDOW_3());
        pool.redeem(withdrawAmount_, users.receiver, users.receiver);
    }

    /// @dev To create an insufficient locked liquidity
    /// step 1: Down size the pool, make the pool supply as default principal
    ///      2: Create loan, the default face amount is same as default principal
    ///      3: Seller withdraw fund
    ///      4: Receiver request redeem to increase locked shares
    function _createInsufficientLockedLiquidity() private {
        uint256 withdrawAmount_ = defaults.POOL_SHARES() - _principal;

        // down size the pool
        _defaultWithdraw(withdrawAmount_);

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

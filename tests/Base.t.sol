// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { StdCheats } from "@forge-std/StdCheats.sol";
import { console } from "@forge-std/console.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { UUPSProxy } from "../contracts/libraries/upgradability/UUPSProxy.sol";
import { Events } from "./utils/Events.sol";
import { Defaults } from "./utils/Defaults.sol";
import { Constants } from "./utils/Constants.sol";
import { Utils } from "./utils/Utils.sol";
import { Users } from "./utils/Types.sol";

// Mocks
import { MintableERC20WithPermit } from "./mocks/MintableERC20WithPermit.sol";

// interfaces
import { ILopoGlobals } from "../contracts/interfaces/ILopoGlobals.sol";
import { IReceivable } from "../contracts/interfaces/IReceivable.sol";
import { IPoolAddressesProvider } from "../contracts/interfaces/IPoolAddressesProvider.sol";
import { IPoolConfigurator } from "../contracts/interfaces/IPoolConfigurator.sol";
import { ILoanManager } from "../contracts/interfaces/ILoanManager.sol";
import { IWithdrawalManager } from "../contracts/interfaces/IWithdrawalManager.sol";
import { IPool } from "../contracts/interfaces/IPool.sol";

// storage
import { ReceivableStorage } from "../contracts/ReceivableStorage.sol";

// main contracts
import { LopoGlobals } from "../contracts/LopoGlobals.sol";
import { Receivable } from "../contracts/Receivable.sol";
import { PoolAddressesProvider } from "../contracts/PoolAddressesProvider.sol";
import { PoolConfigurator } from "../contracts/PoolConfigurator.sol";
import { LoanManager } from "../contracts/LoanManager.sol";
import { WithdrawalManager } from "../contracts/WithdrawalManager.sol";
import { Pool } from "../contracts/Pool.sol";

abstract contract Base_Test is StdCheats, Events, Constants, Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                    VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    /*//////////////////////////////////////////////////////////////////////////
                                TEST CONTRACTS
    //////////////////////////////////////////////////////////////////////////*/

    MintableERC20WithPermit internal usdc;
    Defaults internal defaults;

    // Lopo Globals UUPS contract
    LopoGlobals internal lopoGlobals;

    // Receivable UUPS contract
    Receivable internal receivable;

    // Transparent proxy contracts
    PoolAddressesProvider internal poolAddressesProvider; // Pool admin of the following contracts
    PoolConfigurator internal poolConfigurator;
    Pool internal pool;
    LoanManager internal loanManager;
    WithdrawalManager internal withdrawalManager;

    /*//////////////////////////////////////////////////////////////////////////
                                SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        usdc = new MintableERC20WithPermit("Circle USD", "USDC", ASSET_DECIMALS);

        // label contracts
        vm.label(address(usdc), "USDC");

        // create users for testing
        users = Users({
            governor: createUser("Governor"),
            poolAdmin: createUser("PoolAdmin"),
            seller: createUser("Seller"),
            buyer: createUser("Buyer"),
            caller: createUser("Caller"),
            staker: createAccount("Staker"),
            notStaker: createAccount("NotStaker"),
            receiver: createUser("Receiver"),
            notWhitelistedReceiver: createUser("notWhitelistedReceiver"),
            nullUser: createUser("nullUser")
        });

        // Deploy the defaults contract
        defaults = new Defaults();
        defaults.setAsset(usdc);
        defaults.setUsers(users);

        vm.warp({ timestamp: MAY_1_2023 });
        vm.startPrank(users.poolAdmin); // NOTE: Start prank so that change prank can work in the test suite
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Deploy all related lopo contracts
    function deployContracts() internal {
        deployReceivable();
        deployGlobals();
        deployPool();
    }

    /// @dev Deploy lopo Globals as an UUPS proxy
    function deployGlobals() internal {
        changePrank(users.governor);

        lopoGlobals = LopoGlobals(address(new UUPSProxy(address(new LopoGlobals()), "")));
        lopoGlobals.initialize(users.governor);
        vm.label(address(lopoGlobals), "LopoGlobals");

        // Quick setup for globals
        lopoGlobals.setValidPoolAdmin(users.poolAdmin, true);
        lopoGlobals.setValidPoolAsset(address(usdc), true);
        lopoGlobals.setValidCollateralAsset(address(receivable), true);
    }

    /// @dev Deploy receivable as an UUPS proxy
    function deployReceivable() internal {
        changePrank(users.governor);

        // notice here we use Receivable instead of its interface IReceivable, since we want to call function
        receivable = Receivable(address(new UUPSProxy(address(new Receivable()), "")));
        receivable.initialize(users.governor);
        vm.label(address(receivable), "Receivable");
    }

    /// @dev Deploy pool
    function deployPool() internal {
        changePrank(users.poolAdmin);

        poolAddressesProvider = new PoolAddressesProvider(users.poolAdmin, "BSOS Green Finance", address(lopoGlobals));

        deployPoolConfigurator();
        deployWithdrawalManager();
        deployLoanManager();

        poolConfigurator = PoolConfigurator(poolAddressesProvider.getPoolConfigurator());
        loanManager = LoanManager(poolAddressesProvider.getLoanManager());
        withdrawalManager = WithdrawalManager(poolAddressesProvider.getWithdrawalManager());
        pool = Pool(poolConfigurator.pool());

        vm.label(address(poolAddressesProvider), "PoolAddressesProvider");
        vm.label(address(poolConfigurator), "PoolConfigurator");
        vm.label(address(pool), "Pool");
        vm.label(address(loanManager), "LoanManager");
        vm.label(address(withdrawalManager), "WithdrawalManager");
    }

    /// @dev Deploy pool configurator
    function deployPoolConfigurator() internal {
        address poolConfigurator_ = address(new PoolConfigurator(poolAddressesProvider));
        bytes memory params_ = abi.encodeWithSelector(
            IPoolConfigurator.initialize.selector,
            address(poolAddressesProvider),
            users.poolAdmin,
            address(usdc),
            "BSOS Green Share",
            "BGS"
        );
        poolAddressesProvider.setPoolConfiguratorImpl(poolConfigurator_, params_);
    }

    /// @dev Deploy withdrawal manager
    function deployWithdrawalManager() internal {
        address withdrawalManager_ = address(new WithdrawalManager(poolAddressesProvider));

        bytes memory params = abi.encodeWithSelector(
            IWithdrawalManager.initialize.selector,
            address(poolAddressesProvider),
            defaults.CYCLE_DURATION(),
            defaults.WINDOW_DURATION()
        );
        poolAddressesProvider.setWithdrawalManagerImpl(withdrawalManager_, params);
    }

    /// @dev Deploy loan manager
    function deployLoanManager() internal {
        address loanManager_ = address(new LoanManager(poolAddressesProvider));
        poolAddressesProvider.setLoanManagerImpl(loanManager_);
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

    /// @dev Airdrops a specified amount of usdc to a recipient
    function airdropTo(address recipient_, uint256 amount_) internal {
        usdc.mint({ recipient_: recipient_, amount_: amount_ });
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

    function approveProtocol() internal {
        changePrank(users.caller);
        usdc.approve(address(pool), type(uint256).max);

        changePrank(users.receiver);
        usdc.approve(address(pool), type(uint256).max);

        changePrank(users.buyer);
        usdc.approve(address(loanManager), type(uint256).max);
    }

    function callerDepositToReceiver(address caller, address receiver, uint256 amount) internal {
        changePrank(caller);
        pool.deposit(amount, receiver);
    }

    function callerMintToReceiver(address caller, address receiver, uint256 amount) internal {
        changePrank(caller);
        pool.mint(amount, receiver);
    }

    function createReceivable(uint256 faceAmount_) internal returns (uint256 receivablesTokenId_) {
        changePrank(users.buyer);
        receivablesTokenId_ = receivable.createReceivable(
            users.buyer, users.seller, ud(faceAmount_), defaults.MAY_31_2023(), defaults.CURRENCY_CODE()
        );
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

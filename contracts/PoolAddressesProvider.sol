// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Errors } from "./libraries/Errors.sol";

import { IIsleGlobals } from "./interfaces/IIsleGlobals.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";

import { PoolConfigurator } from "./PoolConfigurator.sol";
import { LoanManager } from "./LoanManager.sol";
import { WithdrawalManager } from "./WithdrawalManager.sol";

contract PoolAddressesProvider is IPoolAddressesProvider {
    string private _marketId;

    mapping(bytes32 => address) private _addresses;

    bytes32 private constant POOL_CONFIGURATOR = "POOL_CONFIGURATOR";
    bytes32 private constant ISLE_GLOBALS = "ISLE_GLOBALS";
    bytes32 private constant LOAN_MANAGER = "LOAN_MANAGER";
    bytes32 private constant WITHDRAWAL_MANAGER = "WITHDRAWAL_MANAGER";

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyGovernor() {
        address governor_ = IIsleGlobals(getAddress(ISLE_GLOBALS)).governor();
        if (msg.sender != governor_) {
            revert Errors.CallerNotGovernor({ governor_: governor_, caller_: msg.sender });
        }
        _;
    }

    constructor(string memory marketId_, IIsleGlobals globals_) {
        if (globals_.governor() == address(0)) {
            revert Errors.PoolAddressesProvider_InvalidGlobals(address(globals_));
        }

        _addresses[ISLE_GLOBALS] = address(globals_);
        _marketId = marketId_;
    }

    function getMarketId() external view override returns (string memory marketId_) {
        marketId_ = _marketId;
    }

    function setMarketId(string memory newMarketId_) external override onlyGovernor {
        _setMarketId(newMarketId_);
    }

    /*//////////////////////////////////////////////////////////////
                            PROXY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolAddressesProvider
    function getPoolConfigurator() external view override returns (address) {
        return getAddress(POOL_CONFIGURATOR);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setPoolConfiguratorImpl(bytes calldata params) external override onlyGovernor {
        address oldPoolConfiguratorImpl = _getProxyImplementation(POOL_CONFIGURATOR);
        address newPoolConfiguratorImpl = address(new PoolConfigurator(this));
        _updateImpl(POOL_CONFIGURATOR, newPoolConfiguratorImpl, params);
        emit PoolConfiguratorUpdated(oldPoolConfiguratorImpl, newPoolConfiguratorImpl);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getLoanManager() external view override returns (address) {
        return getAddress(LOAN_MANAGER);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setLoanManagerImpl(bytes calldata params) external override onlyGovernor {
        address oldLoanManagerImpl = _getProxyImplementation(LOAN_MANAGER);
        address newLoanManagerImpl = address(new LoanManager(this));
        _updateImpl(LOAN_MANAGER, newLoanManagerImpl, params);
        emit LoanManagerUpdated(oldLoanManagerImpl, newLoanManagerImpl);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getWithdrawalManager() external view override returns (address) {
        return getAddress(WITHDRAWAL_MANAGER);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setWithdrawalManagerImpl(bytes calldata params) external override onlyGovernor {
        address oldWithdrawalManagerImpl = _getProxyImplementation(WITHDRAWAL_MANAGER);
        address newWithdrawalManagerImpl = address(new WithdrawalManager(this));
        _updateImpl(WITHDRAWAL_MANAGER, newWithdrawalManagerImpl, params);
        emit WithdrawalManagerUpdated(oldWithdrawalManagerImpl, newWithdrawalManagerImpl);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setAddressAsProxy(
        bytes32 id,
        address newImplementationAddress,
        bytes calldata params
    )
        external
        override
        onlyGovernor
    {
        address proxyAddress = _addresses[id];
        address oldImplementationAddress = _getProxyImplementation(id);
        _updateImpl(id, newImplementationAddress, params);
        emit AddressSetAsProxy(id, proxyAddress, oldImplementationAddress, newImplementationAddress);
    }

    /*//////////////////////////////////////////////////////////////
                          NON-PROXY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolAddressesProvider
    function getIsleGlobals() external view override returns (address) {
        return getAddress(ISLE_GLOBALS);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setIsleGlobals(address newIsleGlobals) external override onlyGovernor {
        address oldIsleGlobals = _addresses[ISLE_GLOBALS];
        _addresses[ISLE_GLOBALS] = newIsleGlobals;
        emit IsleGlobalsUpdated(oldIsleGlobals, newIsleGlobals);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    /// @inheritdoc IPoolAddressesProvider
    function setAddress(bytes32 id, address newAddress) external override onlyGovernor {
        address oldAddress = _addresses[id];
        _addresses[id] = newAddress;
        emit AddressSet(id, oldAddress, newAddress);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal function to update the implementation of a specific proxied component of the protocol.
    /// @param id The id of the proxy to be updated
    /// @param newAddress The address of the new implementation
    /// @param params The params is used as data in a delegate call to `newAddress`
    function _updateImpl(bytes32 id, address newAddress, bytes memory params) internal {
        address proxyAddress = _addresses[id];

        if (proxyAddress == address(0)) {
            TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(newAddress, address(this), params);
            _addresses[id] = proxyAddress = address(proxy);
            emit ProxyCreated(id, proxyAddress, newAddress);
        } else {
            ITransparentUpgradeableProxy Iproxy = ITransparentUpgradeableProxy(payable(proxyAddress));
            if (params.length > 0) {
                Iproxy.upgradeToAndCall(newAddress, params);
            } else {
                Iproxy.upgradeTo(newAddress);
            }
        }
    }

    /// @notice Updates the identifier of the Isle market.
    /// @param newMarketId The new id of the market
    function _setMarketId(string memory newMarketId) internal {
        string memory oldMarketId = _marketId;
        _marketId = newMarketId;
        emit MarketIdSet(oldMarketId, newMarketId);
    }

    /// @notice Returns the the implementation contract of the proxy contract by its identifier.
    /// @dev It returns ZERO if there is no registered address with the given id
    /// @dev It reverts if the registered address with the given id is not
    /// `InitializableImmutableAdminUpgradeabilityProxy`
    /// @param id The id
    /// @return The address of the implementation contract
    function _getProxyImplementation(bytes32 id) internal view returns (address) {
        address proxyAddress = _addresses[id];
        if (proxyAddress == address(0)) {
            return address(0);
        } else {
            address payable payableProxyAddress = payable(proxyAddress);
            return ITransparentUpgradeableProxy(payableProxyAddress).implementation();
        }
    }
}

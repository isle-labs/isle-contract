// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Adminable } from "./abstracts/Adminable.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";
import { IPoolConfigurator } from "./interfaces/IPoolConfigurator.sol";
import { ILoanManager } from "./interfaces/ILoanManager.sol";
import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";

contract PoolAddressesProvider is Adminable, IPoolAddressesProvider {
    string private _marketId;

    mapping(bytes32 => address) private _addresses;

    bytes32 private constant POOL = "POOL";
    bytes32 private constant POOL_CONFIGURATOR = "POOL_CONFIGURATOR";
    bytes32 private constant LOPO_GLOBALS = "LOPO_GLOBALS";
    bytes32 private constant LOAN_MANAGER = "LOAN_MANAGER";
    bytes32 private constant WITHDRAWAL_MANAGER = "WITHDRAWAL_MANAGER";

    constructor(string memory marketId_, address initialAdmin_) {
        admin = initialAdmin_;
        _marketId = marketId_;
    }

    function getMarketId() external view returns (string memory) {
        return _marketId;
    }

    function setMarketId(string memory newMarketId_) external onlyAdmin {
        _marketId = newMarketId_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    Proxied
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolAddressesProvider
    function getPoolConfigurator() external view override returns (address) {
        return getAddress(POOL_CONFIGURATOR);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setPoolConfiguratorImpl(
        address newPoolConfiguratorImpl,
        bytes calldata params
    )
        external
        override
        onlyAdmin
    {
        address oldPoolConfiguratorImpl = _getProxyImplementation(POOL_CONFIGURATOR);
        _updateImpl(POOL_CONFIGURATOR, newPoolConfiguratorImpl, params);
        emit PoolConfiguratorUpdated(oldPoolConfiguratorImpl, newPoolConfiguratorImpl);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getLoanManager() external view override returns (address) {
        return getAddress(LOAN_MANAGER);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setLoanManagerImpl(address newLoanManagerImpl) external override onlyAdmin {
        address oldLoanManagerImpl = _getProxyImplementation(LOAN_MANAGER);
        _updateImpl(LOAN_MANAGER, newLoanManagerImpl);
        emit LoanManagerUpdated(oldLoanManagerImpl, newLoanManagerImpl);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getWithdrawalManager() external view override returns (address) {
        return getAddress(WITHDRAWAL_MANAGER);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setWithdrawalManagerImpl(
        address newWithdrawalManagerImpl,
        bytes calldata params
    )
        external
        override
        onlyAdmin
    {
        address oldWithdrawalManagerImpl = _getProxyImplementation(WITHDRAWAL_MANAGER);
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
        onlyAdmin
    {
        address proxyAddress = _addresses[id];
        address oldImplementationAddress = _getProxyImplementation(id);
        _updateImpl(id, newImplementationAddress, params);
        emit AddressSetAsProxy(id, proxyAddress, oldImplementationAddress, newImplementationAddress);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Not Proxied
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolAddressesProvider
    function getIsleGlobals() external view override returns (address) {
        return getAddress(LOPO_GLOBALS);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setIsleGlobals(address newIsleGlobals) external override onlyAdmin {
        address oldIsleGlobals = _addresses[LOPO_GLOBALS];
        _addresses[LOPO_GLOBALS] = newIsleGlobals;
        emit IsleGlobalsUpdated(oldIsleGlobals, newIsleGlobals);
    }

    /// @inheritdoc IPoolAddressesProvider
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    /// @inheritdoc IPoolAddressesProvider
    function setAddress(bytes32 id, address newAddress) external override onlyAdmin {
        address oldAddress = _addresses[id];
        _addresses[id] = newAddress;
        emit AddressSet(id, oldAddress, newAddress);
    }

    /// @notice Internal function to update the implementation of a specific proxied component of the protocol.
    /// @dev If there is no proxy registered with the given identifier, it creates the proxy setting `newAddress`
    ///   as implementation and calls the initialize() function on the proxy
    /// @dev If there is already a proxy registered, it just updates the implementation to `newAddress` and
    ///   calls the initialize() function via upgradeToAndCall() in the proxy
    /// @param id The id of the proxy to be updated
    /// @param newAddress The address of the new implementation
    function _updateImpl(bytes32 id, address newAddress) internal {
        _updateImpl(id, newAddress, abi.encodeWithSignature("initialize(address)", address(this)));
    }

    function _updateImpl(bytes32 id, address newAddress, bytes memory params) internal {
        address proxyAddress = _addresses[id];
        TransparentUpgradeableProxy proxy;
        ITransparentUpgradeableProxy Iproxy;

        if (proxyAddress == address(0)) {
            proxy = new TransparentUpgradeableProxy(newAddress, address(this), params);
            _addresses[id] = proxyAddress = address(proxy);
            emit ProxyCreated(id, proxyAddress, newAddress);
        } else {
            Iproxy = ITransparentUpgradeableProxy(payable(proxyAddress));
            Iproxy.upgradeToAndCall(newAddress, params);
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

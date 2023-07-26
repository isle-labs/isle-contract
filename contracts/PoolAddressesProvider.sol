// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { ITransparentUpgradeableProxy, TransparentUpgradeableProxy } from "@openzeppelin/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Adminable } from "./abstracts/Adminable.sol";
import { IPoolAddressesProvider } from "./interfaces/IPoolAddressesProvider.sol";

contract PoolAddressesProvider is Adminable, IPoolAddressesProvider {
    string private _marketId;

    mapping(bytes32 => address) private _addresses;

    bytes32 private constant POOL = "POOL";
    bytes32 private constant POOL_CONFIGURATOR = "POOL_CONFIGURATOR";
    bytes32 private constant LOPO_GLOBALS = "LOPO_GLOBALS";
    bytes32 private constant LOAN_MANAGER = "LOAN_MANAGER";
    bytes32 private constant WITHDRAWAL_MANAGER = "WITHDRAWAL_MANAGER";
    bytes32 private constant PRICE_ORACLE = "PRICE_ORACLE";

    constructor(string memory marketId_, address owner_) {
        _marketId = marketId_;
        transferAdmin(owner_);
    }

    function getMarketId() external view returns (string memory) {
        return _marketId;
    }

    function setMarketId(string memory newMarketId_) external onlyAdmin {
        _marketId = newMarketId_;
    }

    /// @inheritdoc IPoolAddressesProvider
    function setAddressAsProxy(bytes32 id, address newImplementationAddress) external override onlyAdmin {
        address proxyAddress = _addresses[id];
        address oldImplementationAddress = _getProxyImplementation(id);
        _updateImpl(id, newImplementationAddress);
        emit AddressSetAsProxy(id, proxyAddress, oldImplementationAddress, newImplementationAddress);
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
        address asset,
        string memory name,
        string memory symbol
    ) external override onlyAdmin {
        address oldPoolConfiguratorImpl = _getProxyImplementation(POOL_CONFIGURATOR);

        bytes memory params = abi.encodeWithSignature(
            "initialize(address,address,string,string)",
            address(this),
            asset,
            name,
            symbol
        );

        _updateImpl(POOL_CONFIGURATOR, newPoolConfiguratorImpl, params);
        emit PoolConfiguratorUpdated(oldPoolConfiguratorImpl, newPoolConfiguratorImpl);
    }

    function getLoanManager() external view override returns (address) {
        return getAddress(LOAN_MANAGER);
    }

    function setLoanManagerImpl(address newLoanManagerImpl) external override onlyAdmin {
        address oldLoanManagerImpl = _getProxyImplementation(LOAN_MANAGER);
        _updateImpl(LOAN_MANAGER, newLoanManagerImpl);
        emit LoanManagerUpdated(oldLoanManagerImpl, newLoanManagerImpl);
    }

    function getWithdrawalManager() external view override returns (address) {
        return getAddress(WITHDRAWAL_MANAGER);
    }

    function setWithdrawalManagerImpl(address newWithdrawalManagerImpl) external override onlyAdmin {
        address oldWithdrawalManagerImpl = _getProxyImplementation(WITHDRAWAL_MANAGER);
        _updateImpl(WITHDRAWAL_MANAGER, newWithdrawalManagerImpl);
        emit WithdrawalManagerUpdated(oldWithdrawalManagerImpl, newWithdrawalManagerImpl);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                Not Proxied
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPoolAddressesProvider
    function getPriceOracle() external view override returns (address) {
        return getAddress(PRICE_ORACLE);
    }

    /// @inheritdoc IPoolAddressesProvider
    function setPriceOracle(address newPriceOracle) external override onlyAdmin {
        address oldPriceOracle = _addresses[PRICE_ORACLE];
        _addresses[PRICE_ORACLE] = newPriceOracle;
        emit PriceOracleUpdated(oldPriceOracle, newPriceOracle);
    }

    function getLopoGlobals() external view override returns (address) {
        return getAddress(LOPO_GLOBALS);
    }

    function setLopoGlobals(address newLopoGlobals) external override onlyAdmin {
        address oldLopoGlobals = _addresses[LOPO_GLOBALS];
        _addresses[LOPO_GLOBALS] = newLopoGlobals;
        emit LopoGlobalsUpdated(oldLopoGlobals, newLopoGlobals);
    }

    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    function setAddress(bytes32 id, address newAddress) external override onlyAdmin {
        address oldAddress = _addresses[id];
        _addresses[id] = newAddress;
        emit AddressSet(id, oldAddress, newAddress);
    }

    /**
     * @notice Internal function to update the implementation of a specific proxied component of the protocol.
     * @dev If there is no proxy registered with the given identifier, it creates the proxy setting `newAddress`
     *   as implementation and calls the initialize() function on the proxy
     * @dev If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     */
    function _updateImpl(bytes32 id, address newAddress) internal {
        _updateImpl(id, newAddress, abi.encodeWithSignature("initialize(address)", address(this)));
    }

    // Function overloading to support upgrades with custom params
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

    /**
     * @notice Updates the identifier of the Lopo market.
     * @param newMarketId The new id of the market
     */
    function _setMarketId(string memory newMarketId) internal {
        string memory oldMarketId = _marketId;
        _marketId = newMarketId;
        emit MarketIdSet(oldMarketId, newMarketId);
    }

    /**
     * @notice Returns the the implementation contract of the proxy contract by its identifier.
     * @dev It returns ZERO if there is no registered address with the given id
     * @dev It reverts if the registered address with the given id is not `InitializableImmutableAdminUpgradeabilityProxy`
     * @param id The id
     * @return The address of the implementation contract
     */
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

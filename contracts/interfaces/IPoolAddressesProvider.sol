// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/// @title IPoolAddressesProvider
/// @notice Defines the basic interface for a Pool Addresses Provider.
interface IPoolAddressesProvider {
    /// @dev Emitted when the market identifier is changed.
    /// @param oldMarketId The previous identifier of the market.
    /// @param newMarketId The new identifier of the market.
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /// @dev Emitted when the address of the PoolConfigurator is updated.
    /// @param oldAddress The former address of the PoolConfigurator.
    /// @param newAddress The updated address of the PoolConfigurator.
    event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when the address of the LoanManager is updated.
    /// @param oldAddress The former address of the LoanManager.
    /// @param newAddress The updated address of the LoanManager.
    event LoanManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when the address of the WithdrawalManager is updated.
    /// @param oldAddress The former address of the WithdrawalManager.
    /// @param newAddress The updated address of the WithdrawalManager.
    event WithdrawalManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when the address of IsleGlobals is updated.
    /// @param oldAddress The former address of IsleGlobals.
    /// @param newAddress The updated address of IsleGlobals.
    event IsleGlobalsUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when a new proxy is created for a contract.
    /// @param id The identifier of the contract.
    /// @param proxyAddress The address of the newly created proxy contract.
    /// @param implementationAddress The address of the implementation contract linked to the proxy.
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /// @dev Emitted when a new address is registered for a contract without a proxy.
    /// @param id The identifier of the contract.
    /// @param oldAddress The former address of the contract.
    /// @param newAddress The newly registered address of the contract.
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when the implementation of a registered proxy is updated.
    /// @param id The identifier of the contract.
    /// @param proxyAddress The address of the proxy contract.
    /// @param oldImplementationAddress The former address of the implementation contract.
    /// @param newImplementationAddress The updated address of the implementation contract.
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /// @notice Retrieves the identifier of the Isle market associated with this contract.
    /// @return The identifier of the market.
    function getMarketId() external view returns (string memory);

    /// @notice Links a new market identifier to this PoolAddressesProvider.
    /// @dev Useful for creating a registry of PoolAddressesProviders for multiple Isle markets.
    /// @param newMarketId The new market identifier.
    function setMarketId(string calldata newMarketId) external;

    /// @notice Fetches an address associated with a given identifier.
    /// @dev Can return either a direct contract address or a proxy address.
    /// @dev Returns address(0) if no address is registered with the given identifier.
    /// @param id The identifier of the contract to retrieve.
    /// @return The address associated with the specified identifier.
    function getAddress(bytes32 id) external view returns (address);

    /// @notice Updates or initializes a proxy for a given identifier with a new implementation address.
    /// @dev Use with caution for identifiers without dedicated setter functions to prevent unintended effects.
    /// @dev Only use for identifiers POOL_CONFIGURATOR, LOAN_MANAGER, WITHDRAWAL_MANAGER, or ISLE_GLOBALS.
    /// @param id The identifier of the contract to update.
    /// @param newImplementationAddress The address of the new implementation.
    /// @param params The initialization parameters for the proxy contract.
    function setAddressAsProxy(bytes32 id, address newImplementationAddress, bytes calldata params) external;

    /// @notice Directly sets a new address for a given identifier, replacing the current address.
    /// @dev Use with caution as this will overwrite the existing address without any checks.
    /// @dev Only use for identifiers POOL_CONFIGURATOR, LOAN_MANAGER, WITHDRAWAL_MANAGER, or ISLE_GLOBALS.
    /// @param id The identifier for which to set the address.
    /// @param newAddress The new address to associate with the identifier.
    function setAddress(bytes32 id, address newAddress) external;

    /// @notice Retrieves the address of the PoolConfigurator proxy.
    /// @return The address of the PoolConfigurator proxy.
    function getPoolConfigurator() external view returns (address);

    /// @notice Sets or initializes the PoolConfigurator proxy with a new implementation.
    /// @param newPoolConfiguratorImpl The address of the new PoolConfigurator implementation.
    /// @param params The initialization parameters for the PoolConfigurator.
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl, bytes calldata params) external;

    /// @notice Retrieves the address of the LoanManager proxy.
    /// @return The address of the LoanManager proxy.
    function getLoanManager() external view returns (address);

    /// @notice Sets or initializes the LoanManager proxy with a new implementation.
    /// @param newLoanManagerImpl The address of the new LoanManager implementation.
    /// @param params The initialization parameters for the LoanManager.
    function setLoanManagerImpl(address newLoanManagerImpl, bytes calldata params) external;

    /// @notice Retrieves the address of the WithdrawalManager proxy.
    /// @return The address of the WithdrawalManager proxy.
    function getWithdrawalManager() external view returns (address);

    /// @notice Sets or initializes the WithdrawalManager proxy with a new implementation.
    /// @param newWithdrawalManagerImpl The address of the new WithdrawalManager implementation.
    /// @param params The initialization parameters for the WithdrawalManager.
    function setWithdrawalManagerImpl(address newWithdrawalManagerImpl, bytes calldata params) external;

    /// @notice Retrieves the address of IsleGlobals.
    /// @return The address of IsleGlobals.
    function getIsleGlobals() external view returns (address);

    /// @notice Sets a new address for IsleGlobals, replacing the current address in the registry.
    /// @param newIsleGlobals The new address for IsleGlobals.
    function setIsleGlobals(address newIsleGlobals) external;
}

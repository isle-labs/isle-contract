// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

/// @title IPoolAddressesProvider
/// @notice Defines the basic interface for a Pool Addresses Provider.
interface IPoolAddressesProvider {
    /// @dev Emitted when the market identifier is updated.
    /// @param oldMarketId The old id of the market
    /// @param newMarketId The new id of the market
    event MarketIdSet(string indexed oldMarketId, string indexed newMarketId);

    /// @dev Emitted when the pool is updated.
    /// @param oldAddress The old address of the Pool
    /// @param newAddress The new address of the Pool
    event PoolUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when the pool configurator is updated.
    /// @param oldAddress The old address of the PoolConfigurator
    /// @param newAddress The new address of the PoolConfigurator
    event PoolConfiguratorUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when the loan manager is updated.
    /// @param oldAddress The old address of the loan manager
    /// @param newAddress The new address of the loan manager
    event LoanManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when the withdrawal manager is updated.
    /// @param oldAddress The old address of the withdrawal manager
    /// @param newAddress The new address of the withdrawal manager
    event WithdrawalManagerUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when lopo globals is updated.
    /// @param oldAddress The old address of lopo globals
    /// @param newAddress The new address of lopo globals
    event LopoGlobalsUpdated(address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when a new proxy is created.
    /// @param id The identifier of the proxy
    /// @param proxyAddress The address of the created proxy contract
    /// @param implementationAddress The address of the implementation contract
    event ProxyCreated(bytes32 indexed id, address indexed proxyAddress, address indexed implementationAddress);

    /// @dev Emitted when a new non-proxied contract address is registered.
    /// @param id The identifier of the contract
    /// @param oldAddress The address of the old contract
    /// @param newAddress The address of the new contract
    event AddressSet(bytes32 indexed id, address indexed oldAddress, address indexed newAddress);

    /// @dev Emitted when the implementation of the proxy registered with id is updated
    /// @param id The identifier of the contract
    /// @param proxyAddress The address of the proxy contract
    /// @param oldImplementationAddress The address of the old implementation contract
    /// @param newImplementationAddress The address of the new implementation contract
    event AddressSetAsProxy(
        bytes32 indexed id,
        address indexed proxyAddress,
        address oldImplementationAddress,
        address indexed newImplementationAddress
    );

    /// @notice Returns the id of the Aave market to which this contract points to.
    /// @return The market id
    function getMarketId() external view returns (string memory);

    /// @notice Associates an id with a specific PoolAddressesProvider.
    /// @dev This can be used to create an onchain registry of PoolAddressesProviders to
    /// identify and validate multiple Aave markets.
    /// @param newMarketId The market id
    function setMarketId(string calldata newMarketId) external;

    /// @notice Returns an address by its identifier.
    /// @dev The returned address might be an EOA or a contract, potentially proxied
    /// @dev It returns ZERO if there is no registered address with the given id
    /// @param id The id
    /// @return The address of the registered for the specified id
    function getAddress(bytes32 id) external view returns (address);

    /// @notice General function to update the implementation of a proxy registered with
    /// certain `id`. If there is no proxy registered, it will instantiate one and
    /// set as implementation the `newImplementationAddress`.
    /// @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
    /// setter function, in order to avoid unexpected consequences
    /// @param id The id
    /// @param newImplementationAddress The address of the new implementation
    /// @param params The intialization parameters for the proxied contract
    function setAddressAsProxy(bytes32 id, address newImplementationAddress, bytes calldata params) external;

    /// @notice Sets an address for an id replacing the address saved in the addresses map.
    /// @dev IMPORTANT Use this function carefully, as it will do a hard replacement
    /// @param id The id
    /// @param newAddress The address to set
    function setAddress(bytes32 id, address newAddress) external;

    /// @notice Returns the address of the PoolConfigurator proxy.
    /// @return The PoolConfigurator proxy address
    function getPoolConfigurator() external view returns (address);

    /// @notice Updates the implementation of the PoolConfigurator, or creates a proxy
    /// setting the new `PoolConfigurator` implementation when the function is called for the first time.
    /// @param newPoolConfiguratorImpl The new PoolConfigurator implementation
    function setPoolConfiguratorImpl(address newPoolConfiguratorImpl, bytes calldata params) external;

    /// @notice Returns the address of the LoanManager proxy.
    /// @return The LoanManager proxy address
    function getLoanManager() external view returns (address);

    /// @notice Updates the implementation of the LoanManager, or creates a proxy
    /// setting the new `LoanManager` implementation when the function is called for the first time.
    /// @param newLoanManagerImpl The new LoanManager implementation
    function setLoanManagerImpl(address newLoanManagerImpl) external;

    /// @notice Returns the address of the WithdrawalManager proxy.
    /// @return The WithdrawalManager proxy address
    function getWithdrawalManager() external view returns (address);

    /// @notice Updates the implementation of the WithdrawalManager, or creates a proxy
    /// setting the new `WithdrawalManager` implementation when the function is called for the first time.
    /// @param newWithdrawalManagerImpl The new WithdrawalManager implementation
    function setWithdrawalManagerImpl(address newWithdrawalManagerImpl, bytes calldata params) external;

    /// @notice Returns the address of lopo globals.
    /// @return The LopoGlobals address
    function getLopoGlobals() external view returns (address);

    /// @notice Sets an address for LopoGlobals replacing the address saved in the addresses map
    /// @param newLopoGlobals LopoGlobals address
    function setLopoGlobals(address newLopoGlobals) external;
}

#!/usr/bin/env bash

# Pre-requisites:
# - foundry (https://getfoundry.sh)
# - pnpm (https://pnpm.io)

# Strict mode: https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
set -euo pipefail

# Delete the current artifacts
artifacts=./artifacts
rm -rf $artifacts

# Create the new artifacts directories
mkdir $artifacts \
  "$artifacts/interfaces" \
  "$artifacts/interfaces/erc20" \
  "$artifacts/interfaces/erc721" \
  "$artifacts/interfaces/hooks" \
  "$artifacts/libraries"

# Generate the artifacts with Forge
forge build

# Copy the production artifacts
cp out/Pool.sol/Pool.json $artifacts
cp out/PoolConfigurator.sol/PoolConfigurator.json $artifacts
cp out/LoanManager.sol/LoanManager.json $artifacts
cp out/WithdrawalManager.sol/WithdrawalManager.json $artifacts
cp out/IsleGlobals.sol/IsleGlobals.json $artifacts
cp out/PoolAddressesProvider.sol/PoolAddressesProvider.json $artifacts
cp out/Receivable.sol/Receivable.json $artifacts

interfaces=./artifacts/interfaces
cp out/IPool.sol/IPool.json $interfaces
cp out/IPoolConfigurator.sol/IPoolConfigurator.json $interfaces
cp out/ILoanManager.sol/ILoanManager.json $interfaces
cp out/IWithdrawalManager.sol/IWithdrawalManager.json $interfaces
cp out/IIsleGlobals.sol/IIsleGlobals.json $interfaces
cp out/IPoolAddressesProvider.sol/IPoolAddressesProvider.json $interfaces
cp out/IReceivable.sol/IReceivable.json $interfaces

erc20=./artifacts/interfaces/erc20
cp out/IERC20.sol/IERC20.json $erc20
cp out/IERC20Metadata.sol/IERC20Metadata.json $erc20

erc721=./artifacts/interfaces/erc721
cp out/IERC721.sol/IERC721.json $erc721
cp out/IERC721MetadataUpgradeable.sol/IERC721MetadataUpgradeable.json $erc721

libraries=./artifacts/libraries
cp out/Errors.sol/Errors.json $libraries

# Format the artifacts with Prettier
pnpm prettier --write ./artifacts

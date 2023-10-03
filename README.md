# Lopo Protocol

[![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry]

[gha]: https://github.com/bsostech/lopo-protocol/actions
[gha-badge]: https://github.com/bsostech/lopo-protocol/actions/workflows/ci.yml/badge.svg
[codecov]: https://codecov.io/gh/bsostech/lopo-protocol
[codecov-badge]: https://codecov.io/gh/bsostech/lopo-protocol/graph/badge.svg?token=MZCPLVNMTH
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

This repository contains the core smart contracts for the Lopo Protocol. In-depth documentation is available at [docs.lopo.finance](https://docs.lopo.finance)

## Getting Started

0. If you are on VS Code, install Nomicfoundation/hardhat-solidity or JuanBlanco/solidity (select one for solidity) and
   Tamasfe/even-better-toml as extensions.
   ([Learn more](https://book.getfoundry.sh/config/vscode#integrating-with-vscode))

1. Install [Forge](https://book.getfoundry.sh/getting-started/installation) and [pnpm](https://pnpm.io/installation)

2. Install npm packages

    ```sh
    pnpm install
    ```

3. Install foundry libraries

    ```sh
    forge install
    ```

## Architecture

Lopo Protocol is a designed where each pool will be a set of contracts

- `PoolAddressesProvider`
- `LoanManager`
- `WithdrawalManager`
- `PoolConfigurator`
- `Pool`

That is to say, each pool will have its own set of contracts so as to maximize customisability for pool admins. Please see the following [diagrams](https://docs.lopo.finance/technical-resources/diagrams) to have a better view of the design and flow.

## Usage

This is a list of the most frequently needed commands.

### Build

Build the contracts:

```sh
$ forge build
```

### Clean

Delete the build artifacts and cache directories:

```sh
$ forge clean
```

### Compile

Compile the contracts:

```sh
$ forge build
```

### Coverage

Get a test coverage report:

```sh
$ forge coverage
```

Get a .lcov coverage report

```sh
$ forge coverage --report lcov
```

### Deploy

Deploy to Anvil:

```sh
$ forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

For this script to work, you need to have a `MNEMONIC` environment variable set to a valid
[BIP39 mnemonic](https://iancoleman.io/bip39/).

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html) tutorial.

### Format

Format the contracts:

```sh
$ forge fmt
```

### Gas Usage

Get a gas report:

```sh
$ forge test --gas-report
```

### Lint

Lint the contracts:

```sh
$ pnpm lint
```

### Test

Run the tests:

```sh
$ forge test
```

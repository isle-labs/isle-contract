# Isle Protocol

[![Github Actions][gha-badge]][gha] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry]

[gha]: https://github.com/bsostech/isle/actions
[gha-badge]: https://github.com/bsostech/isle/actions/workflows/ci.yml/badge.svg
[codecov]: https://codecov.io/gh/bsostech/isle
[codecov-badge]: https://codecov.io/gh/bsostech/isle/graph/badge.svg?token=MZCPLVNMTH
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

This repository contains the core smart contracts for the Isle Protocol. In-depth documentation is available at [docs.isle.finance](https://docs.isle.finance)

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

Isle Protocol is a designed where each pool will be a set of contracts

- `PoolAddressesProvider`
- `LoanManager`
- `WithdrawalManager`
- `PoolConfigurator`
- `Pool`

That is to say, each pool will have its own set of contracts so as to maximize customisability for pool admins. Please see the following [diagrams](https://docs.isle.finance/technical-resources/diagrams) to have a better view of the design and flow.

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

### Gas snapshot

```sh
$ forge snapshot
```

### Gas report

```sh
$ pnpm gas-report
```

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

### Scripts

View balance of address
```sh
cast balance --rpc-url "sepolia" -e $ADDRESS
```

Send ETH to another address

```sh
cast send $ADDRESS --rpc-url "sepolia" --value 0.1ether --private-key $PRIV_KEY
```

Run deploy scripts

```sh
forge script scripts/DeployERC20Mint.s.sol --rpc-url "$RPC_URL" --sender "$SENDER" --broadcast --sig "run()" --verify -vvvv
forge script scripts/DeployCore.s.sol --rpc-url "$RPC_URL" --sender "$SENDER" --broadcast --sig "run(address)" --verify -vvvv "$ADDRESS"
forge script scripts/Init.s.sol --rpc-url "$RPC_URL" --sender "$SENDER" --broadcast --sig "run(address,address)" --verify -vvvv "$RECEIVABLE" "$PAP"
```

Run Anvil with specified Mnemonic

```sh
anvil -m "$MNEMONIC"
```

Get crurrent gas price in gwei

```sh
cast to-unit $(cast gas-price --rpc-url="$RPC_URL") gwei
```

### Deployment Addresses

#### Sepolia

- [IsleUSD](https://sepolia.etherscan.io/token/0xD7719799520b89A6b934A4402388e9EDdFD85387): `0xD7719799520b89A6b934A4402388e9EDdFD85387`
- Deployer: `0xBbC9928618b05356841a8565C72E4493D12ad163`
- Receivable: `0x5B7B3F2A2F8b306F6C8B368414A8c0f2B385cCbA`
- IsleGlobals: `0x3e17bE3a67006497cF1d4b0791D1c4e6fEd2C2dc`
- PoolAddressesProvider: `0x393Ed07ff75e4eD8E64fa664438EC969396081d9`

#### Linea

- [IsleUSD](): `0x0b2BdD04D12f4Fc7d4a45100cE3dC10605b44B00`
- Deployer: `0xBbC9928618b05356841a8565C72E4493D12ad163`
- Receivable: `0x9eDC5845AcEC7D8eeb3Eb5d73E9546D760b95c10`
- IsleGlobals: `0x8264c54eDdCEAe79f2efa9370b96b795Ea6C14B7`
- PoolAddressesProvider: `0x2ce499A1e349a0471ec7d99F64B4F6b8F7834e13`

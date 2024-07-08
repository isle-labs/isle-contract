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
cast to-unit $(cast gas-price) gwei
```

### Deployment Addresses

#### Sepolia (2023.10.19)

- [IsleUSD](https://sepolia.etherscan.io/token/0xD7719799520b89A6b934A4402388e9EDdFD85387): `0xD7719799520b89A6b934A4402388e9EDdFD85387`
- [Receivable](https://sepolia.etherscan.io/token/0x497918fD3227835184Af0D8fCc106E5e70BBc881): `0x497918fD3227835184Af0D8fCc106E5e70BBc881`
- Deployer: `0xBbC9928618b05356841a8565C72E4493D12ad163`
- IsleGlobals: `0xd5175C76F5a129De4F53b0DF5c878706E31910a1`
- PoolAddressesProvider: `0x454Bc3c86aB284F2Aa7A746733B23B46866FbeDB`
- WithdrawalManager: `0x7F5abDad0A9ee5Fbdf0B07F4Cf007F88783f14E5`
- LoanManager: `0x1a16F4f4805197DF48Cc898f97601CE97B13d4a4`
- PoolConfigurator: `0x389dE947656Fd0E2C806254Ad3fD9Ae4Ef297cDE`

##### Implementation

- Receivable: `0x103d37376F312C0D3FA4021351dC87811E0464B2`
- IsleGlobals: `0x359f8Cfc8EadB4acB591211B73F5968b9900dB06`
- WithdrawalManager: `0x9EDe7Fa06de4CcF3be5e26e27120eb608D001Ed8`
- LoanManager: `0x5a0a72f2c0a28161d33e7bd56191ab2ed1a629e3`
- PoolConfigurator: `0x4137b1072c18F50D8D5f883043712727efa7B038`

#### Plume

- Deployer: `0xBbC9928618b05356841a8565C72E4493D12ad163`
- [Receivable](https://testnet-explorer.plumenetwork.xyz/address/0x44dad751B53a250504E2D10EAeB52125Ba49669F?tab=read_proxy):
`0x44dad751B53a250504E2D10EAeB52125Ba49669F`
- [IsleGlobals](https://testnet-explorer.plumenetwork.xyz/address/0x0e7349cbcbA4d5394E51ae8B227a0f7D5ae3333c):
`0x0e7349cbcbA4d5394E51ae8B227a0f7D5ae3333c`
- [PoolAddressesProvider](https://testnet-explorer.plumenetwork.xyz/address/0x51b235a5511e7c25A3F610081f096101CCA72F99): `0x51b235a5511e7c25A3F610081f096101CCA72F99`
- [WithdrawalManager](https://testnet-explorer.plumenetwork.xyz/address/0x402bBecEeac2109Cff1fB358470bC2aa4f90578A): `0x402bbeceeac2109cff1fb358470bc2aa4f90578a`
- [LoanManager](https://testnet-explorer.plumenetwork.xyz/address/0x3e8824538a005e5a42fa9bc0e88eaec9862cae17): `0x3e8824538a005e5a42fa9bc0e88eaec9862cae17`
- [PoolConfigurator](https://testnet-explorer.plumenetwork.xyz/address/0x89b2e004e30f0b41e527c23c3e39cd086a639750): `0x89b2e004e30f0b41e527c23c3e39cd086a639750`

##### Implementation

- [Receivable](https://testnet-explorer.plumenetwork.xyz/address/0x2ce499A1e349a0471ec7d99F64B4F6b8F7834e13): `0x2ce499A1e349a0471ec7d99F64B4F6b8F7834e13`
- [IsleGlobals](https://testnet-explorer.plumenetwork.xyz/address/0x0b2BdD04D12f4Fc7d4a45100cE3dC10605b44B00): `0x0b2BdD04D12f4Fc7d4a45100cE3dC10605b44B00`
- [WithdrawalManager](https://testnet-explorer.plumenetwork.xyz/address/0x5Fe7D1D15Ca56183481D93F36c0467BFAaec48AE): `0x5Fe7D1D15Ca56183481D93F36c0467BFAaec48AE`
- [LoanManager](https://testnet-explorer.plumenetwork.xyz/address/0x533522565fA7A37ddc6Df54458648FFeeDb01066): `0x533522565fA7A37ddc6Df54458648FFeeDb01066`
- [PoolConfigurator](https://testnet-explorer.plumenetwork.xyz/address/0x196F865A118971fBb38E97798Edb2C7cF2938d2B): `0x196F865A118971fBb38E97798Edb2C7cF2938d2B`

### Verify contracts

```sh
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 1000 \
    --watch \
    ${Address} \
    contracts/Receivable.sol:Receivable
```

#### With constructor

See [Foundry Book](https://book.getfoundry.sh/forge/deploying?highlight=verify#verifying-a-pre-existing-contract)

```sh
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 1000 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address)" ${ARG}) \
    ${Address} \
    contracts/WithdrawalManager.sol:WithdrawalManager
```

#### With library

```sh
forge verify-contract \
    --chain-id 11155111 \
    --num-of-optimizations 1000 \
    --watch \
    --constructor-args $(cast abi-encode "constructor(address)" ${ARG}) \
    --libraries contracts/libraries/${Library}.sol:${Library}:${Address} \
    ${Address} \
    contracts/PoolConfigurator.sol:PoolConfigurator
```

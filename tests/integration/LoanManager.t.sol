// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import { console } from "@forge-std/console.sol";
import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import { Errors } from "../../contracts/libraries/Errors.sol";

import { IPoolAddressesProvider } from "../../contracts/interfaces/IPoolAddressesProvider.sol";
import { ILoanManagerEvents } from "../../contracts/interfaces/ILoanManagerEvents.sol";
import { IPool } from "../../contracts/interfaces/IPool.sol";

import { PoolConfigurator } from "../../contracts/PoolConfigurator.sol";
import { IntegrationTest } from "./Integration.t.sol";

contract LoanManagerTest is IntegrationTest, ILoanManagerEvents { }

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IPoolConfiguratorActions } from "./pool/IPoolConfiguratorActions.sol";
import { IPoolConfiguratorStorage } from "./pool/IPoolConfiguratorStorage.sol";
import { IPoolConfiguratorEvents } from "./pool/IPoolConfiguratorEvents.sol";

interface IPoolConfigurator is IPoolConfiguratorActions, IPoolConfiguratorStorage, IPoolConfiguratorEvents {

}

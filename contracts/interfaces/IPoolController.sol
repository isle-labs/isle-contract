// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { IPoolControllerActions } from "./pool/IPoolControllerActions.sol";
import { IPoolControllerStorage } from "./pool/IPoolControllerStorage.sol";
import { IPoolControllerEvents } from "./pool/IPoolControllerEvents.sol";

interface IPoolController is IPoolControllerActions, IPoolControllerStorage, IPoolControllerEvents { }

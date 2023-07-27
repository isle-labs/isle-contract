// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ReceivableStorage } from "../../receivables/ReceivableStorage.sol";

interface IReceivableLike {
    function getReceivableInfoById(uint256 tokenId) external view returns (ReceivableStorage.ReceivableInfo memory);
}

interface ILopoGlobalsLike { }

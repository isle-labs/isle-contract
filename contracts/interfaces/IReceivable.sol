// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { UD60x18, ud } from "@prb/math/UD60x18.sol";
import { ReceivableStorage } from "../ReceivableStorage.sol";

interface IReceivable {
    // events
    event AssetCreated(
        address indexed buyer,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 faceAmount,
        uint256 repaymentTimestamp
    );

    event LopoGlobalsSet(address indexed previousLopoGlobals_, address indexed currentLopoGlobals_);

    function createReceivable(
        address _seller,
        UD60x18 _faceAmount,
        uint256 _repaymentTimestamp,
        uint16 _currencyCode
    )
        external
        returns (uint256 _tokenId);

    function getReceivableInfoById(uint256 tokenId) external view returns (ReceivableStorage.ReceivableInfo memory);

    function setLopoGlobals(address _lopoGlobals) external;

    // View Functions
    function lopoGlobals() external view returns (address _lopoGlobals);

    function governor() external view returns (address _governor);
}

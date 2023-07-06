// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { ILopoProxyFactory, LopoProxyFactory } from "lopo-proxy-factory/LopoProxyFactory.sol";

import { ILopoLoanFactory } from "./interfaces/ILopoLoanFactory.sol";

/// @title LopoLoanFactory deploys Loan instances.
contract LopoLoanFactory is ILopoLoanFactory, LopoProxyFactory {

    mapping(address => bool) public override isLoan;

    /// @param lopoGlobals_ The address of a Lopo Globals contract.
    constructor(address lopoGlobals_) LopoProxyFactory(lopoGlobals_) {}

    function createInstance(bytes calldata arguments_, bytes32 salt_)
        override(ILopoProxyFactory, LopoProxyFactory) public returns (
            address instance_
        )
    {
        isLoan[instance_ = super.createInstance(arguments_, salt_)] = true;
    }

}

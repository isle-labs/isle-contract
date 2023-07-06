// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { ILopoProxyFactory } from "lopo-proxy-factory/interfaces/ILopoProxyFactory.sol";

/// @title LopoLoanFactory deploys Loan instances.
interface ILopoLoanFactory is ILopoProxyFactory {

    /**
     *  @dev    Whether the proxy is a LopoLoan deployed by this factory.
     *  @param  proxy_  The address of the proxy contract.
     *  @return isLoan_ Whether the proxy is a LopoLoan deployed by this factory.
     */
    function isLoan(address proxy_) external view returns (bool isLoan_);
}

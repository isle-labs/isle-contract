// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IERC20Mint {
    function mint(address beneficiary, uint256 amount) external;
}

contract ERC20Mint is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) { }

    function mint(address beneficiary_, uint256 amount_) external {
        _mint(beneficiary_, amount_);
    }
}

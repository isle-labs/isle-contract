// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import { MintableERC20WithPermit } from "../mocks/MintableERC20WithPermit.sol";
import { Assertions } from "./Assertions.sol";

abstract contract Utils is Assertions {
    // Returns a valid `permit` signature signed by this contract's `owner` address
    function getValidPermitSignature(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_,
        uint256 ownerSk_
    )
        internal
        view
        returns (uint8 v_, bytes32 r_, bytes32 s_)
    {
        return vm.sign(ownerSk_, getDigest(token_, owner_, spender_, amount_, nonce_, deadline_));
    }

    // Returns an ERC-2612 `permit` digest for the `owner` to sign
    function getDigest(
        address token_,
        address owner_,
        address spender_,
        uint256 amount_,
        uint256 nonce_,
        uint256 deadline_
    )
        public
        view
        returns (bytes32 digest_)
    {
        digest_ = keccak256(
            abi.encodePacked(
                "\x19\x01",
                MintableERC20WithPermit(token_).DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        MintableERC20WithPermit(token_).PERMIT_TYPEHASH(), owner_, spender_, amount_, nonce_, deadline_
                    )
                )
            )
        );
    }
}

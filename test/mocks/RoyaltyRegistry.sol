// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

/**
 * @title mock RoyaltyRegistry.
 * @dev test implementation of RoyaltyRegistry. Only needed for unit tests, not
 * to be deployed on mainnet-
 */
contract RoyaltyRegistry {
    /**
     * @dev See {IRegistry-getRoyaltyLookupAddress}.
     */
    function getRoyaltyLookupAddress(address tokenAddress) external pure returns (address) {
        return tokenAddress;
    }
}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "./CuratedFactory.sol";

/**
 *
 * @title PayableFactory                                         *
 *                                                           *
 * @notice Clone factory pattern contract                    *
 *                                                           *
 * @custom:security-contact tech@ninfa.io                    *
 *
 */

contract PayableFactory is CuratedFactory {
    uint256 public factoryFee;

    function payToClone(
        address _instance,
        bytes32 _salt,
        bytes calldata _data
    )
        external
        payable
        onlyMasterImplementations(_instance)
        returns (address clone_)
    {
        require(msg.value >= factoryFee);

        clone_ = _clone(_instance, _salt, _data);
    }

    function setFee(uint256 _newPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        factoryFee = _newPrice;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    constructor() {
        factoryFee = 50_000_000 gwei; // 0.05 ETH
    }
}

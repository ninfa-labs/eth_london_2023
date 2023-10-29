// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract ERC721Recipient {
    address public operator;
    address public from;
    uint256 public id;
    bytes public data;

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    )
        public
        returns (bytes4)
    {
        operator = _operator;
        from = _from;
        id = _id;
        data = _data;

        return 0x150b7a02; // ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract RevertingERC721Recipient {
    function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
        revert("0x150b7a02");
    }
}

contract WrongReturnDataERC721Recipient {
    function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
        return 0xCAFEBEEF;
    }
}

contract NonERC721Recipient { }

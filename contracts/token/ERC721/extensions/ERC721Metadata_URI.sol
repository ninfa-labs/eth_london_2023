/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "../ERC721.sol";
import "../../common/DecodeTokenURI.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721Metadata_URI is ERC721 {
    using DecodeTokenURI for bytes;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    /**
     * @dev Hardcoded base URI in order to remove the need for a constructor, it
     * can be set anytime by an admin
     * (multisig).
     */
    string private _baseTokenURI = "ipfs://";

    /**
     * @dev only set when a new token is minted.
     * No need for a setter function, see
     * https://forum.openzeppelin.com/t/why-doesnt-openzeppelin-erc721-contain-settokenuri/6373
     * and
     * https://forum.openzeppelin.com/t/function-settokenuri-in-erc721-is-gone-with-pragma-0-8-0/5978/2
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    mapping(uint256 => bytes32) internal _tokenURIs;

    /**
     * @dev check if the tokenURI has been minted before
     * @dev `_mintedURIs[tokenURI]` is never deleted from storage on purpose when burning tokens, in order to avoid
     * reusing the same tokenURI in the future if a tokenId is burned.
     */
    mapping(bytes32 => bool) private _mintedURIs;

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));

        return string( // once hex encoded base58 is converted to string, we get
            // the initial IPFS hash
            abi.encodePacked(
                _baseTokenURI,
                abi.encodePacked(bytes2(0x1220), _tokenURIs[tokenId]) // full
                    // bytes of base58 + hex encoded IPFS hash
                    // example.
                    // prepending 2 bytes IPFS hash identifier that was removed
                    // before storing the hash in order to
                    // fit in bytes32. 0x1220 is "Qm" base58 and hex encoded
                    // tokenURI (IPFS hash) with its first 2 bytes truncated,
                    // base58 and hex encoded returned as
                    // bytes32
                    .toBase58()
            )
        );
    }

    function _mint(address _to, uint256 _tokenId, bytes memory _data) internal virtual override {
        (bytes32 tokenURI_, bytes memory remainingData) = abi.decode(_data, (bytes32, bytes));
        /**
         * @dev require that tokenURI is not empty as signatures passed by minters to collectors for the lazyBuy()
         * function
         * contain an empty tokenURI which means that the same signed voucher could be used by a collector to mint a new
         * tokenID with an empty tokenURI, for whatever reason
         * @dev require that the tokenId does not exist yet, we check if the tokenURI has been minted before
         * if the tokenId does not exist yet, we check if the tokenURI has been minted before
         */
        if (tokenURI_ == 0x0 || _mintedURIs[tokenURI_]) revert();
        /**
         * @dev token URI MUST be set before transfering the control flow to _mint, which could include
         * external calls, which could result in reentrancy.
         * E.g. https://medium.com/chainsecurity/totalsupply-inconsistency-in-erc1155-nft-tokens-8f8e3b29f5aa
         */
        _tokenURIs[_tokenId] = tokenURI_;
        _mintedURIs[tokenURI_] = true;

        super._mint(_to, _tokenId, remainingData);
    }

    /**
     * @notice Optional function to set the base URI
     * @dev child contract MAY require access control to the external function
     * implementation
     */
    function _setBaseURI(string calldata baseURI_) internal {
        _baseTokenURI = baseURI_;
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function _burn(uint256 _tokenId) internal virtual override {
        delete _tokenURIs[_tokenId];

        super._burn(_tokenId);
    }
}

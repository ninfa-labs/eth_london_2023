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
import "../../common/ERC2981.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a
 * standardized way to retrieve royalty payment
 * information.
 */
abstract contract ERC721Royalties is ERC2981, ERC721 {
    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     * `_royaltyInfo` is an internal mapping pointing to a struct,
     * containing at a minimum `_royaltyInfo[_tokenId].minter` (the original creator of the token address),
     * thus `_deleteRoyaltyInfo()` indirectly revokes the ability to call `setRoyaltyInfo()` for the burned token,
     * since the minter address is used for access control in the child contract.
     */
    function _burn(uint256 _tokenId) internal virtual override {
        _deleteRoyaltyInfo(_tokenId);
        super._burn(_tokenId);
    }

    function _mint(address _to, uint256 _tokenId, bytes memory _data) internal virtual override {
        (address[] memory royaltyRecipients, uint16[] memory royaltyBps, bytes memory data) =
            abi.decode(_data, (address[], uint16[], bytes));

        /// @dev for security reasons, _setRoyaltyInfo() is called only if `royaltyBps` and `royaltyRecipients` are not
        /// empty
        if (royaltyRecipients.length > 0) {
            _setRoyaltyInfo(_tokenId, royaltyBps, royaltyRecipients);
        }

        /// @dev minter must be set regardless of whether `royaltyBps` is empty or not,
        /// since the minter address is used for access control in the child contract
        /// as well as being used as the default royalty recipient for the standard `royaltyInfo` function if the latter
        /// is not set, i.e. `royaltyRecipients.length == 0`
        _royaltyInfo[_tokenId].minter = _to;

        super._mint(_to, _tokenId, data);
    }
}

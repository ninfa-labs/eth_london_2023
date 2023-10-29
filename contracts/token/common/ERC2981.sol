/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

/**
 *
 * @title ERC2981NSovereign                                   *
 *                                                           *
 * @notice adds ERC2981 support to ERC-721.                  *
 *                                                           *
 * @dev Royalties BPS and recipient are token level        *
 * and may be set by owner in child contract by writing      *
 * directly to internal storage variables                    *
 *                                                           *
 * @dev Royalty information can be specified globally for    *
 * all token ids via {ERC2981-_setDefaultRoyalty}, and/or    *
 * individually for specific token ids via                   *
 * {ERC2981-_setTokenRoyalty}. The latter takes precedence.  *
 *                                                           *
 * @custom:security-contact tech@ninfa.io                    *
 *
 */

contract ERC2981 {
    uint16 private constant TOTAL_SHARES = 10_000;
    uint16 internal constant DEFAULT_ROYALTY_BPS = 1000;

    mapping(uint256 => RoyaltyInfo) internal _royaltyInfo;

    /**
     * @dev `bps`; "For precision purposes, it's better to express the royalty
     * percentage as "basis points" (points per
     * 10_000, e.g., 10% = 1000 bps) and compute the amount is
     * `(royaltyBps[_tokenId] * _salePrice) / 10000`" -
     * https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     * @dev minter is only set if different from deployer account in order to save gas, if inherited by a sovereign
     * contract,
     * for communal contracts, minter must be always set when minting
     * > "If you plan on having a contract where NFTs are created by
     * multiple authors
     *      AND they can update royalty details after minting, you will need to
     * record the original author of each
     * token." - https://forum.openzeppelin.com/t/setting-
     * /16065/2
     *      i.e. the original artist's address if different from the royalty
     * recipient's address, MUST be stored in
     * order to be used for access control on setter functions
     */
    struct RoyaltyInfo {
        address minter;
        address[] recipients;
        uint16[] bps;
        uint16 totalBps;
        bool secondary;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _value) external view returns (address recipient, uint256 value) {
        recipient = _royaltyInfo[_tokenId].minter;

        if (_royaltyInfo[_tokenId].totalBps == 0) {
            value = uint256(DEFAULT_ROYALTY_BPS * _value / TOTAL_SHARES);
        } else {
            value = uint256(_royaltyInfo[_tokenId].totalBps * _value / TOTAL_SHARES);
        }
    }

    function ninfaRoyaltyInfo(uint256 _tokenId) external returns (address[] memory recipients, uint16[] memory bps) {
        require(msg.sender.code.length > 0, "Invalid call");

        (recipients, bps) = _ninfaRoyaltyInfo(_tokenId);
    }

    function getRoyalties(uint256 tokenId) external view returns (address[] memory, uint256[] memory) {
        if (_royaltyInfo[tokenId].minter == address(0)) revert();
        return _getRoyalties(tokenId);
    }

    function _ninfaRoyaltyInfo(uint256 _tokenId) internal returns (address[] memory recipients, uint16[] memory bps) {
        if (_royaltyInfo[_tokenId].secondary == false) {
            _royaltyInfo[_tokenId].secondary = true;
        } else {
            if (_royaltyInfo[_tokenId].totalBps == 0) {
                recipients = new address[](1);
                bps = new uint16[](1);
                recipients[0] = _royaltyInfo[_tokenId].minter;
                bps[0] = DEFAULT_ROYALTY_BPS;
            } else {
                recipients = _royaltyInfo[_tokenId].recipients;
                bps = _royaltyInfo[_tokenId].bps;
            }
        }
    }

    function _getRoyalties(uint256 tokenId)
        internal
        view
        returns (address[] memory _royaltyRecipients, uint256[] memory _bps)
    {
        // Get token level royalties
        RoyaltyInfo memory tokenRoyaltyInfo = _royaltyInfo[tokenId];
        uint256 arraysLength = tokenRoyaltyInfo.recipients.length;

        if (arraysLength == 0) {
            _royaltyRecipients = new address[](1);
            _bps = new uint256[](1);
            _royaltyRecipients[0] = _royaltyInfo[tokenId].minter;
            _bps[0] = uint256(DEFAULT_ROYALTY_BPS);
        } else {
            _royaltyRecipients = tokenRoyaltyInfo.recipients;

            _bps = new uint256[](arraysLength);

            for (uint256 i = 0; i < arraysLength; i++) {
                _bps[i] = uint256(tokenRoyaltyInfo.bps[i]);
            }
        }
    }

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * An artist may decide to set the royalty recipient to an address other than its own;
     * it adds the artist address to the `_minters` mapping, in order to use it for access control
     * by the derived contract. This removes the burden of setting this
     * mapping in the `mint()` function as it will
     * rarely be needed.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _royaltyBps - The actual royalty bps, calculated on the total sale amount
     */
    function _setRoyaltyInfo(
        uint256 _tokenId,
        uint16[] memory _royaltyBps,
        address[] memory _royaltyRecipients
    )
        internal
    {
        uint256 bpsLength = _royaltyBps.length;
        require(bpsLength == _royaltyRecipients.length);
        uint16 totalBps;

        /// @dev since `_setRoyaltyInfo()` is called only if `royaltyBps` is not empty, the following unchecked block is
        /// safe from underflow
        /// furthermore the else branch only executes if `royaltyBps.length` is greater than 1
        if (bpsLength == 1) {
            totalBps = _royaltyBps[0];
        } else {
            do {
                unchecked {
                    --bpsLength;
                }
                totalBps += _royaltyBps[bpsLength];
            } while (bpsLength > 0);
            require(totalBps < TOTAL_SHARES);
        }

        _royaltyInfo[_tokenId].recipients = _royaltyRecipients;
        _royaltyInfo[_tokenId].bps = _royaltyBps;
        _royaltyInfo[_tokenId].totalBps = totalBps;
    }

    function _deleteRoyaltyInfo(uint256 _tokenId) internal {
        delete _royaltyInfo[_tokenId];
    }

    function isSecondaryMarket(uint256 _tokenId) external view returns (bool) {
        return _royaltyInfo[_tokenId].secondary;
    }
}

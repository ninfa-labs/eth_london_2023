// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract MockERC721SovereignV1 is ERC721 {

    struct Recipient {
        address recipient;
        uint24 bps;
    }

    struct RoyaltyInfoArray {
        address[] recipients;
        uint24[] bps;
        uint24 royaltyBps;
    }
    /**
     * @notice `royaltyRecipients` maps token ID to original artist, used for sending royalties to royaltyRecipients on all secondary sales.
     *      In self-sovereign editions there are token level royalty recipients
     * @dev "If you plan on having a contract where NFTs are created by multiple authors AND they can update royalty details after minting,
     *      you will need to record the original author of each token." - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     */

    mapping(uint256 => RoyaltyInfoArray) private _royaltyInfoArray;

    uint24 private constant TOTAL_SHARES = 10000; // 10,000 = 100% (total sale price)
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function tokenURI(uint256) public pure virtual override returns (string memory) {}

    function mint(
      address to, 
      uint256 tokenId, 
      uint24 royaltyBps_,
      uint24[] calldata recipientsBps_,
      address[] calldata royaltyRecipients_
        ) public virtual {
        _mint(to, tokenId);
        _setRoyalties(
          tokenId,
          royaltyBps_,
          recipientsBps_,
          royaltyRecipients_
        );
    }

    function burn(uint256 tokenId) public virtual {
        _burn(tokenId);
    }

    function safeMint(address to, uint256 tokenId) public virtual {
        _safeMint(to, tokenId);
    }

    function safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual {
        _safeMint(to, tokenId, data);
    }

    
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address recipient, uint256 royaltyAmount) {
        recipient = _royaltyInfoArray[_tokenId].recipients[0];
        royaltyAmount =
            (_salePrice * _royaltyInfoArray[_tokenId].royaltyBps) /
            TOTAL_SHARES;
    }

    function getRecipients(
        uint256 _tokenId
    ) external view returns (Recipient[] memory) {
        uint24[] memory _bps = _royaltyInfoArray[_tokenId].bps;
        address[] memory _recipients = _royaltyInfoArray[_tokenId].recipients;

        uint256 i = _recipients.length;

        Recipient[] memory _royaltyInfo = new Recipient[](i);

        do {
            --i;
            _royaltyInfo[i].recipient = _recipients[i];
            _royaltyInfo[i].bps = _bps[i];
        } while (i > 0);

        return _royaltyInfo;
    }

    function _setRoyalties(
        uint256 _tokenId,
        uint24 royaltyBps_,
        uint24[] calldata recipientsBps_,
        address[] calldata royaltyRecipients_
    ) internal {
        require(royaltyBps_ <= TOTAL_SHARES);
        uint256 i = recipientsBps_.length;
        require(i == royaltyRecipients_.length);

        uint24 sum;

        do {
            unchecked {
                --i;
                sum += recipientsBps_[i];
            }
        } while (i > 0);

        // the sum has to be equal to 100%
        require(sum == TOTAL_SHARES);

        _royaltyInfoArray[_tokenId].recipients = royaltyRecipients_;
        _royaltyInfoArray[_tokenId].bps = recipientsBps_;
        _royaltyInfoArray[_tokenId].royaltyBps = royaltyBps_;
    }

    function _resetTokenRoyalty(uint256 _tokenId) internal {
        delete _royaltyInfoArray[_tokenId];
    }

    
}
/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "../../../access/AccessControl.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/SignatureChecker.sol";
import "../../common/ERC712.sol";
import "../extensions/ERC721Enumerable.sol";
import "../extensions/ERC721Metadata_URI.sol";
import "../extensions/ERC721Royalties.sol";
import "../extensions/ERC721Burnable.sol";

/**
 *
 * @title ERC721Sovereign                                     *
 *                                                           *
 * @notice Self-sovereign ERC-721 minter preset               *
 *                                                           *
 * @dev {ERC721} token                                       *
 *                                                           *
 * @custom:security-contact tech@ninfa.io                    *
 *
 */

contract ERC721Sovereign is
    AccessControl,
    ERC712,
    ERC721Burnable,
    ERC721Royalties,
    ERC721Metadata_URI,
    ERC721Enumerable
{
    using SignatureChecker for address;
    using Address for address;
    using ECDSA for bytes32;
    /*----------------------------------------------------------*|
    |*  # ACCESS CONTROL                                        *|
    |*----------------------------------------------------------*/

    /**
     * @dev `MINTER_ROLE` is needed in case the deployer may want to use or
     * allow other accounts to mint on their
     * self-sovereign collection
     */
    bytes32 private constant MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE");
    bytes32 private constant CURATOR_ROLE = 0x850d585eb7f024ccee5e68e55f2c26cc72e1e6ee456acf62135757a5eb9d4a10; // keccak256("CURATOR_ROLE")
    /**
     * @dev constant set at deployment of master contract, replaces
     * `initializer` modifier reducing the cost of calling
     * `initialize` from the factory contract when a new clone is deployed.
     */
    address private immutable _FACTORY;

    /*----------------------------------------------------------*|
    |*  # MINTING                                               *|
    |*----------------------------------------------------------*/

    /**
     * @param _data bytes should be in the following format/order:
     * `abi.encodePacked(bytes32 _tokenURI, address [] memory _royaltyRecipients, uint16[] memory _royaltyBps`
     * @param _to is not only the recipient, but also it is set as the address that will be used for access control when
     * calling the `setRoyaltyInfo` function.
     * Hence `_to` MUST be an address controlled by the artist/minter in order to prevent unauthorized changes to the
     * royalty info.
     * @dev _tokenURI Replaces deprecated Openzeppelin contracts v4.0
     * `ERC721Metadata_URI` extension
     *      See
     * https://forum.openzeppelin.com/t/why-doesnt-openzeppelin-erc721-contain-settokenuri/6373
     * and
     * https://forum.openzeppelin.com/t/function-settokenuri-in-erc721-is-gone-with-pragma-0-8-0/5978/2
     * @dev when minted for the first time, royalty recipient MUST be set to
     * msg.sender, i.e. minter/artist;
     *      royalty receipient cannot and SHOULD not be set to an address
     * different than the minter's such as a payment
     * splitter or else `setRoyaltyRecipient` function will revert when called
     * (unless receiver )
     */
    function mint(address _to, bytes memory _data) external onlyRole(MINTER_ROLE) {
        _mint(_to, _owners.length, _data);
    }

    /**
     * @param _voucher voucher struct containing the tokenId metadata.
     * @param _to buyer, needed if using a external payment gateway, so that the
     * minted tokenId value is sent to the
     * address specified insead of `msg.sender`
     * @param _data _data bytes are passed to `onErc1155Received` function if the
     * `_to` address is a contract, for
     * example a marketplace.
     *      `onErc1155Received` is not being called on the minter's address when
     * a new tokenId is minted however, even
     * if it was contract.
     */
    function lazyMint(
        EncodeType.Voucher calldata _voucher,
        bytes calldata _signature,
        bytes calldata _data,
        address _to
    )
        external
        payable
    {
        require(_voucher.price == msg.value);
        /**
         * @dev ensuring that signer has MINTER_ROLE and that tokenIds are incremented sequentially
         * @dev trying to replay the same voucher and signature will revert as the tokenURI will be the same,
         * i.e. no need to void vouchers
         */
        uint256 tokenId = _owners.length;
        bytes32 digest = getTypedDataDigest(_voucher);

        address signer;

        if (_voucher.ERC1271Account == ZERO_ADDRESS) {
            signer = digest.recover(_signature);
            require(hasRole(MINTER_ROLE, signer));
        } else {
            signer = _voucher.ERC1271Account;
            require(hasRole(MINTER_ROLE, signer) && signer.isValidSignatureNow(digest, _signature));
        }

        /**
         * @dev _voucher.tokenURI is prepended to the _data bytes, since it is bytes32 id doesn't need to be padded
         * hence encodePacked is used.
         * @dev since the new token is being minted to the signer, there is no risk of reentrancy due to untrusted
         * external contracts.
         *
         */
        _mint(
            signer,
            tokenId,
            abi.encode(_voucher.tokenURI, abi.encode(_voucher.royaltyRecipients, _voucher.royaltyBps, ""))
        );

        _lazyBuy(_voucher, digest, _to, signer, msg.value);

        _safeTransfer(signer, _to, tokenId, _data);
        _royaltyInfo[tokenId].secondary = true;
    }

    /**
     * @param _voucher.value in this case is not the price of the token, but the tokenId
     */
    function lazyBuy(
        EncodeType.Voucher calldata _voucher,
        bytes calldata _signature,
        bytes calldata _data,
        address _to
    )
        external
        payable
    {
        bytes32 digest = getTypedDataDigest(_voucher);
        address signer = digest.recover(_signature);
        uint256 sellerAmount = _voucher.price;

        if (sellerAmount > 0) {
            require(sellerAmount == msg.value);

            (address[] memory royaltyRecipients, uint16[] memory royaltyBps) = _ninfaRoyaltyInfo(_voucher.value);

            uint256 i = royaltyRecipients.length;
            if (i > 0) {
                uint256 royaltyAmount;
                do {
                    --i;
                    royaltyAmount = (msg.value * royaltyBps[i]) / 10_000;
                    sellerAmount -= royaltyAmount;
                    royaltyRecipients[i].sendValue(royaltyAmount);
                } while (i > 0);
            }
        }
        /**
         * @dev _lazyBuy outside of if statement as it contains require statements that should be executed regardless of
         * price
         */
        _lazyBuy(_voucher, digest, _to, signer, sellerAmount);

        _safeTransfer(signer, _to, _voucher.value, _data);

        _void[signer][digest] = true;
    }

    /*----------------------------------------------------------*|
    |*  # ROYALTY INFO SETTER                                   *|
    |*----------------------------------------------------------*/

    function setRoyaltyInfo(
        uint256 _tokenId,
        uint16[] memory _royaltyBps,
        address[] memory _royaltyRecipients
    )
        external
    {
        require(_royaltyInfo[_tokenId].minter == msg.sender);
        _setRoyaltyInfo(_tokenId, _royaltyBps, _royaltyRecipients);
    }

    /*----------------------------------------------------------*|
    |*  # URI STORAGE                                           *|
    |*----------------------------------------------------------*/

    function setBaseURI(string calldata baseURI_) external {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender));
        _setBaseURI(baseURI_);
    }

    /*----------------------------------------------------------*|
    |*  # REQUIRED SOLIDITY OVERRIDES                           *|
    |*----------------------------------------------------------*/

    /**
     * @dev super._mint calls parent functions from the most derived to the most base contract: ERC721Metadata_URI,
     * ERC721Royalties, ERC721
     */
    function _mint(
        address _to,
        uint256 _id,
        bytes memory _data
    )
        internal
        override(ERC721Metadata_URI, ERC721Royalties, ERC721)
    {
        super._mint(_to, _id, _data);
    }

    /**
     *
     * @param _tokenId token ID to burn
     * @dev overrides _burn function of base contract and all extensions
     * @dev deletes royalty info from storage
     */
    function _burn(uint256 _tokenId) internal override(ERC721Royalties, ERC721Metadata_URI, ERC721) {
        _deleteRoyaltyInfo(_tokenId);
        super._burn(_tokenId);
    }

    /*----------------------------------------------------------*|
    |*  # VIEW FUNCTIONS                                        *|
    |*----------------------------------------------------------*/

    /**
     * @dev same function interface as erc1155, so that external contracts, i.e.
     * the marketplace, can check either erc
     * without requiring an if/else statement
     */
    function exists(uint256 _id) external view returns (bool) {
        return _owners[_id] != ZERO_ADDRESS;
    }

    /*----------------------------------------------------------*|
    |*  # ERC-165                                               *|
    |*----------------------------------------------------------*/

    /**
     * @dev See {IERC165-supportsInterface}.
     * `supportsInterface()` was first implemented by all contracts and later
     * all implementations removed, hardcoding
     * interface IDs in order to save some gas and simplify the code.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x80ac58cd // type(IERC721).interfaceId
            || interfaceId == 0x780e9d63 // type(IERC721Enumerable).interfaceId
            || interfaceId == 0x5b5e139f // type(IERC721Metadata).interfaceId
            || interfaceId == 0x01ffc9a7 // type(IERC165).interfaceId
            || interfaceId == 0x2a55205a // type(IERC2981).interfaceId
            || interfaceId == 0x7965db0b; // type(IAccessControl).interfaceId;
    }

    /*----------------------------------------------------------*|
    |*  # INITIALIZATION                                        *|
    |*----------------------------------------------------------*/

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `MINTER_ROLE` to the account that
     * deploys the contract.
     *      `MINTER_ROLE` is needed in case the deployer may want to use or
     * allow other accounts to mint on their
     * self-sovereign collection
     */
    function initialize(bytes calldata _data) external {
        require(msg.sender == _FACTORY);

        address deployer;
        (name, symbol, deployer) = abi.decode(_data, (string, string, address));

        _grantRole(DEFAULT_ADMIN_ROLE, deployer);
        _grantRole(CURATOR_ROLE, deployer);
        _grantRole(MINTER_ROLE, deployer);
        _setRoleAdmin(MINTER_ROLE, CURATOR_ROLE);

        /**
         * @dev The EIP712Domain fields should be the order as above, skipping
         * any absent fields.
         *      Protocol designers only need to include the fields that make
         * sense for their signing domain. Unused
         * fields are left out of the struct type.
         * @param name the user readable name of signing domain, i.e. the name
         * of the DApp or the protocol.
         * @param chainId the EIP-1155 chain id. The user-agent should refuse
         * signing if it does not match the currently
         * active chain.
         * @param verifyingContract the address of the contract that will verify
         * the signature. The user-agent may do
         * contract specific phishing prevention.
         *      verifyingContract is the only variable parameter in the
         * DOMAIN_SEPARATOR in order to avoid signature
         * replay across different contracts
         *      therefore the DOMAIN_SEPARATOR MUST be calculated inside of the
         * `initialize` function rather than the
         * constructor.
         */
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)), // name
                block.chainid, // chainId
                address(this) // verifyingContract
            )
        );
    }

    constructor(address factory_) {
        _FACTORY = factory_;
    }
}

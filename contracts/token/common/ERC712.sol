/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT

import "../../utils/Address.sol";

pragma solidity 0.8.22;

/**
 * @notice Struct needed for endodeType and encodeData, see
 * https://eips.ethereum.org/EIPS/eip-712#definition-of-encodetype
 */
library EncodeType {
    /**
     * @param tokenURI the IPFS hash of the metadata
     * @param value if more than 0, indicates that this value (from the voucher) is multiplied by the price, rather
     * than the value passed by the user.
     * this is used for when the artist wants to limit the amount of tokens that can be minted per voucher, i.e. per
     * user.
     * E.g. in a DAPP the backend generates a single signature per user, then the nonce is increased so that a new
     * signature is required for each mint, to prevent replay attacks.
     * The artist could for example grant MINER_ROLE to the backend, so that the backend can mint tokens on behalf of
     * the user.
     * @param endTime salt for when the signed voucher should expire,
     *      if no expiration is needed, salt should be `type(uint256).max`
     * i.e. 2**256 - 1,
     *      or anything above 2^32, i.e. 4294967296, i.e. voucher expires after
     * 2106 (in 83 years time)
     * @param salt salt for the signature, to prevent replay attacks,
     * also because it is the only way to make the same voucher unique,
     * or else it would not be possible to sign the same encodeData twice because the signature is voided after lazyBuy
     * is executed
     * The voucher is not voided after lazyMint because it is not supposed to be used more than once; enforced in
     * `ERC721Metadata_URI-_mint()` to avoid repolay attacks
     * @param buyerAddress if not empty, indicates that the voucher is for a specific address, and that the voucher
     * @param tokenId the tokenId will be ignored in lazyMint, because it will be _owners.length
     * while it must beused in lazyBuy
     * @param royaltyBps royalty basis points. Will be ignored in lazyBuy, while it must be used in lazyMint
     * @param royaltyRecipients royalty recipient. Will be ignored in lazyBuy, while it must be used in lazyMint
     * @param commissionBps array of commission basis points, i.e. 10000 = 100%,
     *     commissionBps.length must be the same as commissionRecipients.length
     * @param commissionRecipients array of commission recipients
     */
    struct Voucher {
        bytes32 tokenURI;
        uint256 price;
        uint256 endTime;
        uint256 value;
        uint256 salt;
        address buyerAddress;
        address ERC1271Account;
        uint16[] royaltyBps;
        uint16[] commissionBps;
        address[] royaltyRecipients;
        address[] commissionRecipients;
    }
}

contract ERC712 {
    using Address for address;

    bytes32 internal DOMAIN_SEPARATOR;
    bytes32 internal immutable DOMAIN_TYPEHASH;
    bytes32 private immutable VOUCHER_TYPEHASH;

    mapping(address => mapping(bytes32 => bool)) internal _void;

    event VoidVouchers(address, bytes32[] digests);

    function voidVouchers(bytes32[] calldata _digests) external {
        uint256 i = _digests.length;
        do {
            --i;
            _void[msg.sender][_digests[i]] = true;
        } while (i > 0);
        emit VoidVouchers(msg.sender, _digests);
    }

    function _lazyBuy(
        EncodeType.Voucher calldata _voucher,
        bytes32 _digest,
        address _to,
        address _signer,
        uint256 _sellerAmount
    )
        internal
    {
        require(
            // allows to set an expiration date for the voucher
            _voucher.endTime > block.timestamp
            // prevents invalid signatures to be used
            && !_void[_signer][_digest]
            // if the voucher buyerAddress is not empty, it must be the same as the _to address, or else the voucher is
            // not valid because it was not minted for the _to address
            && (_voucher.buyerAddress == address(0) || _voucher.buyerAddress == _to)
        );

        if (_voucher.price > 0) {
            /**
             * @dev it is not necessary to check if bps and recipients arrays are the same length, since the voucher is
             * signed by the artist.
             * if they were different lengths by mistake, the tx would either revert with index out of bounds,
             * or if `(_voucher.commissionBps.length < _voucher.commissionRecipients.length)`,
             * the loop would not revert but any additional address in _voucher.commissionRecipients would be ignored.
             */
            uint256 i = _voucher.commissionRecipients.length;
            if (i > 0) {
                uint256 commissionAmount;
                do {
                    --i;
                    commissionAmount = (msg.value * _voucher.commissionBps[i]) / 10_000;
                    _sellerAmount -= commissionAmount;
                    _voucher.commissionRecipients[i].sendValue(commissionAmount);
                } while (i > 0);
            }

            _signer.sendValue(_sellerAmount);
        }
    }

    function getTypedDataDigest(EncodeType.Voucher calldata _voucher) public view returns (bytes32 _digest) {
        _digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VOUCHER_TYPEHASH,
                        _voucher.tokenURI,
                        _voucher.price,
                        _voucher.endTime,
                        _voucher.value,
                        _voucher.salt,
                        _voucher.buyerAddress,
                        keccak256(abi.encodePacked(_voucher.royaltyBps)),
                        keccak256(abi.encodePacked(_voucher.commissionBps)),
                        keccak256(abi.encodePacked(_voucher.royaltyRecipients)),
                        keccak256(abi.encodePacked(_voucher.commissionRecipients))
                    )
                )
            )
        );
    }

    constructor() {
        DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
        VOUCHER_TYPEHASH = keccak256(
            "EncodeType.Voucher(bytes32 tokenURI,uint256 price,uint256 endTime,uint256 value,uint256 salt,address buyerAddress,address ERC1271Account,uint16[] royaltyBps,uint16[] commissionBps,address[] royaltyRecipients,address[] commissionRecipients)"
        );
    }
}

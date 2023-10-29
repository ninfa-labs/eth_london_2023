// SPDX-License-Identifier: MIT

pragma solidity 0.8.22;

import "./IERC721.sol";
import { EncodeType } from "src/token/common/ERC712.sol";

interface IERC721Sovereign is IERC721 {

    /**
     * METADATA EXTENSION
     */

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256) external view returns (string memory);

    /**
     * BURNABLE EXTENSION
     */

    function burn(uint256) external;

    /**
     * MINTABLE EXTENSION
     */

    function mint(address, bytes calldata) external;

    /**
     * ENUMERABLE EXTENSION
     */
    
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token
     * list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address, uint256) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by
     * the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256) external view returns (uint256);

    /**
     * @dev invalidates signatures
     * in case of lazy mint: must be used in case the signer raises the price, edits the split or cancels the voucher
     * in case of lazy buy: must be used in any case the signer wants to modify the voucher, except burn, because
     * no one can be the owner of the token anymore.
     */ 
    function voidVouchers(bytes32[] calldata, bytes[] calldata) external;

    function lazyMint(
        EncodeType.Voucher calldata,
        bytes calldata,
        bytes calldata,
        address
        ) external payable;

    function lazyBuy(
        EncodeType.Voucher calldata,
        bytes calldata,
        bytes calldata,
        address
    )
        external
        payable;

    function getTypedDataDigest(EncodeType.Voucher memory) external view returns (bytes32);

    function recover(bytes memory, bytes32) external pure returns (address);

    function royaltyInfo(uint256, uint256) external view returns (address, uint256);

    function ninfaRoyaltyInfo(uint256) external returns (address[] memory, uint16[] memory);

    function isSecondaryMarket(uint256) external view returns (bool);
}

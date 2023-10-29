// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { Test } from "forge-std/Test.sol";
import { Constants } from "test/helpers/Utils.sol";
import { console2 } from "forge-std/console2.sol";

import {
    ERC721Recipient,
    RevertingERC721Recipient,
    WrongReturnDataERC721Recipient,
    NonERC721Recipient
} from "test/mocks/ERC721Recipient.sol";
import "test/interfaces/IERC165.sol";
import "test/interfaces/IERC721.sol";
import "test/interfaces/IERC721Sovereign.sol";
import "test/interfaces/IAccessControl.sol";

abstract contract ERC721Validator is Test, Constants, ERC721Recipient {

    function _testAccounts(
        address deployer_,
        address curator_,
        address minter_,
        address collector_,
        address operator_,
        address anon_,
        address feesRecipient_
    )
        internal
    {
        assertEq(deployer_, DEPLOYER);
        assertEq(curator_, CURATOR);
        assertEq(minter_, MINTER);
        assertEq(collector_, COLLECTOR);
        assertEq(operator_, OPERATOR);
        assertEq(anon_, ANON);
        assertEq(feesRecipient_, FEES_RECIPIENT);
    }

    /*----------------------------------------------------------*|
    |*  # INTERFACES AND EXTENSIONS                             *|
    |*----------------------------------------------------------*/

    function _testSupportsInterface(address _ERC721) internal {

        /// @dev ERC165

        assertEq(IERC721(_ERC721).supportsInterface(type(IERC721).interfaceId), true);

        /// @dev ERC721

        assertEq(IERC721(_ERC721).supportsInterface(type(IERC165).interfaceId), true);

        /// @dev ERC721Metadata

        assertEq(IERC721(_ERC721).supportsInterface(0x5b5e139f), true); // type(IERC721Metadata).interfaceId
        string memory tokenURI = IERC721Sovereign(_ERC721).tokenURI(0);
        assertEq(bytes(tokenURI).length > 0, true);

        /// @dev ERC721Enumerable

        assertEq(IERC721(_ERC721).supportsInterface(0x780e9d63), true);  // type(IERC721Enumerable).interfaceId
        /// @dev tokenByIndex(0) should not throw.
        assertEq(IERC721Sovereign(_ERC721).tokenByIndex(0), 0);

        uint256 totalSupply = IERC721Sovereign(_ERC721).totalSupply();
        uint256 totalBalance = 0;

        address[] memory uniqueAddresses = new address[](totalSupply);
        uint256 uniqueAddressesCount = 0;

        for (uint256 i = 0; i < totalSupply; i++) {
            address currentOwner = IERC721(_ERC721).ownerOf(i);
            bool alreadySeen = false;

            for (uint256 j = 0; j < uniqueAddressesCount; j++) {
                if (uniqueAddresses[j] == currentOwner) {
                    alreadySeen = true;
                    break;
                }
            }

            if (!alreadySeen) {
                uniqueAddresses[uniqueAddressesCount] = currentOwner;
                uniqueAddressesCount++;
                totalBalance += IERC721(_ERC721).balanceOf(currentOwner);
            }
        }
        /// @dev The sum of all user balances must be equal to the total supply
        assertEq(totalSupply, totalBalance);
    }



    /*----------------------------------------------------------*|
    |*  # MODIFIED SOLMATE TESTS                                *|
    |*----------------------------------------------------------*/

    /// @dev modified Solmate function interface, name and symbol are optional, pass "" if name and symbol are not known
    function _invariant_ERC721Metadata(address _ERC721, string memory _name, string memory _symbol) internal {
        if (bytes(_name).length > 0) {
            assertEq(IERC721Sovereign(_ERC721).name(), _name);
        } else {
            _name = IERC721Sovereign(_ERC721).name();
            assertEq(bytes(_name).length > 0, true);
        }

        if (bytes(_symbol).length > 0) {
            assertEq(IERC721Sovereign(_ERC721).symbol(), _symbol);
        } else {
            _symbol = IERC721Sovereign(_ERC721).symbol();
            assertEq(bytes(_symbol).length > 0, true);
        }
    }

    function _testMint(address _ERC721) internal {
        assertEq(IERC721(_ERC721).balanceOf(address(this)), 1);
        assertEq(IERC721(_ERC721).ownerOf(0), address(this));
    }

    function _testBurn(address _ERC721) internal {
        IERC721Sovereign(_ERC721).burn(0);

        assertEq(IERC721(_ERC721).balanceOf(address(this)), 0);
        vm.expectRevert(bytes(""));
        IERC721(_ERC721).ownerOf(0);
    }

    function _testApprove(address _ERC721) internal {
        IERC721(_ERC721).approve(OPERATOR, 0);

        assertEq(IERC721(_ERC721).getApproved(0), OPERATOR);
    }

    function _testApproveBurn(address _ERC721) internal {
        IERC721(_ERC721).approve(OPERATOR, 0);

        IERC721Sovereign(_ERC721).burn(0);

        assertEq(IERC721(_ERC721).balanceOf(address(this)), 0);

        vm.expectRevert(bytes(""));
        IERC721(_ERC721).getApproved(0);

        vm.expectRevert(bytes(""));
        IERC721(_ERC721).ownerOf(0);
    }

    function _testApproveAll(address _ERC721) internal {
        IERC721(_ERC721).setApprovalForAll(OPERATOR, true);

        assertTrue(IERC721(_ERC721).isApprovedForAll(address(this), OPERATOR));
    }

    function _testTransferFrom(address _ERC721) internal {
        IERC721(_ERC721).approve(OPERATOR, 0);

        vm.prank(OPERATOR);
        IERC721(_ERC721).transferFrom(address(this), OPERATOR, 0);

        assertEq(IERC721(_ERC721).getApproved(0), address(0));
        assertEq(IERC721(_ERC721).ownerOf(0), OPERATOR);
        assertEq(IERC721(_ERC721).balanceOf(OPERATOR), 1);
        assertEq(IERC721(_ERC721).balanceOf(address(this)), 0);
    }

    function _testTransferFromSelf(address _ERC721) internal {
        IERC721(_ERC721).transferFrom(address(this), OPERATOR, 0);

        assertEq(IERC721(_ERC721).getApproved(0), address(0));
        assertEq(IERC721(_ERC721).ownerOf(0), OPERATOR);
        assertEq(IERC721(_ERC721).balanceOf(OPERATOR), 1);
        assertEq(IERC721(_ERC721).balanceOf(address(this)), 0);
    }

    function _testTransferFromApproveAll(address _ERC721) internal {
        IERC721(_ERC721).setApprovalForAll(OPERATOR, true);

        vm.prank(OPERATOR);
        IERC721(_ERC721).transferFrom(address(this), OPERATOR, 0);

        assertEq(IERC721(_ERC721).getApproved(0), address(0));
        assertEq(IERC721(_ERC721).ownerOf(0), OPERATOR);
        assertEq(IERC721(_ERC721).balanceOf(OPERATOR), 1);
        assertEq(IERC721(_ERC721).balanceOf(address(this)), 0);
    }

    function _testSafeTransferFromToEOA(address _ERC721) internal {
        IERC721(_ERC721).setApprovalForAll(OPERATOR, true);

        vm.prank(OPERATOR);
        IERC721(_ERC721).safeTransferFrom(address(this), OPERATOR, 0);

        assertEq(IERC721(_ERC721).getApproved(0), address(0));
        assertEq(IERC721(_ERC721).ownerOf(0), OPERATOR);
        assertEq(IERC721(_ERC721).balanceOf(OPERATOR), 1);
        assertEq(IERC721(_ERC721).balanceOf(address(this)), 0);
    }

    function _testSafeTransferFromToERC721Recipient(address _ERC721) internal {
        IERC721(_ERC721).setApprovalForAll(OPERATOR, true);

        ERC721Recipient recipient = new ERC721Recipient();

        vm.prank(OPERATOR);
        IERC721(_ERC721).safeTransferFrom(address(this), address(recipient), 0);

        assertEq(IERC721(_ERC721).getApproved(0), address(0));
        assertEq(IERC721(_ERC721).ownerOf(0), address(recipient));
        assertEq(IERC721(_ERC721).balanceOf(address(recipient)), 1);
        assertEq(IERC721(_ERC721).balanceOf(address(this)), 0);

        assertEq(recipient.operator(), OPERATOR);
        assertEq(recipient.from(), address(this));
        assertEq(recipient.id(), 0);
        assertEq(recipient.data(), "");
    }

    function _testSafeTransferFromToERC721RecipientWithData(address _ERC721) internal {
        ERC721Recipient recipient = new ERC721Recipient();

        IERC721(_ERC721).setApprovalForAll(OPERATOR, true);

        vm.prank(OPERATOR);
        IERC721(_ERC721).safeTransferFrom(address(this), address(recipient), 0, "testing 123");

        assertEq(IERC721(_ERC721).getApproved(0), address(0));
        assertEq(IERC721(_ERC721).ownerOf(0), address(recipient));
        assertEq(IERC721(_ERC721).balanceOf(address(recipient)), 1);
        assertEq(IERC721(_ERC721).balanceOf(address(this)), 0);

        assertEq(recipient.operator(), OPERATOR);
        assertEq(recipient.from(), address(this));
        assertEq(recipient.id(), 0);
        assertEq(recipient.data(), "testing 123");
    }

    function _testSafeMintToERC721Recipient(address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps) internal {
        ERC721Recipient to = new ERC721Recipient();
        IERC721Sovereign(_ERC721).mint(address(to), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "")));

        assertEq(IERC721(_ERC721).ownerOf(1), address(to));
        assertEq(IERC721(_ERC721).balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1);
        assertEq(to.data(), "");
    }

    function _testSafeMintToERC721RecipientWithData(address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps
        ) internal {
        ERC721Recipient to = new ERC721Recipient();

        IERC721Sovereign(_ERC721).mint(address(to), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "testing 123")));

        assertEq(IERC721(_ERC721).ownerOf(1), address(to));
        assertEq(IERC721(_ERC721).balanceOf(address(to)), 1);

        assertEq(to.operator(), address(this));
        assertEq(to.from(), address(0));
        assertEq(to.id(), 1);
        assertEq(to.data(), "testing 123");
    }

    function _testFailMintToZero(address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps
        ) internal {
        IERC721Sovereign(_ERC721).mint(address(0), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "")));
    }

    function _testFailDoubleMint(address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps
        ) internal {
        IERC721Sovereign(_ERC721).mint(address(this), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "")));
        IERC721Sovereign(_ERC721).mint(address(this), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "")));
    }

    function _testFailBurnUnminted(address _ERC721) internal {
        IERC721Sovereign(_ERC721).burn(1);
    }

    function _testFailDoubleBurn(address _ERC721) internal {
        IERC721Sovereign(_ERC721).burn(0);
        IERC721Sovereign(_ERC721).burn(0);
    }

    function _testFailApproveUnMinted(address _ERC721) internal {
        IERC721(_ERC721).approve(OPERATOR, 1337);
    }

    function _testFailApproveUnAuthorized(address _ERC721) internal {
        vm.prank(ANON);
        IERC721(_ERC721).approve(OPERATOR, 0);
    }

    function _testFailTransferFromUnOwned(address _ERC721) internal {
        IERC721(_ERC721).transferFrom(ANON, address(this), 1337);
    }

    function _testFailTransferFromWrongFrom(address _ERC721) internal {
        IERC721(_ERC721).transferFrom(ANON, address(this), 0);
    }

    function _testFailTransferFromToZero(address _ERC721) internal {
        IERC721(_ERC721).transferFrom(address(this), address(0), 0);
    }

    function _testFailTransferFromNotOwner(address _ERC721) internal {
        vm.prank(ANON);
        IERC721(_ERC721).transferFrom(address(this), ANON, 0);
    }

    function _testFailSafeTransferFromToNonERC721Recipient(address _ERC721) internal {
        IERC721(_ERC721).safeTransferFrom(address(this), address(new NonERC721Recipient()), 0);
    }

    function _testFailSafeTransferFromToNonERC721RecipientWithData(address _ERC721) internal {
        IERC721(_ERC721).safeTransferFrom(address(this), address(new NonERC721Recipient()), 0, "testing 123");
    }

    function _testFailSafeTransferFromToRevertingERC721Recipient(address _ERC721) internal {
        IERC721(_ERC721).safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 0);
    }

    function _testFailSafeTransferFromToRevertingERC721RecipientWithData(address _ERC721) internal {
        IERC721(_ERC721).safeTransferFrom(address(this), address(new RevertingERC721Recipient()), 0, "testing 123");
    }

    function _testFailSafeTransferFromToERC721RecipientWithWrongReturnData(address _ERC721) internal {
        IERC721(_ERC721).safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 0);
    }

    function _testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData(address _ERC721) internal {
        IERC721(_ERC721).safeTransferFrom(address(this), address(new WrongReturnDataERC721Recipient()), 0, "testing 123");
    }

    function _testFailSafeMintToNonERC721Recipient(address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps) internal {
        IERC721Sovereign(_ERC721).mint(address(new NonERC721Recipient()), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "")));
    }

    function _testFailSafeMintToNonERC721RecipientWithData(
        address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps

    )
        internal
    {
        IERC721Sovereign(_ERC721).mint(address(new NonERC721Recipient()), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "testing 123")));
    }

    function _testFailSafeMintToRevertingERC721Recipient(address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps) internal {
        IERC721Sovereign(_ERC721).mint(address(new RevertingERC721Recipient()), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "")));
    }

    function _testFailSafeMintToRevertingERC721RecipientWithData(address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps) internal {
        IERC721Sovereign(_ERC721).mint(address(new RevertingERC721Recipient()), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "testing 123")));
    }

    function _testFailSafeMintToERC721RecipientWithWrongReturnData(address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps) internal {
        IERC721Sovereign(_ERC721).mint(address(new WrongReturnDataERC721Recipient()), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "")));
    }

    function _testFailSafeMintToERC721RecipientWithWrongReturnDataWithData(
        address _ERC721, address[] memory _royaltyRecipients, uint16[] memory _royaltyBps
    )
        internal
    {
        IERC721Sovereign(_ERC721).mint(address(new WrongReturnDataERC721Recipient()), abi.encode(ONE_BYTES32, abi.encode(_royaltyRecipients, _royaltyBps, "testing 123")));
    }

    /// @dev balanceOf(address(0)) should throw.
    function _testFailBalanceOfZeroAddress(address _ERC721) internal view {
        IERC721(_ERC721).balanceOf(address(0));
    }

    function _testFailOwnerOfUnminted(address _ERC721) internal view {

        IERC721(_ERC721).ownerOf(1);
    }

    /*----------------------------------------------------------*|
    |*  # LAZY MINT AND LAZY BUY                                *|
    |*----------------------------------------------------------*/

    // test lazy mint from testing contract signing via ERC1271, sovereign contracts must support this ERC!
    // function _testLazyMintFromERC1271Signer {
    //     // TODO
    // }

    // TODO test private sale lazy mint
    // todo test royalties; a) default royalties (none set when minting), b) set royalty info with an array length of 1 and c) 2 recipients (multiple recipients)
    function _testLazyMint(
        address _ERC721,
        address _seller,
        address _buyer,
        EncodeType.Voucher memory _voucher,
        bytes memory _signature
    )
        internal
    {
        uint256 buyerBalance = _buyer.balance;
        uint256 sellerBalance = _seller.balance;
        uint256 primarySaleCommissionAmount;
        
        if(_voucher.commissionBps.length > 0)
            primarySaleCommissionAmount = _voucher.price * _voucher.commissionBps[0] / 10000;

        vm.prank(_buyer);

        IERC721Sovereign(_ERC721).lazyMint{ value: _voucher.price }(
                _voucher,
                _signature,
                "",
                _buyer
            );

        // check ownership
        assertEq(IERC721(_ERC721).balanceOf(_buyer), 1, "EOA balance incorrect");
        assertEq(IERC721(_ERC721).ownerOf(1), _buyer, "ownerOf failed");
        // check balances
        assertEq(_buyer.balance, buyerBalance - _voucher.price, "buyer balance failed");
        assertEq(_seller.balance, sellerBalance + _voucher.price - primarySaleCommissionAmount, "lazy mint, seller balance failed");
        if (primarySaleCommissionAmount > 0)
            assertEq(NINFA_FEES_MULTISIG.balance, primarySaleCommissionAmount, "NINFA_FEES_MULTISIG balance failed");
    }

    function _testLazyBuy(
        address _ERC721,
        address _seller,
        address _buyer,
        EncodeType.Voucher memory _voucher,
        bytes memory _signature
    )
        internal
    {
        uint256 buyerBalance = _buyer.balance;
        uint256 sellerBalance = _seller.balance;
        uint256 primarySaleCommissionAmount;
        bool isSecondarySale = IERC721Sovereign(_ERC721).isSecondaryMarket(_voucher.value);
        address royaltyRecipient;
        uint256 royaltyRecipientBalance;
        uint256 royaltyAmount;

        if(_voucher.commissionBps.length > 0)
            primarySaleCommissionAmount = _voucher.price * _voucher.commissionBps[0] / 10000;

        /// @dev must be calculated before lazyBuy because lazyBuy sets the secondary bool to true after the sale
        if (isSecondarySale) {
            (royaltyRecipient, royaltyAmount) = IERC721Sovereign(_ERC721).royaltyInfo(_voucher.value, _voucher.price);
            royaltyRecipientBalance = royaltyRecipient.balance;
        }

        // transfer tokenId 0 to _seller so that they own it and can sell it via lazyBuy (primary sale, i.e. commissions paid to)
        // i.e. if tokenId is 0, it is owned by address(this) as per all other tests, see `setup()` function
        if (_voucher.value == 0)
            IERC721Sovereign(_ERC721).transferFrom(address(this), _seller, _voucher.value);

        vm.prank(_buyer);

        IERC721Sovereign(_ERC721).lazyBuy{ value: _voucher.price }(
                _voucher,
                _signature,
                "",
                _buyer
            );

        
        // check ownership
        assertEq(IERC721(_ERC721).balanceOf(_buyer), 1, "EOA balance incorrect");
        assertEq(IERC721(_ERC721).ownerOf(_voucher.value), _buyer, "ownerOf failed");
        // check balances
        assertEq(_buyer.balance, buyerBalance - _voucher.price, "collector balance failed");

        assertEq(_seller.balance, sellerBalance + _voucher.price - primarySaleCommissionAmount - royaltyAmount, "lazy buy, seller balance failed"); // checking this contract's balance because it is the one that receives the funds, i.e. token was not lazy minted hence owner is contract
        if (primarySaleCommissionAmount > 0)
            assertEq(NINFA_FEES_MULTISIG.balance, primarySaleCommissionAmount, "NINFA_FEES_MULTISIG balance failed");
        if (isSecondarySale)
            assertEq(royaltyRecipient.balance, royaltyRecipientBalance + royaltyAmount, "royaltyRecipient balance failed");
    }

    function _testVoidVoucher(address _ERC721,
        bytes32 _digest,
        bytes memory _signature) internal {

        bytes32[] memory digests = new bytes32[](1);
        digests[0] = _digest;

        bytes[] memory signatures = new bytes[](1);
        signatures[0] = _signature;

        vm.prank(MINTER);
        IERC721Sovereign(_ERC721).voidVouchers(digests, signatures);
    }







}

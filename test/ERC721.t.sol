// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import "test/helpers/ERC721Validator.sol";
import "src/token/ERC721/presets/ERC721Sovereign.sol";
import "src/factory/CuratedFactory.sol";



contract ERC721Test is ERC721Validator {
    ERC721Sovereign private _ERC721SovereignMaster;
    ERC721Sovereign private _ERC721SovereignClone;
    CuratedFactory private _ninfaFactory;


    /// @dev the deployer is the account that deploys the CuratedFactory and grants the CURATOR_ROLE to the curator
    address private immutable _deployer;
    /// @dev the curator is the account that deploys the CuratedFactory and grants the MINTER_ROLE to this contract
    address private immutable _curator;
    /// @dev the minter is the account for testing lazy mint signatures from an EOA, normal minting is done from the
    /// testing contract (this)
    address private immutable _minter;
    /// @dev the collector is the account for testing buying operations using ETH, or for secondary sales
    address private immutable _collector;
    /// @dev the operator is the account for testing operator approval and transfers
    address private immutable _operator;
    /// @dev the anon is the account for testing unauthorised operations
    address private immutable _anon;
    /// @dev the feesRecipient is the account for testing fees collected by lazy minting and buying in the context of
    /// ERC721Sovereign, which may be set to a different account than the (default) minter/deployer
    address private immutable _feesRecipient;

    address private _erc721SovereignAddress;
    uint256 private immutable _minterPK;
    uint256 private immutable _collectorPK;

    /// @dev strings and arrays cannot be immutable

    string private ANVIL_MNEMONIC;
    string private NAME;
    string private SYMBOL;

    // Royalties and commissions

    uint16[] private _royaltyBps = new uint16[](0);
    uint16[] private _primarySaleBps = new uint16[](0);
    uint16[] private _emptyBps = new uint16[](0);

    address[] private _royaltyRecipients = new address[](0);
    address[] private _primarySaleRecipients = new address[](0);
    address[] private _emptyRecipients = new address[](0);

    /*----------------------------------------------------------*|
    |*  # SETUP                                                 *|
    |*----------------------------------------------------------*/

    constructor() {
        ANVIL_MNEMONIC = vm.envString("ANVIL_MNEMONIC");
        NAME = "ninfa.io";
        SYMBOL = NAME;

        (_deployer,) = deriveRememberKey(ANVIL_MNEMONIC, 0);
        (_curator,) = deriveRememberKey(ANVIL_MNEMONIC, 1);
        (_minter, _minterPK) = deriveRememberKey(ANVIL_MNEMONIC, 2);
        (_collector, _collectorPK) = deriveRememberKey(ANVIL_MNEMONIC, 3);
        (_operator,) = deriveRememberKey(ANVIL_MNEMONIC, 4);
        (_anon,) = deriveRememberKey(ANVIL_MNEMONIC, 5);
        (_feesRecipient,) = deriveRememberKey(ANVIL_MNEMONIC, 6);

        _royaltyBps.push(1000);
        _primarySaleBps.push(1500);
        _royaltyRecipients.push(address(this));
        _primarySaleRecipients.push(NINFA_FEES_MULTISIG);
    }

    function setUp() public {
        _ERC721SovereignClone = new ERC721Sovereign(address(this));
        _ERC721SovereignClone.initialize(abi.encode("Ninfa", "NINFA", address(this)));


        // todo write solidity function for generating tokenURI 32 bytes hash from base58 encoded IPFS hash

        _ERC721SovereignClone.mint(
            address(this), abi.encode(TOKEN_ID_0_URI, abi.encode(_royaltyRecipients, _royaltyBps, ""))
        );
        /// @dev grant the MINTER_ROLE to the minter account, only needed for testing lazy minting signatures from an
        /// EOA, i.e. not signed by this contract (ERC-1271)
        _ERC721SovereignClone.grantRole(MINTER_ROLE, _minter);

        /**
         * @dev send some ether for testing
         */
        vm.deal(address(this), 100 ether);
        vm.deal(_collector, 100 ether);
        vm.deal(_anon, 100 ether); // ETH needed for secondary sales
    }

    function _getDigestAndSignature(
        EncodeType.Voucher memory _voucher,
        uint256 _PK
    )
        private
        view
        returns (bytes32 digest, bytes memory signature)
    {
        digest = _ERC721SovereignClone.getTypedDataDigest(_voucher);
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(_PK, digest);
        signature = abi.encodePacked(r, s, v);
    }

    /*----------------------------------------------------------*|
    |*  # ERC-1271                                              *|
    |*----------------------------------------------------------*/

    /*----------------------------------------------------------*|
    |*  # EXTRA TESTS                                           *|
    |*----------------------------------------------------------*/

    function testAccounts() public {
        _testAccounts(_deployer, _curator, _minter, _collector, _operator, _anon, _feesRecipient);
    }

    function testSupportsInterface() public {
        _testSupportsInterface(address(_ERC721SovereignClone));
    }

    /*----------------------------------------------------------*|
    |*  # SOLMATE TESTS                                         *|
    |*----------------------------------------------------------*/

    function invariant_ERC721Metadata() public {
        _invariant_ERC721Metadata(address(_ERC721SovereignClone), NAME, SYMBOL);
    }

    function testMint() public {
        _testMint(address(_ERC721SovereignClone));
    }

    function testBurn() public {
        _testBurn(address(_ERC721SovereignClone));
    }

    function testApprove() public {
        _testApprove(address(_ERC721SovereignClone));
    }

    function testApproveBurn() public {
        _testApproveBurn(address(_ERC721SovereignClone));
    }

    function testApproveAll() public {
        _testApproveAll(address(_ERC721SovereignClone));
    }

    function testTransferFrom() public {
        _testTransferFrom(address(_ERC721SovereignClone));
    }

    function testTransferFromSelf() public {
        _testTransferFromSelf(address(_ERC721SovereignClone));
    }

    function testTransferFromApproveAll() public {
        _testTransferFromApproveAll(address(_ERC721SovereignClone));
    }

    function testSafeTransferFromToEOA() public {
        _testSafeTransferFromToEOA(address(_ERC721SovereignClone));
    }

    function testSafeTransferFromToERC721Recipient() public {
        _testSafeTransferFromToERC721Recipient(address(_ERC721SovereignClone));
    }

    function testSafeTransferFromToERC721RecipientWithData() public {
        _testSafeTransferFromToERC721RecipientWithData(address(_ERC721SovereignClone));
    }

    function testSafeMintToERC721Recipient() public {
        _testSafeMintToERC721Recipient(address(_ERC721SovereignClone), _royaltyRecipients, _royaltyBps);
    }

    function testSafeMintToERC721RecipientWithData() public {
        _testSafeMintToERC721RecipientWithData(address(_ERC721SovereignClone), _royaltyRecipients, _royaltyBps);
    }

    function testFailMintToZero() public {
        _testFailMintToZero(address(_ERC721SovereignClone), _royaltyRecipients, _royaltyBps);
    }

    function testFailDoubleMint() public {
        _testFailDoubleMint(address(_ERC721SovereignClone), _royaltyRecipients, _royaltyBps);
    }

    function testFailBurnUnminted() public {
        _testFailBurnUnminted(address(_ERC721SovereignClone));
    }

    function testFailDoubleBurn() public {
        _ERC721SovereignClone.burn(0);
        _ERC721SovereignClone.burn(0);
    }

    function testFailApproveUnMinted() public {
        _testFailApproveUnMinted(address(_ERC721SovereignClone));
    }

    function testFailApproveUnAuthorized() public {
        _testFailApproveUnAuthorized(address(_ERC721SovereignClone));
    }

    function testFailTransferFromUnOwned() public {
        _testFailTransferFromUnOwned(address(_ERC721SovereignClone));
    }

    function testFailTransferFromWrongFrom() public {
        _testFailTransferFromWrongFrom(address(_ERC721SovereignClone));
    }

    function testFailTransferFromToZero() public {
        _testFailTransferFromToZero(address(_ERC721SovereignClone));
    }

    function testFailTransferFromNotOwner() public {
        _testFailTransferFromNotOwner(address(_ERC721SovereignClone));
    }

    function testFailSafeTransferFromToNonERC721Recipient() public {
        _testFailSafeTransferFromToNonERC721Recipient(address(_ERC721SovereignClone));
    }

    function testFailSafeTransferFromToNonERC721RecipientWithData() public {
        _testFailSafeTransferFromToNonERC721RecipientWithData(address(_ERC721SovereignClone));
    }

    function testFailSafeTransferFromToRevertingERC721Recipient() public {
        _testFailSafeTransferFromToRevertingERC721Recipient(address(_ERC721SovereignClone));
    }

    function testFailSafeTransferFromToRevertingERC721RecipientWithData() public {
        _testFailSafeTransferFromToRevertingERC721RecipientWithData(address(_ERC721SovereignClone));
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnData() public {
        _testFailSafeTransferFromToERC721RecipientWithWrongReturnData(address(_ERC721SovereignClone));
    }

    function testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData() public {
        _testFailSafeTransferFromToERC721RecipientWithWrongReturnDataWithData(address(_ERC721SovereignClone));
    }

    function testFailSafeMintToNonERC721Recipient() public {
        _testFailSafeMintToNonERC721Recipient(address(new NonERC721Recipient()), _royaltyRecipients, _royaltyBps);
    }

    function testFailSafeMintToNonERC721RecipientWithData() public {
        _testFailSafeMintToNonERC721RecipientWithData(
            address(new NonERC721Recipient()), _royaltyRecipients, _royaltyBps
        );
    }

    function testFailSafeMintToRevertingERC721Recipient() public {
        _testFailSafeMintToRevertingERC721Recipient(
            address(new RevertingERC721Recipient()), _royaltyRecipients, _royaltyBps
        );
    }

    function testFailSafeMintToRevertingERC721RecipientWithData() public {
        _testFailSafeMintToRevertingERC721RecipientWithData(
            address(new RevertingERC721Recipient()), _royaltyRecipients, _royaltyBps
        );
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnData() public {
        _testFailSafeMintToERC721RecipientWithWrongReturnData(
            address(new WrongReturnDataERC721Recipient()), _royaltyRecipients, _royaltyBps
        );
    }

    function testFailSafeMintToERC721RecipientWithWrongReturnDataWithData() public {
        _testFailSafeMintToERC721RecipientWithWrongReturnDataWithData(
            address(new WrongReturnDataERC721Recipient()), _royaltyRecipients, _royaltyBps
        );
    }

    function testFailBalanceOfZeroAddress() public view {
        _testFailBalanceOfZeroAddress(address(_ERC721SovereignClone));
    }

    function testFailOwnerOfUnminted() public view {
        _ERC721SovereignClone.ownerOf(1);
    }

    /*----------------------------------------------------------*|
    |*  # LAZY MINT AND LAZY BUY                                *|
    |*----------------------------------------------------------*/

    /**
     * @dev minting new tokenId and buying it via lazyMint
     * Voucher is signed by EOA and the token is minted to EOA
     */
    function testLazyMintFromEOA2EOA() public {
        EncodeType.Voucher memory voucher = EncodeType.Voucher(
            ONE_BYTES32, // voucher.tokenURI MUST never be empty
            1 ether,
            type(uint32).max,
            0,
            block.timestamp, // salt
            address(0), // buyerAddress
            address(0),
            _royaltyBps,
            _primarySaleBps,
            _royaltyRecipients,
            _primarySaleRecipients
        );

        (, bytes memory signature) = _getDigestAndSignature(voucher, _minterPK);

        _testLazyMint(_erc721SovereignAddress, _minter, _collector, voucher, signature);
    }

    /**
     * @dev buying tokenId 0 (minted via mint() during setup) from minter to collector
     * Voucher is signed by EOA and the token is safe transferred to EOA
     */
    function testLazyBuyFromEOA2EOA() public {
        EncodeType.Voucher memory voucher = EncodeType.Voucher(
            ZERO_BYTES32,
            2 ether,
            type(uint32).max,
            0, // value, set to 0 when minting ERC721 and set to tokenId when buying ERC721 (which could be 0, which it
                // is in this case)
            block.timestamp,
            address(0),
            address(0),
            _emptyBps,
            _primarySaleBps, // since lazyBuy is being used for a primary sale, set sale bps
            _emptyRecipients,
            _primarySaleRecipients // since lazyBuy is being used for a primary sale, set sale recipients
        );

        (, bytes memory signature) = _getDigestAndSignature(voucher, _minterPK);


        _testLazyBuy(_erc721SovereignAddress, _minter, _collector, voucher, signature);
    }

    /**
     * @dev test calling voidVoucher() external function from signer, although any account with MINTER_ROLE could call
     * it
     * if the call to lazyMint fails, the test passes, i.e. the voucher is voided
     */
    function testFailVoidVoucherLazyMint() public {
        // Vanilla vcucher example, doesn't matter what the voucher is, since it will be voided explicitly
        // the following voucher would be perfectly valid if used for minting, i.e. if the voucher was not voided
        EncodeType.Voucher memory voucher = EncodeType.Voucher(
            ONE_BYTES32,
            0,
            type(uint32).max,
            0,
            0,
            address(0),
            address(0),
            _emptyBps,
            _emptyBps,
            _emptyRecipients,
            _emptyRecipients
        );

        (bytes32 digest, bytes memory signature) = _getDigestAndSignature(voucher, _minterPK);

        _testVoidVoucher(_erc721SovereignAddress, digest, signature);

        _testLazyMint(_erc721SovereignAddress, _minter, _collector, voucher, signature);
    }

    /**
     * @dev test calling voidVoucher() external function from signer, although any account with MINTER_ROLE could call
     * it
     * if the call to lazyMint fails, the test passes, i.e. the voucher is voided
     */
    function testFailVoidVoucherLazyBuy() public {
        // same vouches as in testLazybuy()
        EncodeType.Voucher memory voucher = EncodeType.Voucher(
            ZERO_BYTES32,
            2 ether,
            type(uint32).max,
            0, // value, set to 0 when minting ERC721 and set to tokenId when buying ERC721 (which could be 0, which it
                // is in this case)
            block.timestamp,
            address(0),
            address(0),
            _emptyBps,
            _primarySaleBps, // since lazyBuy is being used for a primary sale, set sale bps
            _emptyRecipients,
            _primarySaleRecipients // since lazyBuy is being used for a primary sale, set sale recipients
        );

        (bytes32 digest, bytes memory signature) = _getDigestAndSignature(voucher, _minterPK);

        _testVoidVoucher(_erc721SovereignAddress, digest, signature);

        _testLazyBuy(_erc721SovereignAddress, _minter, _collector, voucher, signature);
    }

    /**
     * @dev test fails because the tokenURI is required to be unique by the ERC721Sovereign implementation,
     * in order to prevent vouchers from being reused
     */
    function testFailLazyMintReplay() public {
        EncodeType.Voucher memory voucher = EncodeType.Voucher(
            ONE_BYTES32,
            1 ether,
            type(uint32).max,
            0,
            block.timestamp, // salt
            address(0), // buyerAddress
            address(0),
            _royaltyBps,
            _primarySaleBps,
            _royaltyRecipients,
            _primarySaleRecipients
        );

        (, bytes memory signature) = _getDigestAndSignature(voucher, _minterPK);

        _testLazyMint(_erc721SovereignAddress, _minter, _collector, voucher, signature);

        _testLazyMint(_erc721SovereignAddress, _minter, _collector, voucher, signature);
    }

    function testFailLazyBuyReplay() public {
        EncodeType.Voucher memory voucher = EncodeType.Voucher(
            ZERO_BYTES32,
            2 ether,
            type(uint32).max,
            0, // value, set to 0 when minting ERC721 and set to tokenId when buying ERC721 (which could be 0, which it
                // is in this case)
            block.timestamp,
            address(0),
            address(0),
            _emptyBps,
            _primarySaleBps, // since lazyBuy is being used for a primary sale, set sale bps
            _emptyRecipients,
            _primarySaleRecipients // since lazyBuy is being used for a primary sale, set sale recipients
        );

        (, bytes memory signature) = _getDigestAndSignature(voucher, _minterPK);

        _testLazyBuy(_erc721SovereignAddress, _minter, _collector, voucher, signature);

        _testLazyBuy(_erc721SovereignAddress, _minter, _collector, voucher, signature);
    }

    function testERC721LazyMintLazyBuy() public {
        EncodeType.Voucher memory voucher = EncodeType.Voucher(
            ONE_BYTES32, // voucher.tokenURI MUST never be empty when minting
            1 ether,
            type(uint32).max,
            0,
            block.timestamp, // salt
            address(0), // buyerAddress
            address(0),
            _emptyBps,
            _primarySaleBps,
            _emptyRecipients,
            _primarySaleRecipients
        );

        (, bytes memory signature) = _getDigestAndSignature(voucher, _minterPK);

        _testLazyMint(_erc721SovereignAddress, _minter, _collector, voucher, signature);

        voucher = EncodeType.Voucher(
            ZERO_BYTES32,
            2 ether,
            type(uint32).max,
            1, // lazy minted tokenId 1
            block.timestamp,
            address(0),
            address(0),
            _emptyBps,
            _emptyBps,
            _emptyRecipients,
            _emptyRecipients
        );

        (, signature) = _getDigestAndSignature(voucher, _collectorPK);

        _testLazyBuy(_erc721SovereignAddress, _collector, _anon, voucher, signature);
    }

    // receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

abstract contract Constants {
    struct Offer {
        uint256 tokenId;
        uint256 unitPrice;
        uint256 erc1155Value;
        address collection;
        address from; // buyer
    }

    struct Order {
        uint256 tokenId;
        uint256 unitPrice;
        uint256 erc1155Value;
        uint256 commissionBps;
        address commissionReceiver;
        address collection;
        address from;
        address operator;
    }

    struct Auction {
        address operator;
        address seller;
        address collection;
        address bidder;
        address commissionReceiver;
        uint256 commissionBps;
        uint256 tokenId;
        uint256 bidPrice;
        uint256 end;
    }

    address internal constant LORENZO = 0xf9d7F42FbE699D026618d62657208c38a4604ca2;
    address internal constant BRANDO = 0x8c729d8c76BeeCd472E942407Ad30Cc95c652A29; // Brando
    address internal constant PIETRO = 0x269232926750A0306dD4494BedB5f950a4fE2e29; // Pietro
    address internal constant CARLO = 0xbD4567400EF90637F41E45f0E2E989E11c4E8Bf5; // Ciaki
    address internal constant COSIMO = 0x0F92D39489433041ceF0D7d4fD322434A941b068; // Cosmic
    address internal constant NINFA_FEES_MULTISIG = 0x229946a96C34edD89c06d23DCcbFA259E9752a7c;
    address internal constant LAZY_WHITELIST_SIGNER = 0x2EbdcB97AE594a8c8cEE00f08fe10D887DF28fB1;

    address internal constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    address internal constant LAZY_SIGNER_MAINNET = 0x4b99321f211375049F56f230F2a03BFe10ac9039;

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant CURATOR_ROLE = keccak256("CURATOR_ROLE");
    bytes32 internal constant MARKETPLACE_ROLE = keccak256("MARKETPLACE_ROLE");
    bytes32 internal constant ZERO_BYTES32 = 0x0000000000000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant ONE_BYTES32 = 0x1111111111111111111111111111111111111111111111111111111111111111;
    // todo generate URIs dynamically in tests
    bytes32 internal constant TOKEN_ID_0_URI = 0xe8bd59d52eb01940e086e87d941dab4d3084a7ffe1f877a1ea27edf10e48768a;
    bytes32 internal constant TOKEN_ID_1_URI = 0x3ad231046a98699f721d555f83fd8a7a02adaf294969d72950694ece70d58d84;

    address internal constant ERC1155_COMMUNAL = 0x4F1D84FC1028A6Bd43AEf8Ae03395255c3105e31;
    address internal constant DOMUS = 0xe28781EeC3BB69C242AEd71c7Ea0754a7e795248;
    address internal constant ERC721_Sovereign = 0x86A30746D6E4B3E96Be8364f162EB1E146eBBe4C;
    address internal constant ERC1155_Sovereign = 0xa7904C92703375EACedbf81C223f9eC3b2A534bA;
    address internal constant FACTORY = 0x61b98ACbfc23326Cfe296f380B5aa3e5Adcc5238;
    address internal constant ERC721_SOVEREIGN_V1_MAINNET_EXAMPLE = 0x0842E31f6Ed20454faDa8E7B9F18ECDd41621110;
    address internal constant MARKETPLACE_V2 = 0xfee1F4596B40b13A8B8723478Ff87Bd7C62b5980;
    address internal constant ENGLISH_AUCTION_V2 = 0x93425B5a58d1dD17C6BF5DBe4944039CD2656241;
    address internal constant PAYMENT_SPLITTER = 0x32d686928608885E33CBE93875aD3F15932caF04;
    address internal constant NINFA_LAZY_CURATOR = 0x4919E58C8c285cA882C46cD98181286EFc1B6A84;
    address internal constant ROYALTY_REGISTRY_MAINNET = 0xaD2184FB5DBcfC05d8f056542fB25b04fa32A95D;
    address internal constant MARKET_REGISTRY_MAINNET = 0x167A296135c0067903d4C099806405f6c316442E;
    address payable internal constant WHITELIST_MAINNET = payable(0xEdE30a830C6bD69ABb358976B108b3596e5DA7c9);

    address internal constant MARKETPLACE_V2_SEPOLIA = 0x38D5EF5C03AA7d943546B4dE87ad2763eCE85b50;
    address internal constant ENGLISH_AUCTION_V2_SEPOLIA = 0xBcb0bBD9fe3266a00621f374a6b4d07D1b22B203;
    address internal constant ERC1155_REWARDS_SEPOLIA = 0xEC0d2AcE6ec96C11a624b6fcC62974033cd2e199;

    // TEST ANVIL_MNEMONIC ACCOUNTS
    address internal constant DEPLOYER = 0xCe48Ce8d62745Ba60429Cb1397b2EEb09F3eb0ff; // Account 0
    address internal constant CURATOR = 0x74018d04bBc7a40ed7CFEE03F43A59a2b37D6AB3; // Account 1
    address internal constant MINTER = 0xb27965AB2E849034D3770f75fbdfc38D5042685A; // Account 2
    address internal constant COLLECTOR = 0x3cFEd5CCaFf91d14c3B9e738F087E5c06E1525eF; // Account 3
    address internal constant OPERATOR = 0xb0aCCdFc7852180861560a902AcE10cD8c215dE0; // Account 4
    address internal constant ANON = 0xeADC307965F026F8D8bFF214EB1A7667A33d619f; // Account 5
    address internal constant FEES_RECIPIENT = 0x5bA2bDcA06D87c78152927c900ca9a7F152BeeB8; // Account 6
    address internal constant LAZY_SIGNER = 0xe5E0Ff510A46C6dc27F2E56eBE5799bE0Cb801Bd; // Account 7
    uint256 internal constant LAZY_SIGNER_PK =
        13_266_260_542_021_635_864_469_793_571_673_249_069_619_439_717_418_594_164_054_558_747_199_608_612_914;

    address internal constant FACTORY_GOERLI = 0x22de36aa425898fDfe37fA6e8b4f174f3994Bd1B;
    address internal constant ERC721_Sovereign_GOERLI = 0x94a5AcB1cAaA49d15f148082B6e5008155c1D7C0;
    address internal constant ERC1155_Sovereign_GOERLI = 0x241D1612418323aD40c60a024fcedCdabCb6b831;
    address internal constant PAYMENT_SPLITTER_GOERLI = 0x30499059a7e2439a61e6dbd73A1ca7Daf4F0B46F;
    address internal constant ERC1155_COMMUNAL_GOERLI = 0x6EE256086bB2e3349e8C76F34aDf7B740C2ed8a4;
    address internal constant DOMUS_GOERLI = 0xaD08D7E1c94656Ddb8aEc30e8700Af7Ecd5DDE9E;
    address internal constant MARKET_REGISTRY_GOERLI = 0xff3F537951bAD2192bfB82c699ed73Ad9B0C7771;
    address internal constant MARKETPLACE_V2_GOERLI = 0xF9eD646FAe8B04A58E55de280F25205bbD277985;
    address internal constant MARKETPLACE_V2_5_GOERLI = 0x4a22c757041d7dAf8f9f130E4Dc1E88B2cBf9F1a;
    address internal constant AUCTION_V2_GOERLI = 0x3981C894207f4Dc0e2D3ef85D9825D6Bd2Ef0050;
    address internal constant AUCTION_V2_5_GOERLI = 0xC24F41332Ad6968C46d8BE93fA93a131a5675ee8;
    address internal constant LAZY_CURATOR_GOERLI = 0x2d436Abe000e7ed9291Aa5f9B068AC86B49D3956;
    address internal constant LAZY_WHITELISTER_GOERLI = 0xb2De758BD5E4B1a18B72D6BC660Ca4F6c5Bc4798;
    address internal constant REWARDS_GOERLI = 0x01ccA4F716e7c68E3feD090320a240F23d8Dddfa;
}

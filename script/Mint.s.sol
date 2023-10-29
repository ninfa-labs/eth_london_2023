// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import "src/token/ERC721/presets/ERC721Sovereign.sol";
import { stdJson } from "forge-std/StdJson.sol";

contract Goerli is Script {
    ERC721Sovereign private _ERC721Sovereign;
    string constant METADATA_IPFS_CID = "./src/assets/bytes32CIDs.txt";
    bytes32[] public hashes; // State variable to store the bytes32 hashes

    uint16[] private _royaltyBps = new uint16[](0);
    address[] private _royaltyRecipients = new address[](0);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("GOERLI_DEPLOYER_PK");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        
        // Read and instantiate contract address from ./broadcast/DeployERC721.s.sol/5/run-latest.json
        string memory json = vm.readFile("./broadcast/DeployERC721.s.sol/5/run-latest.json");
        (address deployedAddress) = abi.decode(vm.parseJson(json, ".deployedTo"), (address));
        _ERC721Sovereign = ERC721Sovereign(deployedAddress);

        // Read bytes32 hashes from file
        while (vm.exists(METADATA_IPFS_CID)) {
            string memory line = vm.readLine(METADATA_IPFS_CID);
            if (bytes(line).length == 0) {
                break; // End of file or empty line detected
            }
            bytes32 hash = parseBytes32(line);
            hashes.push(hash);
        }

        for (uint256 i = 0; i < hashes.length; i++) {
            _ERC721Sovereign.mint(deployer, abi.encode(hashes[i], abi.encode(_royaltyRecipients, _royaltyBps, "")));
        }

        console2.log("Number of metadata hashes read:", hashes.length);
    }

    function parseBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}

contract Anvil is Script {
    ERC721Sovereign private _ERC721Sovereign;
    string constant METADATA_IPFS_CID = "./src/assets/bytes32CIDs.txt";
    bytes32[] public hashes; // State variable to store the bytes32 hashes

    uint16[] private _royaltyBps = new uint16[](0);
    address[] private _royaltyRecipients = new address[](0);

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_ACCOUNT_0_PK");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        

        // Read the JSON file
        string memory json = vm.readFile("./broadcast/DeployERC721.s.sol/31337/run-latest.json");

        // Parse the contract address
        bytes memory deployedAddressBytes = vm.parseJson(json, ".transactions[0].contractAddress");
        address deployedAddress = abi.decode(deployedAddressBytes, (address));

        // Log the address to the console
        console2.log("Deployed Contract Address:", deployedAddress);

        // Instantiate the ERC721Sovereign contract
        _ERC721Sovereign = ERC721Sovereign(deployedAddress);

        // Read bytes32 hashes from file
        while (vm.exists(METADATA_IPFS_CID)) {
            string memory line = vm.readLine(METADATA_IPFS_CID);
            if (bytes(line).length == 0) {
                break; // End of file or empty line detected
            }
            bytes32 hash = parseBytes32(line);
            hashes.push(hash);
        }

        for (uint256 i = 0; i < hashes.length; i++) {
            _ERC721Sovereign.mint(deployer, abi.encode(hashes[i], abi.encode(_royaltyRecipients, _royaltyBps, "")));
        }

        console2.log("Number of metadata hashes read:", hashes.length);
    }

    function parseBytes32(string memory source) public pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }
}

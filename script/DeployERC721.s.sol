// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

// import "forge-std/Test.sol";
import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";
import "src/token/ERC721/presets/ERC721Sovereign.sol";

contract Anvil is Script {
    ERC721Sovereign private _ERC721Sovereign;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_ACCOUNT_0_PK");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        _ERC721Sovereign = new ERC721Sovereign(deployer);
        _ERC721Sovereign.initialize(abi.encode("Ninfa", "NINFA", deployer));
        console2.log("ERC721Sovereign", address(_ERC721Sovereign));

    }

}

contract Goerli is Script {
    ERC721Sovereign private _ERC721Sovereign;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("GOERLI_DEPLOYER_PK");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);

        _ERC721Sovereign = new ERC721Sovereign(deployer);
        _ERC721Sovereign.initialize(abi.encode("Ninfa", "NINFA", deployer));
        console2.log("ERC721Sovereign", address(_ERC721Sovereign));

       
    }

}
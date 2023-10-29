# Social Login + MPC wallet + Account Abstracion

## Setup

### Install Node Modules

`pnpm i`

### Foundry Installation

[Install Foundry Docs](https://book.getfoundry.sh/getting-started/installation)

### Install smart contract libraries

`forge install`

### Compile Contracts

'forge build'

### Create .env

Register an infura account and create an IPFS project. Register a development account with Lit to get your API key,
otherwise try with "1234567890", or search for existing API keys hardcoded in some of https://github.com/LIT-Protocol/
example apps ;)

```
# Private Keys
ANVIL_ACCOUNT_0_PK="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
ANVIL_MNEMONIC="test test test test test test test test test test test junk"
# API KEYS
INFURA_IPFS_PROJECT_ID="<your_project_id>"
INFURA_IPFS_PROJECT_SECRET="<your_project_secret>"
INFURA_API_KEY="
LIT_API_KEY="1234567890"
```

### Run Anvil

In a new terminal start the development blockchain

`anvil`

### Run Deployment Script

`forge script script/DeployERC721.s.sol:Anvil --fork-url=localhost -vv --broadcast`

or

`forge script script/DeployERC721.s.sol:Goerli --fork-url=goerli -vv --broadcast`

### Run IPFS script

Run the node script providing as arguments the chain id (31337 for anvil, 5 for Goerli, etc) and the ERC721 contract
address, found in `./broadcast/DeployERC721.s.sol/<chainId>/run-latest.json` under `transactions[0].contractAddress`

`node src/utils/ipfs.mjs <chainId> <deployed_contract_address>`

When using Anvil the contract address will always be the same, as long as the deployment script is run on a fresh Anvil
instance, i.e. the CREATE tx is the first on the local blockchain and the deployer is account[0]

`node src/utils/ipfs.mjs 31337 0x5FbDB2315678afecb367f032d93F642f64180aa3`

The script reads images already contained in `./src/assets/gallery/*` and for each of them generates a metadata file and
uploads it on IPFS, then creates `./src/assets/nftsData.js` and populates it with useful data about each NFT, this file
acts as a fake backend for demo purposes. It also creates `./src/assets/bytes32CIDs.txt` containing the metadata IPFS
CIDv1 converted to bytes32, used by the minting script next.

### Run Deployment Script

`forge script script/Mint.s.sol:Anvil --fork-url=localhost -vv --broadcast`

or

`forge script script/Mint.s.sol:Goerli --fork-url=goerli -vv --broadcast`

This script will iterate each line in `./src/assets/bytes32CIDs.txt` and mint a new token id for each NFT published on
IPFS in the previous step.

### Get a Google API Key

used for social login // TODO

### Start Vite

`vite`

import React, { useEffect, useState } from "react";
import { IProvider } from "@web3auth/base";
import nftData from "../assets/nftdata.json";
import { useWalletAddress } from "@etherspot/transaction-kit";
import { ethers, Contract } from "ethers";
import { Dialog } from "@mui/material";

const EtherspotMain = ({
  provider,
  contract,
  signer,
}: {
  provider: IProvider | null;
  contract: Contract | null;
  signer: ethers.Signer | null;
}) => {
  const etherspotAddress = useWalletAddress("etherspot-prime", 5);
  const [selectedNft, setSelectedNft] = useState<
    (typeof nftData)[number] | null
  >(null);
  return (
    <div
      style={{
        display: "flex",
        width: "100%",
        justifyContent: "center",
      }}
    >
      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: 30,
          marginTop: 30,
        }}
      >
        {nftData.map((nft, i) => (
          <Card
            nft={nft}
            key={i}
            address={etherspotAddress || ""}
            contract={contract}
            handleBuy={setSelectedNft}
          />
        ))}
      </div>
      <BuyModal
        open={selectedNft !== null}
        handleClose={() => setSelectedNft(null)}
        nft={selectedNft!}
        signer={signer}
        userAddress={etherspotAddress || ""}
        contract={contract}
      />
    </div>
  );
};

export default EtherspotMain;

const Card = ({
  nft,
  address,
  contract,
  handleBuy,
}: {
  nft: (typeof nftData)[number];
  address: string;
  contract: Contract | null;
  handleBuy: (nft: (typeof nftData)[number]) => void;
}) => {
  const [isOwner, setIsOwner] = useState(false);
  const [ownerAddress, setOwnerAddress] = useState<string | null>(null);
  useEffect(() => {
    if (!contract || nft.tokenId === null) {
      setIsOwner(false);
      setOwnerAddress(null);
      return;
    }
    const checkOwner = async () => {
      console.log(nft.tokenId);
      const owner = (await contract.ownerOf(nft.tokenId)) as string;
      console.log(nft.tokenId, owner, address);
      setIsOwner(owner.toLowerCase() === address.toLowerCase());
      setOwnerAddress(owner);
    };
    checkOwner();
  }, [address]);
  return (
    <div
      style={{
        width: 400,
        height: 600,
        display: "flex",
        flexDirection: "column",
        border: "1px blueviolet solid",
        borderRadius: 24,
        padding: 1,
      }}
    >
      <img
        src={
          nft.imageUri.replace("ipfs://", "https://ipfs.io/ipfs/") + "/nft.jpg"
        }
        style={{
          width: "100%",
          height: "100%",
          objectFit: "cover",
          borderRadius: 24,
        }}
      />
      <div
        style={{
          padding: 10,
        }}
      >
        <p>test</p>
        <p>
          owner:{" "}
          {ownerAddress
            ? ownerAddress
            : "0xf9d7F42FbE699D026618d62657208c38a4604ca2"}
        </p>
        <button
          style={{
            border: "none",
            backgroundColor: "#532be2",
            color: "white",
            padding: "5px 20px",
            borderRadius: 24,
            cursor: "pointer",
            fontSize: 16,
            opacity: !isOwner ? 1 : 0,
            pointerEvents: !isOwner ? "all" : "none",
          }}
          onClick={() => handleBuy(nft)}
        >
          buy
        </button>
      </div>
    </div>
  );
};

const BuyModal = ({
  open,
  handleClose,
  nft,
  signer,
  userAddress,
  contract,
}: {
  open: boolean;
  handleClose: () => void;
  nft: (typeof nftData)[number];
  signer: ethers.Signer | null;
  userAddress: string;
  contract: Contract | null;
}) => {
  const [isBuying, setIsBuying] = useState(false);
  const [txHash, setTxHash] = useState<string | null>(null);

  const handleBuy = async () => {
    if (!signer || !contract || userAddress === "") return;
    const tx = await contract
      .connect(signer)
      .transferFrom(
        "0xf9d7F42FbE699D026618d62657208c38a4604ca2",
        userAddress,
        nft.tokenId
      );
    console.log(tx);
    setIsBuying(false);
    setTxHash(tx.hash);
  };

  return (
    <Dialog open={open} onClose={handleClose}>
      <div
        style={{
          height: "80%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          margin: 30,
        }}
      >
        Buy your first nft with fiat through a third party service
        {txHash ? <p>{txHash}</p> : null}
        {isBuying ? <p>buying...</p> : null}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "flex-end",
            gap: 10,
          }}
        >
          <button
            onClick={() => {
              handleClose();
            }}
            style={{
              border: "none",
              backgroundColor: "#532be2",
              color: "white",
              padding: "5px 20px",
              borderRadius: 24,
              cursor: "pointer",
              fontSize: 16,
            }}
          >
            close
          </button>
          <button
            // onClick={handleClose}
            style={{
              border: "none",
              backgroundColor: "#532be2",
              color: "white",
              padding: "5px 20px",
              borderRadius: 24,
              cursor: "pointer",
              fontSize: 16,
            }}
            onClick={handleBuy}
          >
            buy
          </button>
        </div>
      </div>
    </Dialog>
  );
};

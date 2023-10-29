import React, { useEffect, useState } from "react";
import { IProvider } from "@web3auth/base";
import nftData from "../assets/nftdata.json";
import { useWalletAddress } from "@etherspot/transaction-kit";
import { ethers, Contract } from "ethers";

const EtherspotMain = ({
  provider,
  contract,
}: {
  provider: IProvider | null;
  contract: Contract | null;
}) => {
  const etherspotAddress = useWalletAddress("etherspot-prime", 5);
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
          />
        ))}
      </div>
    </div>
  );
};

export default EtherspotMain;

const Card = ({
  nft,
  address,
  contract,
}: {
  nft: (typeof nftData)[number];
  address: string;
  contract: Contract | null;
}) => {
  const [isOwner, setIsOwner] = useState(false);
  useEffect(() => {
    if (!contract || nft.tokenId === null) {
      setIsOwner(false);
      return;
    }
    const checkOwner = async () => {
      console.log(nft.tokenId);
      const owner = (await contract.ownerOf(nft.tokenId)) as string;
      console.log(nft.tokenId, owner, address);
      setIsOwner(owner.toLowerCase() === address.toLowerCase());
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
        >
          buy
        </button>
      </div>
    </div>
  );
};

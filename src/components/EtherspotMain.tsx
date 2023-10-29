import React, { useEffect, useState } from "react";
import { IProvider } from "@web3auth/base";
import nftData from "../assets/nftdata.json";
import { useWalletAddress } from "@etherspot/transaction-kit";

const EtherspotMain = ({ provider }: { provider: IProvider | null }) => {
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
            isOwner={
              etherspotAddress !== undefined &&
              nft.owner.toLowerCase() !== etherspotAddress.toLowerCase()
            }
          />
        ))}
      </div>
    </div>
  );
};

export default EtherspotMain;

const Card = ({
  nft,
  isOwner,
}: {
  nft: (typeof nftData)[number];
  isOwner: boolean;
}) => {
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
            opacity: isOwner ? 1 : 0,
            pointerEvents: isOwner ? "all" : "none",
          }}
        >
          buy
        </button>
      </div>
    </div>
  );
};

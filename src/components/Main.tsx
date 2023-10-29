import React, { useEffect, useState } from "react";
import { IProvider } from "@web3auth/base";
import nftData from "../assets/nftdata.json";

const Main = ({ provider }: { provider: IProvider | null }) => {
  return (
    <>
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
            <Card nft={nft} key={i} />
          ))}
        </div>
      </div>
    </>
  );
};

export default Main;

const Card = ({ nft }: { nft: (typeof nftData)[number] }) => {
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
          }}
        >
          buy
        </button>
      </div>
    </div>
  );
};

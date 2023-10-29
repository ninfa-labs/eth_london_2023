import React, { useEffect, useState } from "react";
import { IProvider } from "@web3auth/base";
import nftData from "../assets/nftdata.json";
import { Contract } from "ethers";

const Main = ({ contract }: { contract: Contract | null }) => {
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
            <Card nft={nft} key={i} contract={contract} />
          ))}
        </div>
      </div>
    </>
  );
};

export default Main;

const Card = ({
  nft,
  contract,
}: {
  nft: (typeof nftData)[number];
  contract: Contract | null;
}) => {
  const [ownerAddress, setOwnerAddress] = useState<string | null>(null);
  useEffect(() => {
    if (!contract || nft.tokenId === null) {
      setOwnerAddress(null);
      return;
    }
    const checkOwner = async () => {
      const owner = (await contract.ownerOf(nft.tokenId)) as string;
      setOwnerAddress(owner);
    };
    checkOwner();
  }, [nft.tokenId]);
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
          }}
        >
          buy
        </button>
      </div>
    </div>
  );
};

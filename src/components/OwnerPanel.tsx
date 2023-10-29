import React, { useState } from "react";
import nftData from "../assets/nftdata.json";
import { useWalletAddress } from "@etherspot/transaction-kit";
import {
  EtherspotContractTransaction,
  EtherspotBatches,
  EtherspotBatch,
  useEtherspotTransactions,
} from "@etherspot/transaction-kit";
import { Dialog } from "@mui/material";
import ER271Sovereign from "../assets/ERC721SovreignLazyMint.abi.json";

const contractAddress = "0x091541AC5b5B1BCBd879F4dCD07B5F01007aBA7B"; // hardcoded for simplicity

const OwnerPanel = () => {
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
        {nftData.map((nft, i) => {
          if (!etherspotAddress) return null;
          if (nft.owner.toLowerCase() !== etherspotAddress.toLowerCase())
            return null;
          return <Card key={i} nft={nft} />;
        })}
      </div>
    </div>
  );
};

export default OwnerPanel;

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
          transfer
        </button>
      </div>
    </div>
  );
};

const TransferModal = ({
  nft,
  open,
  handleClose,
  userAddress,
}: {
  nft: (typeof nftData)[number];
  open: boolean;
  handleClose: () => void;
  userAddress: string;
}) => {
  const { send } = useEtherspotTransactions();
  const [toAddress, setToAddress] = useState<string>("");
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setToAddress(e.target.value);
  };
  if (nft.tokenId === null) {
    return null;
  }
  return (
    <EtherspotBatches
      paymaster={{
        url: "https://arka.etherspot.io",
        api_key: "arka_public_key",
        context: { mode: "sponsor" },
      }}
    >
      <EtherspotBatch>
        <EtherspotContractTransaction
          contractAddress={contractAddress}
          abi={ER271Sovereign}
          methodName={"transferFrom"}
          params={[userAddress, toAddress, nft.tokenId]}
          // value={'0'}
        >
          <Dialog open={open} onClose={handleClose}>
            <div
              style={{
                width: 600,
                height: 400,
              }}
            >
              <div
                style={{
                  height: "80%",
                  display: "flex",
                  flexDirection: "column",
                  justifyContent: "space-between",
                  margin: 30,
                }}
              >
                <label>transfer to:</label>
                <input value={toAddress} onChange={handleChange} />
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "flex-end",
                    gap: 10,
                  }}
                >
                  <button
                    onClick={handleClose}
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
                    onClick={() => {
                      send();
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
                    Transfer
                  </button>
                </div>
              </div>
            </div>
          </Dialog>
        </EtherspotContractTransaction>
      </EtherspotBatch>
    </EtherspotBatches>
  );
};

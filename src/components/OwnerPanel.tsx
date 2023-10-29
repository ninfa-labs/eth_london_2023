import React, { useState, useEffect } from "react";
import nftData from "../assets/nftdata.json";
import { useWalletAddress } from "@etherspot/transaction-kit";
import {
  EtherspotContractTransaction,
  EtherspotBatches,
  EtherspotBatch,
  useEtherspotTransactions,
} from "@etherspot/transaction-kit";
import { Dialog } from "@mui/material";
import { Contract } from "ethers";

const contractAddress = "0x091541AC5b5B1BCBd879F4dCD07B5F01007aBA7B"; // hardcoded for simplicity

const OwnerPanel = ({ contract }: { contract: Contract | null }) => {
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
            key={i}
            nft={nft}
            onClick={setSelectedNft}
            address={etherspotAddress || ""}
            contract={contract}
          />
        ))}
      </div>
      {selectedNft && etherspotAddress ? (
        <TransferModal
          nft={selectedNft}
          open={true}
          handleClose={() => setSelectedNft(null)}
          userAddress={etherspotAddress}
        />
      ) : null}
    </div>
  );
};

export default OwnerPanel;

const Card = ({
  nft,
  onClick,
  contract,
  address,
}: {
  nft: (typeof nftData)[number];
  onClick: (nft: (typeof nftData)[number]) => void;
  contract: Contract | null;
  address: string;
}) => {
  const [isOwner, setIsOwner] = useState(false);
  useEffect(() => {
    if (!contract || nft.tokenId === null) {
      setIsOwner(false);
      return;
    }
    const checkOwner = async () => {
      const owner = (await contract.ownerOf(nft.tokenId)) as string;
      setIsOwner(owner.toLowerCase() === address.toLowerCase());
    };
    checkOwner();
  }, [address]);
  return (
    <div
      style={{
        width: 400,
        height: 600,

        flexDirection: "column",
        border: "1px blueviolet solid",
        borderRadius: 24,
        padding: 1,
        display: isOwner ? "flex" : "none",
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
          onClick={() => {
            console.log("click");
            onClick(nft);
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
  const [toAddress, setToAddress] = useState<string>("");
  const [confirmOpen, setConfirmOpen] = useState<boolean>(false);
  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setToAddress(e.target.value);
  };
  if (nft.tokenId === null) {
    return null;
  }
  if (!confirmOpen) {
    return (
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
                  setConfirmOpen(true);
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
                transfer
              </button>
            </div>
          </div>
        </div>
      </Dialog>
    );
  } else {
    return (
      <ConfirmModal
        nft={nft}
        open={open}
        handleClose={handleClose}
        userAddress={userAddress}
        toAddress={toAddress}
      />
    );
  }
};

const ConfirmModal = ({
  nft,
  open,
  handleClose,
  userAddress,
  toAddress,
}: {
  nft: (typeof nftData)[number];
  open: boolean;
  handleClose: () => void;
  userAddress: string;
  toAddress: string;
}) => {
  const { send, estimate } = useEtherspotTransactions();
  const [sending, setSending] = useState<boolean>(false);
  const [sendSuccess, setSendSuccess] = useState<boolean>(false);

  const handleSend = async () => {
    setSending(true);
    const estimateData = await estimate();
    console.log("Estimate Data:", estimateData);

    if (JSON.stringify(estimateData).includes("reverted")) {
      console.log("Tx reverted! No gas token in account");
      return;
    }
    const res = await send();
    console.log("RES: ", res);
    setSending(false);
    setSendSuccess(true);
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
      onSent={() => console.log("sent")}
    >
      <EtherspotBatch chainId={5}>
        <EtherspotContractTransaction
          contractAddress={contractAddress}
          abi={["function transferFrom(address, address , uint256)"]}
          methodName={"transferFrom"}
          params={[userAddress, toAddress, nft.tokenId]}
          value={"0"}
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
                <p>transfer from: {userAddress}</p>
                <p>transfer to: {toAddress}</p>
                {sending ? <p>sending...</p> : null}
                {sendSuccess ? <p>sent!</p> : null}

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
                      setSendSuccess(false);
                      setSending(false);
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
                    onClick={handleSend}
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
                    confirm
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

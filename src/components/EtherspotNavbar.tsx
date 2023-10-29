import React, { useState } from "react";
import { IProvider } from "@web3auth/base";
import logo from "../assets/ninfa-logo.png";
import { Dialog } from "@mui/material";
import { useWalletAddress } from "@etherspot/transaction-kit";

const EtherspotNavbar = ({
  logout,
  provider,
  changePanel,
  panel,
}: {
  logout: () => void;
  provider: IProvider;
  changePanel: (panel: "main" | "owner") => void;
  panel: "main" | "owner";
}) => {
  const [accountPopupOpen, setAccountPopupOpen] = useState(false);
  const etherspotAddress = useWalletAddress("etherspot-prime", 5);
  return (
    <div
      style={{
        position: "relative",
      }}
    >
      <div
        style={{
          height: 50,
          // width: "100%",
          padding: "10px 30px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          backgroundColor: "blueviolet",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 15,
          }}
        >
          <img
            src={logo}
            style={{
              width: 30,
            }}
          />

          <h1
            style={{
              color: "white",
            }}
          >
            ETH London 2023
          </h1>
        </div>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 15,
          }}
        >
          {panel === "main" ? (
            <button
              onClick={() => changePanel("owner")}
              style={{
                border: "none",
                backgroundColor: "#532be2",
                color: "white",
                padding: "5px 20px",
                borderRadius: 24,
                cursor: "pointer",
                fontSize: 24,
              }}
            >
              your NFTs
            </button>
          ) : (
            <button
              onClick={() => changePanel("main")}
              style={{
                border: "none",
                backgroundColor: "#532be2",
                color: "white",
                padding: "5px 20px",
                borderRadius: 24,
                cursor: "pointer",
                fontSize: 24,
              }}
            >
              all NFTs
            </button>
          )}

          <button
            onClick={() => setAccountPopupOpen(true)}
            style={{
              border: "none",
              backgroundColor: "#532be2",
              color: "white",
              padding: "5px 20px",
              borderRadius: 24,
              cursor: "pointer",
              fontSize: 24,
            }}
          >
            {etherspotAddress
              ? `${etherspotAddress.slice(0, 4)}...${etherspotAddress.slice(
                  etherspotAddress.length - 4,
                  etherspotAddress.length
                )}`
              : ""}
          </button>
        </div>
      </div>
      <AccountModal
        open={accountPopupOpen}
        handleClose={() => setAccountPopupOpen(false)}
        logout={logout}
        address={etherspotAddress || ""}
      />
    </div>
  );
};

export default EtherspotNavbar;

const AccountModal = ({
  open,
  address,
  handleClose,
  logout,
}: {
  open: boolean;
  handleClose: () => void;
  logout: () => void;
  address: string;
}) => {
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
          <p>wallet address: {address}</p>
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
                logout();
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
              Logout
            </button>
          </div>
        </div>
      </div>
    </Dialog>
  );
};

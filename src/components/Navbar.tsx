import React, { useState } from "react";
import { IProvider } from "@web3auth/base";
import logo from "../assets/ninfa-logo.png";

const Navbar = ({ login }: { login: () => void }) => {
  return (
    <div
      style={{
        position: "relative",
      }}
    >
      <div
        style={{
          height: 50,
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
        <button
          onClick={login}
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
          Login
        </button>
      </div>
    </div>
  );
};

export default Navbar;

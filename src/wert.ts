import { signSmartContractData } from "@wert-io/widget-sc-signer";
import ER271Sovereign from "../out/ERC721Sovereign.sol/ERC721Sovereign.json";
import { ethers } from "ethers";
import nftData from "./assets/nftdata.json";

export const sign = async (
  contractAddress: string,
  userAddress: string,
  nft: (typeof nftData)[number]
) => {
  const contract = new ethers.Contract(
    contractAddress,
    ER271Sovereign.abi,
    new ethers.providers.JsonRpcProvider()
  );
  const inputData = contract.interface.encodeFunctionData("lazyMint", [
    nft.voucher, // voucher
    nft.signature, //sig
    "", //data
    userAddress, //to address
  ]);

  const signedData = signSmartContractData(
    {
      address: userAddress,
      commodity: "ETH:goerli",
      commodity_amount: nft.price,
      network: "goerli",
      sc_address: contractAddress,
      sc_input_data: inputData,
    },
    process.env.REACT_APP_WERT_P_KEY as string
  );

  return signedData;
};

export const getOptions = (
  title: string,
  imageUri: string,
  ownerName: string,
  artistName: string,
  artistImage: string,
  width: number,
  height: number,
  toggleModal = () => {}
) => {
  const options = {
    partner_id: "01G79Y2PMCVJR8VS2VMYMM8DQZ",
    commodity: "ETH:goerli",
    click_id: Math.random(),
    origin: "https://sandbox.wert.io",
    width: width,
    height: height,
    listeners: {
      loaded: () => {
        toggleModal();
      },
      "payment-status": (data: { status: string }) => {
        if (data.status === "success") {
          console.log("wert payment success");
        }
        if (data.status === "failed") {
          console.log("wert payment failed");
        }
        if (data.status === "canceled") {
          console.log("wert payment canceled");
        }
        if (data.status === "progress") {
          console.log("wert payment pending");
        }
      },
    },
    extra: {
      item_info: {
        author_image_url: artistImage,
        author: artistName,
        image_url: imageUri,
        name: title,
        seller: ownerName,
      },
    },
  };
  return options;
};

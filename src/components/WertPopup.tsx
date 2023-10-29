import React, { useState, useEffect } from "react";
import WertModule from "@wert-io/module-react-component";
import { Dialog } from "@mui/material";
import nftData from "../assets/nftdata.json";
import { sign, getOptions } from "../wert";

const contractAddress = "0x091541AC5b5B1BCBd879F4dCD07B5F01007aBA7B"; // hardcoded for simplicity

const WertPopup = ({
  nft,
  isOpen,
  onRequestClose,
  userAddress,
}: {
  nft: (typeof nftData)[number];
  isOpen: boolean;
  onRequestClose: () => void;
  userAddress: string;
}) => {
  const [isNftOwner, setIsNFTOwner] = useState(false);
  const [signature, setSignature] = useState<{ signature: string } | null>(
    null
  );

  const nftURL = nft.imageUri;
  // const tokenId = nft.tokenId; // todo

  useEffect(() => {
    async function getSignatureFromAPI() {
      if (signature === null) {
        const signatureFromAPI = await sign(userAddress, contractAddress, nft);
        setSignature(signatureFromAPI);
      }
    }

    if (!isNftOwner) {
      getSignatureFromAPI();
    }
  }, [signature, isNftOwner]);

  return (
    <Dialog open={isOpen} onClose={onRequestClose}>
      <div className="modal-content">
        <div className="modal-header">
          <button
            type="button"
            className="close"
            onClick={() => onRequestClose()}
          >
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <div className="modal-body">
          {signature ? (
            <WertModule
              className="wert-module"
              options={{
                ...signature,
                ...getOptions(
                  "nft title",
                  nft.imageUri.replace("ipfs://", "https://ipfs.io/ipfs/") +
                    "/nft.jpg",
                  "owner username",
                  "creator username",
                  "https://static.vecteezy.com/system/resources/previews/019/896/008/original/male-user-avatar-icon-in-flat-design-style-person-signs-illustration-png.png",
                  1000,
                  800
                ),
              }}
            />
          ) : (
            <div />
          )}
        </div>
      </div>
    </Dialog>
  );
};

export default WertPopup;

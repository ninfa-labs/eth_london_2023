import { useEffect, useState } from "react";
import { Web3Auth } from "@web3auth/modal";
import {
  WALLET_ADAPTERS,
  CHAIN_NAMESPACES,
  SafeEventEmitterProvider,
  IProvider,
} from "@web3auth/base";
import { OpenloginAdapter } from "@web3auth/openlogin-adapter";
import Main from "./components/Main";
import Navbar from "./components/Navbar";
import EtherspotMain from "./components/EtherspotMain";
import EtherspotNavbar from "./components/EtherspotNavbar";
import OwnerPanel from "./components/OwnerPanel";
import { EtherspotTransactionKit } from "@etherspot/transaction-kit";
import { Web3WalletProvider } from "@etherspot/prime-sdk";
import { ethers, Contract } from "ethers";
import abi from "./assets/ERC721SovreignLazyMint.abi.json";
import "./App.css";

const contractAddress = "0x091541AC5b5B1BCBd879F4dCD07B5F01007aBA7B"; // hardcoded for simplicity

const clientId = process.env.REACT_APP_WEB3AUTH_CLIENT_ID as string; // get from https://dashboard.web3auth.io

function App() {
  const [web3auth, setWeb3auth] = useState<Web3Auth | null>(null);
  const [provider, setProvider] = useState<IProvider | null>(null);
  const [nftContract, setNftContract] = useState<Contract | null>(null);

  const [panel, setPanel] = useState<"main" | "owner">("main");

  useEffect(() => {
    const init = async () => {
      const provider = new ethers.providers.JsonRpcProvider(
        `https://goerli.infura.io/v3/${process.env.REACT_APP_INFURA_PROJECT_ID}`
      );
      const contractInstance = new ethers.Contract(
        contractAddress,
        abi,
        provider
      );
      setNftContract(contractInstance);
    };

    init();
  }, []);

  useEffect(() => {
    const init = async () => {
      try {
        const web3auth = new Web3Auth({
          clientId,
          web3AuthNetwork: "testnet", // mainnet, aqua,  cyan or testnet
          chainConfig: {
            chainNamespace: CHAIN_NAMESPACES.EIP155,
            chainId: "0x1",
            rpcTarget: "https://rpc.ankr.com/eth", // This is the public RPC we have added, please pass on your own endpoint while creating an app
          },
        });

        const openloginAdapter = new OpenloginAdapter({
          loginSettings: {
            mfaLevel: "none", // Pass on the mfa level of your choice: default, optional, mandatory, none
          },
          adapterSettings: {
            loginConfig: {
              // Add login configs corresponding to the provider
              // Google login
              google: {
                name: "Google Login", // The desired name you want to show on the login button
                verifier: "test-v", // Please create a verifier on the developer dashboard and pass the name here
                typeOfLogin: "google", // Pass on the login provider of the verifier you've created
                clientId: process.env.REACT_APP_GOOGLE as string, // use your app client id you got from google
              },
              // Add other login providers here
            },
          },
        });
        web3auth.configureAdapter(openloginAdapter);
        setWeb3auth(web3auth);

        await web3auth.initModal();
      } catch (error) {
        console.error(error);
      }
    };

    init();
  }, []);

  const [mappedProvider, setMappedProvider] =
    useState<Web3WalletProvider | null>(null);
  useEffect(() => {
    if (!provider) {
      setMappedProvider(null);
      return;
    }
    init(provider);
  }, [provider]);

  const init = async (provider: IProvider) => {
    const mProvider = new Web3WalletProvider(provider);
    await mProvider.refresh();
    setMappedProvider(mProvider);
  };

  const login = async () => {
    if (!web3auth) {
      uiConsole("web3auth not initialized yet");
      return;
    }
    const web3authProvider = await web3auth.connect();
    setProvider(web3authProvider);
  };

  const authenticateUser = async () => {
    if (!web3auth) {
      uiConsole("web3auth not initialized yet");
      return;
    }
    const idToken = await web3auth.authenticateUser();
    uiConsole(idToken);
  };

  const getUserInfo = async () => {
    if (!web3auth) {
      uiConsole("web3auth not initialized yet");
      return;
    }
    const user = await web3auth.getUserInfo();
    uiConsole(user);
  };

  const logout = async () => {
    if (!web3auth) {
      uiConsole("web3auth not initialized yet");
      return;
    }
    await web3auth.logout();
    setProvider(null);
  };

  function uiConsole(...args: any[]): void {
    const el = document.querySelector("#console>p");
    if (el) {
      el.innerHTML = JSON.stringify(args || {}, null, 2);
    }
  }

  if (!web3auth) {
    return <div>Loading</div>;
  }

  if (!mappedProvider || !provider) {
    return (
      <div
        style={{
          width: "100%",
        }}
      >
        <Navbar login={login} />

        <Main provider={null} />
      </div>
    );
  }

  return (
    <EtherspotTransactionKit provider={mappedProvider} chainId={5}>
      <div
        style={{
          width: "100%",
        }}
      >
        <EtherspotNavbar
          logout={logout}
          provider={provider}
          panel={panel}
          changePanel={setPanel}
        />

        {panel === "main" ? (
          <EtherspotMain provider={provider} contract={nftContract} />
        ) : (
          <OwnerPanel contract={nftContract} />
        )}
      </div>
    </EtherspotTransactionKit>
  );
}

export default App;

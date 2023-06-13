import { 
  ConnectWallet,
  useAddress,
  useContract,
  useContractRead,
  useContractWrite,
  useTokenBalance,
  Web3Button
} from "@thirdweb-dev/react";
import { ethers } from "ethers";
import { useEffect, useState } from "react";
import "./styles/Home.css";
import { stakingContractAddress } from "../src/caAddresses";
import Logo from "./images/logo-2x.png";

export default function Landing() {
  const address = useAddress();
  const [amountToStake, setAmountToStake] = useState(0);

  // Initialize all the contracts
  const { contract: staking, isLoading: isStakingLoading } = useContract(
    stakingContractAddress,
    "custom"
  );

  // Get contract data from staking contract
  const { data: rewardTokenAddress } = useContractRead(staking, "rewardToken");
  const { data: stakingTokenAddress } = useContractRead(
    staking,
    "stakingToken"
  );

  // Initialize token contracts
  const { contract: stakingToken, isLoading: isStakingTokenLoading } =
    useContract(stakingTokenAddress, "token");
  const { contract: rewardToken, isLoading: isRewardTokenLoading } =
    useContract(rewardTokenAddress, "token");

  // Token balances
  const { data: stakingTokenBalance, refetch: refetchStakingTokenBalance } =
    useTokenBalance(stakingToken, address);
  const { data: rewardTokenBalance, refetch: refetchRewardTokenBalance } =
    useTokenBalance(rewardToken, address);

  // Get staking data
  const {
    data: stakeInfo,
    refetch: refetchStakingInfo,
    isLoading: isStakeInfoLoading,
  } = useContractRead(staking, "getStakeInfo", address || "0");

  useEffect(() => {
    setInterval(() => {
      refetchData();
    }, 10000);
  }, []);

  const refetchData = () => {
    refetchRewardTokenBalance();
    refetchStakingTokenBalance();
    refetchStakingInfo();
  };

  return (
    <>
    <header>
      <div className="container">
        <div className="row pt-2">
        <div class="d-flex justify-content-end">
          <div className="connect">
          {/* <ConnectWallet dropdownPosition={{ side: 'bottom', align: 'center'}} /> */}
        </div>
            </div>
          </div>
          <div className="row">
            <div className="col-12 hero">
              <img src={Logo} className="logo" alt="You are Here" />
              <h1 className="title pt-5">
                Staking Launch Imminent
              </h1>
              <p className="description w-50">
              Tokens will be available for staking shortly. Team is updating the dapp and after some quick testing, we will go live.  
              </p>
            </div>
          </div>
        </div>
    </header>

    <footer className="py-5 my-5">
      <div className="container">
        <div className="row">
          <div className="col-12 text-center">
            <h2 className="title2 pt-5">
                Why Buy and Stake?
              </h2>
              <p className="description px-5 mx-5">only those who stake will be eligible for ETH rewards from partner projects, future airdrops, alpha access and more as we grow. What makes this different is your ETH rewards do not come from taxes, so volume is not necessarily required to earn.
              </p>
          </div>
        </div>
      </div>
    </footer>
    </>
  );
}

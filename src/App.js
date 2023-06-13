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

export default function Home() {
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
          <ConnectWallet dropdownPosition={{ side: 'bottom', align: 'center'}} />
        </div>
            </div>
          </div>
          <div className="row">
            <div className="col-12 hero">
              <img src={Logo} className="logo" alt="You are Here" />
              <h1 className="title pt-5">
                Stake YAH
              </h1>
              <p className="description w-50">
              Stake your YAH for a period of days or weeks and receive just rewards from our labor.
              </p>
            </div>
          </div>
        </div>
    </header>
    <div className="container">
      <div className="row">
        <div className="col-6 col-md-3 g-0">
        <div className="card-display">
            <h3>Unstaked YAH</h3>
            <h4>{stakingTokenBalance?.displayValue}</h4>
          </div>
          </div>
          <div className="col-6 col-md-3 g-0">
          <div className="card-display">
            <h3>Staked YAH</h3>
            <h4>0.0{stakeInfo && ethers.utils.formatEther(stakeInfo[0].toString())}</h4>
            
          </div>
          </div>
          <div className="col-6 col-md-3 g-0">
          <div className="card-display">
            <h3>ETH Rewards</h3>
            <h4>-</h4>
          </div>
          </div>
          <div className="col-6 col-md-3 g-0">
          <div className="card-display">
            <h3>YAH Rewards</h3>
            <h4>0.0{stakeInfo && ethers.utils.formatEther(stakeInfo[1].toString())}</h4>
          </div>
          </div>
        </div>
      </div>
    <div className="container pt-5 pb-5">
      <div className="row">
        <div className="col-6 text-center">

            <div class="balance-form-area">
              <h4 className="labels">Stake YAH</h4>
              <input 
              className="input-staking" 
              type="number"
              value={amountToStake}
              onChange={(e) => setAmountToStake(e.target.value)} 
              placeholder="00.00" />
              <span className="max">MAX</span>
              <div className="white-shape-small approve">
              <Web3Button
            className="btn-staking"
            contractAddress={stakingContractAddress}
            action={async (contract) => {
              await stakingToken.setAllowance(
                stakingContractAddress,
                amountToStake
              );
              await contract.call(
                "stake",
                ethers.utils.parseEther(amountToStake)
              );
              alert("Tokens staked successfully!");
            }}
          >
            Stake!
          </Web3Button>
          
          {/* <input type="submit" value="Approve" className="btn-staking" />
                  <span className="hover-shape1"></span>
                  <span className="hover-shape2"></span>
                  <span className="hover-shape3"></span>       */}
              </div>
            </div>

        </div>
        <div className="col-6 text-center">
            <div class="balance-form-area">
              <h4 className="labels">Unstake YAH</h4>
              <input className="input-staking" type="text" placeholder="00.00" />
              <span className="max">MAX</span>
              <div className="white-shape-small approve">
              <Web3Button
            className="btn-staking"
            contractAddress={stakingContractAddress}
            action={async (contract) => {
              await contract.call(
                "withdraw",
                ethers.utils.parseEther(amountToStake)
              );
              alert("Tokens unstaked successfully!");
            }}
          >
            Unstake!
          </Web3Button>
                  {/* <input type="submit" value="Approve" className="btn-staking" />
                  <span className="hover-shape1"></span>
                  <span className="hover-shape2"></span>
                  <span className="hover-shape3"></span>       */}
              </div>
            </div>
        </div>
      </div>
    </div>
    <footer className="py-5 my-5">
      <div className="container">
        <div className="row">
          <div className="col-12 text-center">
            <h2 className="title2 pt-5">
                We are all here.
              </h2>
              <p className="description">more to be revealed. The light shines our path and illuminates the mind in its own time.
              </p>
          </div>
        </div>
      </div>
    </footer>
    </>
  );
}

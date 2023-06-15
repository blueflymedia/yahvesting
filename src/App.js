import { 
  ConnectWallet,
  useAddress,
  useContract,
  useContractRead,
  useContractWrite,
  useTokenBalance,
  useSigner,
  Web3Button,
  Transaction
} from "@thirdweb-dev/react";
import { ethers } from "ethers";
import { useEffect, useState } from "react";
import CountdownTimer from "./CountdownTimer";
// import useContractEvents from "./useContractEvents";

import "./styles/Home.css";
// import { stakingContractAddress } from "../src/caAddresses";
import Logo from "./images/logo-2x.png";
// api key for thirdweb 02f2d6f5bdafebb308ee17e411b4e58903375c2ef3778edac28d6f993227dff0777e44c9d527bedc8e49244b41bd542394a89f9e554b12cebd86e37419ca6a50
// ethereum.rpc.thirdweb.com
// https://ipfs.thirdwebcdn.com/ipfs/

export default function App() {
  const countDownDate = new Date("Jun 26, 2023 13:02:35").getTime();
  console.log('countdown date:',countDownDate);
  const THREE_DAYS_IN_MS = 3 * 24 * 60 * 60 * 1000;
  const SEVEN_DAYS_IN_MS = 7 * 24 * 60 * 60 * 1000;
  const now = new Date().getTime();
  const distance = countDownDate - now; 

  // const launchDate = countDownDate - NOW_IN_MS;
  const launchDate = now + distance;
  function decimalRound(bal, decimals) {
    if (!decimals) decimals = 2;
    return Number.parseFloat(bal).toFixed(decimals);
  }

  function truncateNumber(bal) {
    return bal.toFixed(2);
  }
  const contractAddress = "0x0777E4C556b76143349b81D86EAc8D36b7efB58E";
  const yahToken = "0x421a312D1C443faA673AE47338c0c42Fb40CdfD0";
  const address = useAddress();
  const signer = useSigner();
  // const signer = ethers.getDefaultProvider();
  const [amountToStake, setAmountToStake] = useState(0);
  const [amountToWithdraw, setAmountToWithdraw] = useState(0);
  // const [amountToClaim, setAmountToClaim] = useState(0);
  // const [ethRewards, setEthRewards] = useState(0);


  // Initialize all the contracts
  const { contract: staking, isLoading: isStakingLoading } = useContract(
    contractAddress,
    "custom"
  );
  // Initialize token contracts
  const { contract: stakingToken, isLoading: isStakingTokenLoading } =
    useContract(yahToken, "token");
  const { contract: rewardsToken, isLoading: isRewardTokenLoading } =
    useContract(yahToken, "token");
  // const { data, isLoading, error } = useTokenDecimals(contract);

  // Get contract data from staking contract
//   const { data: rewardTokenAddress } = useContractRead(staking, "rewardsToken");
//   const { data: stakingTokenAddress } = useContractRead(
//     staking,
//     "stakingToken"
//   );
// console.log('staking token:',stakingTokenAddress);
// console.log('reward token',rewardTokenAddress);

  

  // Token balances
  const { 
    data: unstakedTokenBalance, 
    refetch: refetchUnstakedTokenBalance,
    error: unstakedTokenBalanceError } =
    useTokenBalance(
      rewardsToken, 
      address
      );

      // user staked token balance
const { 
  data: stakedTokenBalance, 
  refetch: refetchStakedTokenBalance,
  error: stakedTokenBalanceError } = useContractRead(
  staking, 
  "balanceOf", 
  (
    [address]
  ),
);

const { 
  data: totalStaked, 
  error: stakedTokenError } = useContractRead(
    staking, 
    "totalSupply",
);


  const { data: rewardsTokenBalance, refetch: refetchRewardsBalance } =
  useContractRead(staking, "rewards", [address]);

    //check to see if token balances are working
    console.log('unstaked token balance:',unstakedTokenBalance);
    console.log('staked token balance:',stakedTokenBalance);

  // Get APY
//   const totalRewards = 388888888;
// const totalStakedTokens = decimalRound(ethers.utils.parseUnits(totalStaked,9));
// const userStakedTokens = decimalRound(ethers.utils.parseUnits(stakedTokenBalance,9));
// const APY= userStakedTokens*(totalRewards/totalStakedTokens)* 100;
  //  const { data, isLoading, error } = useContractRead(staking, "balanceOf", [address || "0"]);
    
  // Get staking data
  // const {
  //   data: stakeInfo,
  //   refetch: refetchStakingInfo,
  //   isLoading: isStakeInfoLoading,
  // } = useContractRead(staking, "balanceOf", address);
  // console.log('staked yah:',stakeInfo);
  // const percentageStaked = (totalStaked/7777777777)*100;
  useEffect(() => {
    setInterval(() => {
      refetchData();
    }, 10000);
  }, []);

  const refetchData = () => {
    refetchStakedTokenBalance();
    refetchUnstakedTokenBalance();
    refetchRewardsBalance();
  };

  return (
    <>
    <header>
      <div className="container">
        <div className="row pt-2">
        <div className="d-flex justify-content-center justify-content-md-end">
          <div className="connect">
          <ConnectWallet theme="dark" dropdownPosition={{ side: 'bottom', align: 'center'}} />
        </div>
            </div>
          </div>
          <div className="row">
            <div className="col-12 hero pb-2">
              <img src={Logo} className="logo" alt="You are Here" />
              <h1 className="title pt-5">
                Stake YAH
              </h1>
              <p className="description w-md-50">
              Stake your YAH for a period of days or weeks and receive just rewards from our labor.
              </p>
            </div>
          </div>
        </div>
    </header>
    <div className="container">
      <div className="row">
        <div className="col-6 col-md-3 g-0">
        <div className="card-display min-height225">
            <h3>Unstaked YAH</h3>
            <h4>
            {decimalRound(unstakedTokenBalance?.displayValue)}
              {/* {unstakedTokenBalance && (decimalRound(ethers.utils.formatUnits(unstakedTokenBalance,9)))} */}
              </h4>
          </div>
          </div>
          <div className="col-6 col-md-3 g-0">
          <div className="card-display min-height225">
            <h3>Staked YAH</h3>
            <h4>{stakedTokenBalance && (decimalRound(ethers.utils.formatUnits(stakedTokenBalance,9)))}
              </h4>
            
          </div>
          </div>
          <div className="col-6 col-md-3 g-0">
          <div className="card-display min-height225">
            <h3>YAH Rewards</h3>
            <h4>{rewardsTokenBalance && (decimalRound(ethers.utils.formatUnits(rewardsTokenBalance,9),2))}{" "}{"YAH"}</h4>
            <Web3Button
        className="btn-claim"
      contractAddress="0x0777E4C556b76143349b81D86EAc8D36b7efB58E"
      action={(stakingToken) => {
        stakingToken.call("claim")
      }}
    >
      Claim Rewards
    </Web3Button>
          </div>
          </div>
          <div className="col-6 col-md-3 g-0">
          <div className="card-display min-height225">
            <h3>Partner Launch</h3>
            <h4 className="aqua"><CountdownTimer targetDate={launchDate} /></h4>
            <p>portion goes to yahvesting.eth</p>
          </div>
          </div>
        </div>
      </div>
    <div className="container pt-5 pb-5">
      <div className="row">
        {/* <!-- col 1 --> */}
        <div className="col-12 col-md-6">
          <div className="row">
            {/* Stake YAH */}
            <div className="col-12 pb-5">
              <div className="balance-form-area">
                <h4 className="labels">Stake YAH</h4>
                {/* <h5></h5> */}
                <input 
                className="input-staking" 
                type="text"
                value={amountToStake}
                onChange={(e) => setAmountToStake(e.target.value)} 
                placeholder="00.00" />
          
          <Web3Button
          className="btn-staking"
        contractAddress="0x421a312D1C443faA673AE47338c0c42Fb40CdfD0"
        action={(stakingToken) => {
          stakingToken.call("approve", [contractAddress, '7777777777000000000'])
        }}
      >
        1. approve
      </Web3Button>
          
            <Web3Button
            theme="dark"
            className="btn-staking"
        contractAddress="0x0777E4C556b76143349b81D86EAc8D36b7efB58E"
        action={(contract) => {
          contract.call("stake", [ethers.utils.parseUnits(amountToStake,9)])
        }}
        // onSuccess={(result) => alert("Staking Transaction successful")}
      >
        2. stake
      </Web3Button>
      <p className="footnote pt-1 aqua">You will need to approve the token before you can stake.</p>
                </div>
            </div>
          </div>
          <div className="row">
            {/* Withdraw YAH */}
            <div className="col-12 pb-3 pb-md-1">
              <div className="balance-form-area">
                <h4 className="labels">Unstake YAH</h4>
                <input 
                className="input-staking" 
                type="text"
                value={amountToWithdraw}
                onChange={(e) => setAmountToWithdraw(e.target.value)} 
                placeholder="00.00" />
                {/* <span className="max">MAX</span> */}
                <div className="white-shape-small approve">
                <Web3Button
                theme="dark"
        className="btn-staking"
        contractAddress="0x0777E4C556b76143349b81D86EAc8D36b7efB58E"
        action={(contract) => {
          contract.call("withdraw", [ethers.utils.parseUnits(amountToWithdraw,9)])
        }}
      >
        unstake
      </Web3Button>
          
                </div>
              </div>
            </div>
          </div>
        </div>
        {/* <!-- col 2 --> */}
        <div className="col-12 col-md-5 offset-md-1 ps-md-5">
          <div className="row">
            <div className="col-12 pb-3 pb-md-1">
            <div className="card-display min-height150">
              <h3>Total YAH Staked</h3>
              <h4 className="pt-4">
              {totalStaked && (decimalRound(ethers.utils.formatUnits(totalStaked,9)))}
                </h4>
                {/* <p>{decimalRound(ethers.utils.parseUnits(percentageStaked,9))}{"%"}</p> */}
            </div>
          </div>
          </div>
          <div className="row">
            <div className="col-12 pb-3 pb-md-1">
            <div className="card-display min-height150">
                <h3>Current APY</h3>
                <h4 className="pt-4">not yet available</h4>
                {/* <h4>{APY && (decimalRound(APY,2))}%</h4> */}
            </div>
            </div>
          </div>
          <div className="row">
            <div className="col-12 pb-3 pb-md-1">
            <div className="card-display min-height150">
                <h3>ETH Rewards</h3>
                <h4 className="pt-4">stay tuned</h4>
                {/* <h4>{APY && (decimalRound(APY,2))}%</h4> */}
            </div>
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
              <p className="description">only those who stake will be eligible for ETH rewards from partner projects, future airdrops, alpha access and more as we grow. What makes this different is your ETH rewards do not come from taxes, so volume is not necessarily required to earn.
              </p>
          </div>
        </div>
      </div>
    </footer>
    </>
  );
}

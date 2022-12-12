import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config()

async function main() {  
  // // Step 1: deploy contract authority
  const AuthorityFactory: ContractFactory = await ethers.getContractFactory("Authority");
  const authority = await upgrades.deployProxy(
    AuthorityFactory,
    [],
    { kind: "uups", "initializer": "initialize"}
  )
  await authority.deployed()
  console.log(`Authority deployed to ${authority.address}`)
  
  // // Step 2: deploy contract token
  // const TokenFactory :ContractFactory = await ethers.getContractFactory("GovernanceToken")
  // const token = await upgrades.deployProxy(
  //   TokenFactory,
  //   [],
  //   {kind: "uups", initializer: "initialize"}
  //   )
  // await token.deployed()
  // console.log(`Token address: ${token.address}`) 

  // // Step 3: deploy contract treasury
  const TreasuryFactory :ContractFactory = await ethers.getContractFactory("Treasury")
  const treasury = await upgrades.deployProxy(
    TreasuryFactory,
    [authority.address],
    {kind: "uups", initializer: "initialize"}
    )
  await treasury.deployed()
  console.log(`Treasury address: ${treasury.address}`) 
  
  // // TESTNET ONLY: deploy contract payment token for testing : testnet
  // const PMTFactory:ContractFactory = await ethers.getContractFactory("PMToken")
  // const pmt = await PMTFactory.deploy("TEST_BUSD", "T_BUSD")
  // await pmt.deployed()
  // console.log(`PMT address: ${pmt.address}`) 
  
  // Step 4: deploy contract Swapped
  // const SwappedFactory :ContractFactory = await ethers.getContractFactory("Swap")
  // const swap = await upgrades.deployProxy(
  //   SwappedFactory,
  //   ["0xa8CBA1c1793d7Ad0C98167f97FCCEB7Cc69dca88","0xB5647784312E67EBe8F1E374bfD6B39D963658c2","500", "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", "0xbaEff6FB1C4B07D7F6625Fb81B4E6D6363fc503F"],
  //   {kind: "uups", initializer: "initialize"}
  //   )
  // await swap.deployed()
  // console.log(`Swap address: ${swap.address}`) 
  
  // Step 5: deploy contract binary plan
  // const BinaryPlanFactory: ContractFactory = await ethers.getContractFactory("BinaryPlan");
  // const binaryPlan = await BinaryPlanFactory.deploy("0x486d2faBbdC7c93a8Aa4CD8eED80B3c49Baa8608")
  // await binaryPlan.deployed()
  // console.log(`BinaryPlan deployed to ${binaryPlan.address}`);

  // Step 6: deploy contract ReferralTreeFactory
  // const ReferralTreeFactory: ContractFactory = await ethers.getContractFactory("ReferralTreeFactory")
  // const referralTree = await ReferralTreeFactory.deploy("0x486d2faBbdC7c93a8Aa4CD8eED80B3c49Baa8608", "0x7f1050f95d93602334007D5F5E54FD9a568DF948")
  // await referralTree.deployed()
  // console.log(`Factory ${referralTree.address}`)


  // // Step 7: deploy contract NFT collection
  // const NFTFactory :ContractFactory = await ethers.getContractFactory("NFTCollection")
  // const nft = await upgrades.deployProxy(
  //   NFTFactory,
  //   ["AI NFTs","AIN","ipfs://QmcPccuccWbtewn7bwpxw3rhWuuT77NSXyg4ncYEGycYNg/","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"],
  //   {kind: "uups", initializer: "init"}
  //   )
  // await nft.deployed()
  // console.log(`NFT address: ${nft.address}`) 

  // Step 8: deploy contract staking
  // const StakingFactory :ContractFactory = await ethers.getContractFactory("ERC721Staking")
  // const staking = await upgrades.deployProxy(
  //   StakingFactory,
  //   ["0x540f0552f770e4E98C0aE0448386A8D34685C193","0xf8FF4bCbC801FA40D25ee3BF0197b9EF4ce0Ec05"],
  //   {kind: "uups", initializer: "initialize"}
  //   )
  // await staking.deployed()
  // console.log(`Staking address: ${staking.address}`) 

























  // const AICarePro: ContractFactory = await ethers.getContractFactory("AICarePro");
  // const aiCarePro = await upgrades.deployProxy(
  //   AICarePro,
  //   ["0xe9e7cea3dedca5984780bafc599bd69add087d56"],
  //   { kind: "uups", initializer: "initialize"},
     
  // );
  
  // await aiCarePro.deployed();
  // console.log(`erc1155 deployed to ${aiCarePro.address}`);

  // const Factory = await ethers.getContractFactory("ReferralTreeFactory");
  // const factory = await Factory.deploy(
  //   process.env.AUTHORITY || "",
  //   "0xe7F1c47C5eC425a0A932DA69838797E33D712Fd7"
  //   // binaryPlan.address
  // );

  // await factory.deployed();

  // console.log(`Factory deployed to ${factory.address}`);

  // const NFTStaking: ContractFactory = await ethers.getContractFactory("ERC721Staking");
  //   const nftStaking: Contract = await upgrades.deployProxy(
  //       NFTStaking,
  //       ["0xAAc6CE62CD4253c1b5A2902b5A1b1D9464256A54", "0xcf7C84E60c468007aB30FF75Bd2467d6e357d840"],
  //       { kind: "uups", initializer: "initialize"},
  //   );
  //   await nftStaking.deployed();
  //   console.log("NFTStaking deployed to : ", nftStaking.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

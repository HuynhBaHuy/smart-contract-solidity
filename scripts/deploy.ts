import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
import * as dotenv from "dotenv";

dotenv.config()

async function main() {  
  // // Step 1: deploy contract marketplace
  const MarketplaceFactory: ContractFactory = await ethers.getContractFactory("Marketplace");
  const marketplace = await upgrades.deployProxy(
    MarketplaceFactory,
    [],
    { kind: "uups", "initializer": "initialize"}
  )
  await marketplace.deployed()
  console.log(`Marketplace deployed to ${marketplace.address}`)

  // // Step 1: deploy contract authority
  // const AuthorityFactory: ContractFactory = await ethers.getContractFactory("Authority");
  // const authority = await upgrades.deployProxy(
  //   AuthorityFactory,
  //   [],
  //   { kind: "uups", "initializer": "initialize"}
  // )
  // await authority.deployed()
  // console.log(`Authority deployed to ${authority.address}`)
  
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
  // const TreasuryFactory :ContractFactory = await ethers.getContractFactory("Treasury")
  // const treasury = await upgrades.deployProxy(
  //   TreasuryFactory,
  //   [authority.address],
  //   {kind: "uups", initializer: "initialize"}
  //   )
  // await treasury.deployed()
  // console.log(`Treasury address: ${treasury.address}`) 
  
  // // Step 3.1: deploy contract whitelist
  // const WhiteListFactory :ContractFactory = await ethers.getContractFactory("WhiteList")
  // const whiteList = await upgrades.deployProxy(
  //   WhiteListFactory,
  //   ["0xc2a04b816fe6b531b5e8100e78f9dc420b081b20"],
  //   {kind: "uups", initializer: "initialize"}
  //   )
  // await whiteList.deployed()
  // console.log(`whiteList address: ${whiteList.address}`) 
  
  // // TESTNET ONLY: deploy contract payment token for testing : testnet
  // const PMTFactory:ContractFactory = await ethers.getContractFactory("PMToken")
  // const pmt = await PMTFactory.deploy("TEST_BUSD", "T_BUSD")
  // await pmt.deployed()
  // console.log(`PMT address: ${pmt.address}`) 
  
  // Step 4: deploy contract Swapped
  // const SwappedFactory :ContractFactory = await ethers.getContractFactory("Swap")
  // const swap = await upgrades.deployProxy(
  //   SwappedFactory,
  //   ["0x47603421d83c6811AE0C9c7682A59254AEf2581f","0xBa21830C55089c550a4889F7aaC0FEd75e419183","500", "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", "0xf8FF4bCbC801FA40D25ee3BF0197b9EF4ce0Ec05"],
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


  // Step 7: deploy contract NFT collection
  // const NFTFactory :ContractFactory = await ethers.getContractFactory("NFT")
  // const nft = await upgrades.deployProxy(
  //   NFTFactory,
  //   ["1988 DRAGON","NGER","ipfs://QmcGmMTyUiCPteNfDKKaDho724Y99Z9Fs7N58yJXvwBbam/","0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"],
  //   {kind: "uups", initializer: "init"},
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



  // // Step x: deploy contract PaymentSystem
  // const PaymentSystemFactory :ContractFactory = await ethers.getContractFactory("PaymentSystem")
  // const paymentSystem = await upgrades.deployProxy(
  //   PaymentSystemFactory,
  //   ["0x1B329402Cb1825C6F30A0d92aB9E2862BE47333f","0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06","500000000000000000","0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526","0x4ce7E3773118933f9D81D045c37D29d699C3c690","0x9c0495e415664E1C0426198b1155a9019D93202d"],
  //   {kind: "uups", initializer: "initialize"}
  //   )
  // await paymentSystem.deployed()
  // console.log(`PaymentSystem address: ${paymentSystem.address}`)

  // // Deploy API Consumer
  // const APIConsumerFactory :ContractFactory = await ethers.getContractFactory("APIConsumer")
  // const apiConsumer = await APIConsumerFactory.deploy(
  //   ""
  // )



















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

import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
// 
const proxyAddress: string = "0x6c864714e36c66c6a5557426e2E13deA899fD2B0";

async function main(): Promise<void> {
  console.log("Deploying Proxy contract...");
  const factory: ContractFactory = await ethers.getContractFactory("NFTCollection");
  const contract: Contract = await upgrades.upgradeProxy(proxyAddress, factory);
  await contract.deployed();
  console.log("Logic Proxy Contract deployed to : ", contract.address);
  console.log(
    "Logic Contract implementation address is : ",
    await upgrades.erc1967.getImplementationAddress(contract.address),
  );
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
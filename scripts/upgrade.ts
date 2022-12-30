import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
// 
const proxyAddress: string = "0x08b749d12c8d4b9C9ECBbe166A9bCf324f793dd6";

async function main(): Promise<void> {
  console.log("Deploying Proxy contract...");
  const factory: ContractFactory = await ethers.getContractFactory("Marketplace");
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
import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";
// 
const proxyAddress: string = "0xe52975AcCa0558176C0d304FB936561D11b12Ba6";

async function main(): Promise<void> {
  console.log("Deploying Proxy contract...");
  const factory: ContractFactory = await ethers.getContractFactory("Swap");
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
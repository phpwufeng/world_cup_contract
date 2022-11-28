import { ethers } from "hardhat";

async function main() {
  const LENS = await ethers.getContractFactory("WorldCupLens");
  const lens = await LENS.deploy();

  await lens.deployed();

  console.log(`WorldCupLens deployed at: ${lens.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

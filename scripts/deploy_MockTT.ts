import { ethers } from "hardhat";

async function main() {
  let [owner] = await ethers.getSigners();
  const MockTT = await ethers.getContractFactory("MockTT");
  const tt = await MockTT.deploy();

  await tt.deployed();

  console.log(`MockTT deployed at: ${tt.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

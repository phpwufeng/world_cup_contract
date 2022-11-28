import { ethers } from "hardhat";

// 国库钱包
const vault =   {
  "address": "0x593984169bc598f877a71c386e9352755ba2ef00",
};

async function main() {
  const [owner] = await ethers.getSigners();

  const WC = await ethers.getContractFactory("WorldCupQatar");
  const wc = await WC.deploy(owner.address, vault.address);

  await wc.deployed();

  console.log(`WorldCupQatar deployed at: ${wc.address}`);

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

import { ethers } from "hardhat";

const owner = process.env.OWNER || "";
const vault = process.env.VAULT || "";

async function main() {
  if (owner.length == 0 || vault.length == 0) {
    throw new Error("owner or vault not defined.");
  }

  console.log(`Settings:
    owner: ${owner},
    vault: ${vault}
    `);
  const WC = await ethers.getContractFactory("WorldCupQatar");
  const wc = await WC.deploy(owner, vault);

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

// import { ethers } from "hardhat";

import { task } from "hardhat/config";



task("start-match", "start a match")
  .addParam("wc", "Address of contract WorldCupQatar")
  .addParam("a", "Id of country A")
  .addParam("b", "Id of country B")
  .addParam("offset", "time offset by now of start time of match")
  .addParam("token", "pay token of this match")
  .setAction(async (taskArgs) => {
      const BN = hre.ethers.BigNumber;
      const [owner] = await hre.ethers.getSigners();
      const now = Math.floor((new Date()).getTime() / 1000);
      const offset = Math.floor(parseFloat(taskArgs.offset) * 3600);
      const matchStart = now + offset;
      const matchEnd = matchStart + 120 * 60;

      const guessStart = matchStart - 8 * 60 * 60;
      const guessEnd = matchStart;

      const wc = await hre.ethers.getContractAt("WorldCupQatar",taskArgs.wc);
      let tx = await wc.connect(owner).startMatch(
        BN.from(taskArgs.a),
        BN.from(taskArgs.b),
        BN.from(matchStart), BN.from(matchEnd),
        BN.from( guessStart), BN.from(guessEnd),
        taskArgs.token
      );
      await tx.wait()

      console.log(`task finished hash: ${tx.hash}`);
  });
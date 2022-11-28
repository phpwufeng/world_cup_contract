import { ethers } from "hardhat";
import { GuessType } from "../test/GuessType";
import { Address, player1, player2, player3, vault } from "./address";
import { Signer } from "@ethersproject/abstract-signer";

const BN = ethers.BigNumber;

async function startMatch(a: number, b: number, matchStartDelay: number) {
    const [owner] = await ethers.getSigners();
    const now = Math.floor((new Date()).getTime() / 1000);

    const offset = Math.floor(matchStartDelay * 3600);
    const matchStart = now + offset;
    const matchEnd = matchStart + 30 * 60;

    const guessStart = matchStart - 3 * 60 * 60;
    const guessEnd = matchStart;

    const cup = await ethers.getContractAt("WorldCupQatar", Address.wc);
    let tx = await cup.connect(owner).startMatch(
      BN.from(a),
      BN.from(b),
      BN.from(matchStart), BN.from(matchEnd),
      BN.from( guessStart), BN.from(guessEnd),
      Address.token
    );
    await tx.wait()

    console.log(`task finished hash: ${tx.hash}`);
}

async function allMatchs() {
    const cup = await ethers.getContractAt("WorldCupQatar", Address.wc);
    const totalMatches = (await cup.totalMatches()).toNumber();
    for (let i = 1; i <= totalMatches; i++) {
        const matAddr = await cup.matches(i);
        const mat = await ethers.getContractAt("Match", matAddr);

        console.log(`
        Match:
            matchId:    ${await mat.matchId()},
            countryA:   ${await mat.countryA()},
            countryB:   ${await mat.countryB()},
            matchStart: ${await mat.startTime()},
            matchEnd:   ${await mat.endTime()},
            guessStart: ${await mat.guessStartTime()},
            guessEnd:   ${await mat.guessEndTime()},
            payToken:   ${await mat.payToken()},
            finalScore: ${(await mat.finalScores()).toHexString()}
        `);
    }
}
async function guess(player: Signer, matId: number, guessType: number, betAmount: number) {
    const cup = await ethers.getContractAt("WorldCupQatar", Address.wc);
    let tx = await cup.connect(player).guess(BN.from(matId), BN.from(guessType), BN.from(betAmount));
    await tx.wait();

    console.log(`guess tx: ${tx.hash}`);
}

async function setScores(matchId: number, scoreA: number, scoreB: number) {
    const cup = await ethers.getContractAt("WorldCupQatar", Address.wc);
    let tx = await cup.setScores(BN.from(matchId), BN.from(scoreA), BN.from(scoreB));
    await tx.wait();

    console.log(`set score tx: ${tx.hash}`);
}

async function claimReward(player: Signer, matchId: number, betId: string) {
    const cup = await ethers.getContractAt("WorldCupQatar", Address.wc);
    let tx = await cup.connect(player).claimReward(BN.from(matchId), BN.from(betId));
    await tx.wait();

    console.log(`claim reward tx: ${tx.hash}`);
}

async function TTBalance(address: string) {
    const tt = await ethers.getContractAt("MockTT", Address.token);
    console.log(`
    ${address} balance: ${await tt.balanceOf(address)}
    `);
}

async function main() {
    let [owner] = await ethers.getSigners();

    // await owner.sendTransaction({ to: player1.address, value: ethers.utils.parseEther('0.03') });
    // await owner.sendTransaction({ to: player2.address, value: ethers.utils.parseEther('0.03') });
    // await owner.sendTransaction({ to: player3.address, value: ethers.utils.parseEther('0.03') });

    // await mintTT(player1, "100000000000000000000");
    // await mintTT(player2, "100000000000000000000");
    // await mintTT(player3, "100000000000000000000");

    // await startMatch(1, 2, 0.01);
    // await startMatch(3, 4, 0.01);

    // await startMatch(5, 6, 3.0);
    // await startMatch(7, 8, 3.0);

    // await startMatch(9, 10, 20);  // 未来
    // await startMatch(11, 12, 20); // 未来

    // await startMatch(13, 14, 0.45);
    // await startMatch(15, 16, 0.45);

    // await startMatch(17, 18, 3);  // 未来
    // await startMatch(19, 20, 3); // 未来


    // await guess(player1, 3, GuessType.GUESS_WINLOSE_A_WIN, 10000);
    // await guess(player2, 3, GuessType.GUESS_SCORE_34, 15000);
    // await guess(player3, 3, GuessType.GUESS_SCORE_OTHER, 20000)

    // await guess(player1, 4, GuessType.GUESS_WINLOSE_B_WIN, 20000);
    // await guess(player2, 4, GuessType.GUESS_SCORE_20, 30000);
    // await guess(player3, 4, GuessType.GUESS_WINLOSE_A_WIN, 40000);

    // await setScores(1, 2, 3);
    // await setScores(2, 1, 0);
    // await setScores(3, 5, 4);
    // await setScores(4, 2, 0);
    // await setScores(5, 6, 1);
    // await setScores(6, 2, 0);

    // await allMatchs();

    // await claimReward(player1, 3, "1161995860596616152391849729530928935249637440387407");
    // await claimReward(player1, 4, "1539063283027989105288400416371729954320868036475215"); // not win bet

    // await claimReward(player3, 3, "1161106645827231236274260338464896429207026521014395"); // not win bet
    // await TTBalance(await player3.getAddress());
    // await claimReward(player3, 4, "1536712566621273286252607340472981165258601184559227"); // not win bet
    // await TTBalance(await player3.getAddress());

    // await TTBalance(vault.address);

    const tt = await ethers.getContractAt("MockTT", Address.tt);
    let tx = await tt.mint("0xa3f45b3ab5ff54d24d61c4ea3f39cc98ebcb3c7e", BN.from("100000000000000000000000000"));
    await tx.wait();
}

async function mintTT(to: Signer, amount: string) {

    const tt = await ethers.getContractAt("MockTT", Address.tt);
    let tx = await tt.mint(await to.getAddress(), amount);
    await tx.wait();

    console.log(`mint tt to ${await to.getAddress()} :  ${tx.hash}`)

    tx = await tt.connect(to).approve(Address.qatar, amount);
    await tx.wait();
    console.log(`${await to.getAddress()} approve :  ${tx.hash}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

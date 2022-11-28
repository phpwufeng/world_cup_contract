import { expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { MockTT, WorldCupQatar } from "../typechain-types";
import { Countries } from "./Country";
import { GuessType } from "./GuessType";

const BN = ethers.BigNumber;
const TT = ethers.utils.parseEther;
const E18 = BN.from("1000000000000000000");

describe("WorldCupQatar", function () {
  let owner: SignerWithAddress;
  let player1: SignerWithAddress;
  let player2: SignerWithAddress;
  let player3: SignerWithAddress;
  let vault: SignerWithAddress;
  let tt: MockTT;
  let wc: WorldCupQatar;

  beforeEach(async () => {
    [owner, player1, player2, player3, vault] = await ethers.getSigners();
    let MockTT = await ethers.getContractFactory("MockTT");
    tt = await MockTT.deploy();
    await tt.deployed();

    let WorldCupQatar = await ethers.getContractFactory("WorldCupQatar");
    wc = await WorldCupQatar.deploy(owner.address, vault.address);
    await wc.deployed();

    await tt.connect(owner).mint(player1.address, ethers.utils.parseEther("1000"));
    await tt.connect(owner).mint(player2.address, ethers.utils.parseEther("1000"));
    await tt.connect(owner).mint(player3.address, ethers.utils.parseEther("1000"));

    await tt.connect(player1).approve(wc.address, ethers.utils.parseEther("1000"));
    await tt.connect(player2).approve(wc.address, ethers.utils.parseEther("1000"));
    await tt.connect(player3).approve(wc.address, ethers.utils.parseEther("1000"));
  });

  afterEach(async () => {
    let b1 = await tt.balanceOf(vault.address);
    let b0 = await tt.balanceOf(wc.address);
    let p1 = await tt.balanceOf(player1.address);
    let p2 = await tt.balanceOf(player2.address);
    let p3 = await tt.balanceOf(player3.address);

    expect(b1.add(b0).add(p1).add(p2).add(p3)).to.equal(ethers.utils.parseEther("3000"), "final balance mismatch");
  });

  it("startMatch", async () => {
    let countryA = Countries.Senegal.id;
    let countryB = Countries.Argentina.id;
    let now = (await ethers.provider.getBlock('latest')).timestamp;
    let matchStart = now + 30 * 60;
    let matchEnd = matchStart + 30*60;
    let guessStart = matchStart - 30 * 60;
    let guessEnd = matchStart;

    await wc.startMatch(countryA, countryB, matchStart, matchEnd, guessStart, guessEnd, tt.address);

    expect(await wc.totalMatches()).to.equal(1);

    let mat = await ethers.getContractAt("Match", await wc.matches(1));
    expect(await mat.countryA()).to.equal(countryA);
    expect(await mat.countryB()).to.equal(countryB);
    expect(await mat.startTime()).to.equal(matchStart);
    expect(await mat.endTime()).to.equal(matchEnd);
    expect(await mat.guessStartTime()).to.equal(guessStart);
    expect(await mat.guessEndTime()).to.equal(guessEnd);
    expect(await mat.payToken()).to.equal(tt.address);
    expect(await mat.finalScores()).to.equal(BN.from(0xffffff));
    expect(await mat.paused()).to.equal(false);
    expect(await mat.factory()).to.equal(wc.address);

    let winlose = await ethers.getContractAt("WinLoseGuess", await mat.winLose());

    expect(await winlose.factory()).to.equal(mat.address);
    expect(await winlose.matchId()).to.equal(await mat.matchId());
    expect(await winlose.totalSeq()).to.equal(0);
    expect(await winlose.POOL_COUNT()).to.equal(3);
    expect(await winlose.GUESS_TYPE_START()).to.equal(GuessType.GUESS_WINLOSE_A_WIN);

    let scoreguess = await ethers.getContractAt("ScoreGuess", await mat.scoreGuess());
    expect(await scoreguess.factory()).to.equal(mat.address);
    expect(await scoreguess.matchId()).to.equal(await mat.matchId());
    expect(await scoreguess.totalSeq()).to.equal(0);
    expect(await scoreguess.POOL_COUNT()).to.equal(26);
    expect(await scoreguess.GUESS_TYPE_START()).to.equal(GuessType.GUESS_SCORE_10);
  });

  it("guess & claim", async ()=> {
    let countryA = Countries.Senegal.id;
    let countryB = Countries.Argentina.id;
    let now = (await ethers.provider.getBlock('latest')).timestamp;
    let matchStart = now + 60 * 60;
    let matchEnd = matchStart + 30*60;
    let guessStart = matchStart - 30 * 60;
    let guessEnd = matchStart;

    await wc.startMatch(countryA, countryB, matchStart, matchEnd, guessStart, guessEnd, tt.address);
    await expect(wc.connect(player1).guess(5, GuessType.GUESS_SCORE_00, TT("10"))).to.revertedWith("match not exist")
    await expect(wc.connect(player1).guess(1, GuessType.GUESS_SCORE_00, TT("0"))).to.revertedWith("bet amount invalid")
    await expect(wc.connect(player1).guess(1, GuessType.GUESS_SCORE_00, TT("10"))).to.revertedWith("match is not betable");

    // fastforward to guess start time
    await ethers.provider.send("evm_setNextBlockTimestamp", [guessStart]);
    await ethers.provider.send("evm_mine", []);

    await expect(wc.connect(player1).guess(1, 31, TT("10"))).to.revertedWith("not support guess type");

    const P1BetAmount = TT("10");
    const P2BetAmount = TT("15");
    const P3BetAmount = TT("20");

    const FEE1 = P1BetAmount.mul(3).div(100);
    const FEE2 = P2BetAmount.mul(3).div(100);
    const FEE3 = P3BetAmount.mul(3).div(100);

    await wc.connect(player1).guess(1, GuessType.GUESS_SCORE_00, P1BetAmount);
    await wc.connect(player1).guess(1, GuessType.GUESS_WINLOSE_B_WIN, P1BetAmount);

    await wc.connect(player2).guess(1, GuessType.GUESS_WINLOSE_A_WIN, P2BetAmount);
    await wc.connect(player2).guess(1, GuessType.GUESS_SCORE_13, P2BetAmount);

    await wc.connect(player3).guess(1, GuessType.GUESS_SCORE_OTHER, P3BetAmount);
    await wc.connect(player3).guess(1, GuessType.GUESS_WINLOSE_DRAW, P3BetAmount);

    const totalFee = FEE1.add(FEE2).add(FEE3);
    expect(await tt.balanceOf(vault.address)).to.equal(totalFee.mul(2));

    let mat = await ethers.getContractAt("Match", await wc.matches(1));
    let winlose = await ethers.getContractAt("WinLoseGuess", await mat.winLose());
    let scoreguess = await ethers.getContractAt("ScoreGuess", await mat.scoreGuess());

    expect(await winlose.totalSeq()).to.equal(3);
    expect(await scoreguess.totalSeq()).to.equal(3);
    expect(await winlose.totalBetPlayers()).to.equal(3);
    expect(await scoreguess.totalBetPlayers()).to.equal(3);

    expect(await winlose.totalDeposit()).to.equal(P1BetAmount.add(P2BetAmount).add(P3BetAmount).sub(totalFee));
    expect(await scoreguess.totalDeposit()).to.equal(P1BetAmount.add(P2BetAmount).add(P3BetAmount).sub(totalFee));

    let realOdds = await winlose.odds(GuessType.GUESS_WINLOSE_A_WIN);
    let targetOdds = (P1BetAmount.add(P2BetAmount).add(P3BetAmount).sub(totalFee)).mul(E18).div(P2BetAmount.sub(FEE2));
    expect(realOdds).to.equal(targetOdds);

    // fast forward to match start
    await ethers.provider.send("evm_setNextBlockTimestamp", [matchStart]);
    await ethers.provider.send("evm_mine", []);

    await expect(wc.connect(player1).guess(1, GuessType.GUESS_SCORE_02, TT("10"))).to.revertedWith("match is not betable");
    // await expect(wc.connect(owner).setScores(1, 2, 3)).to.revertedWith("match is not end");

    let betId = await winlose.sequenceRecords(1);
    await expect(wc.connect(player1).claimReward(1, betId)).to.revertedWith("match is not finished");

    // fast forward to match end
    await ethers.provider.send("evm_setNextBlockTimestamp", [matchEnd]);
    await ethers.provider.send("evm_mine", []);
    // match finished,  result not set
    await expect(wc.connect(player1).claimReward(1, betId)).to.revertedWith("match is not finished");

    await wc.connect(owner).setScores(1, 3, 2);
    await wc.connect(owner).setMatchFinished(1);

    let failBetId = await winlose.sequenceRecords(2);
    await expect(wc.connect(player1).claimReward(1, failBetId)).to.revertedWith("claimer not match better");
    await expect(wc.connect(player1).claimReward(1, betId)).to.revertedWith("not win bet");

    // 计算收益
    let winBetId = await winlose.sequenceRecords(2);

    let beforeBalance = await tt.balanceOf(player2.address);
    await wc.connect(player2).claimReward(1, winBetId);
    let afterBalance = await tt.balanceOf(player2.address);

    let r = await winlose.getPlayerBetInfo(player2.address, GuessType.GUESS_WINLOSE_A_WIN);
    let betAmount = r[0];
    let claimedAmount = r[2];
    let odds = await winlose.odds(GuessType.GUESS_WINLOSE_A_WIN);

    expect(betAmount.mul(odds).div(E18)).to.equal(claimedAmount);
    expect(afterBalance.sub(beforeBalance)).to.equal(claimedAmount);

    await expect(wc.connect(player2).claimReward(1, winBetId)).to.revertedWith("reward claimed");

  });

  it("claimAllRewards", async ()=> {
    let now = (await ethers.provider.getBlock('latest')).timestamp;
    let matchStart = now + 60 * 60;
    let matchEnd = matchStart + 30*60;
    let guessStart = matchStart - 30 * 60;
    let guessEnd = matchStart;

    await wc.startMatch( Countries.Senegal.id, Countries.Argentina.id, matchStart, matchEnd, guessStart, guessEnd, tt.address);
    await wc.startMatch( Countries.Poland.id, Countries.Denmark.id, matchStart, matchEnd, guessStart, guessEnd, tt.address);
    await wc.startMatch( Countries.France.id, Countries.Germany.id, matchStart, matchEnd, guessStart, guessEnd, tt.address);
    await wc.startMatch( Countries.Morocco.id, Countries.Switzerland.id, matchStart, matchEnd, guessStart, guessEnd, tt.address);

    // fastforward to guess start time
    await ethers.provider.send("evm_setNextBlockTimestamp", [guessStart]);
    await ethers.provider.send("evm_mine", []);

    const P1BetAmount = TT("10");
    const P2BetAmount = TT("15");
    const P3BetAmount = TT("20");

    const FEE1 = P1BetAmount.mul(3).div(100);
    const FEE2 = P2BetAmount.mul(3).div(100);
    const FEE3 = P3BetAmount.mul(3).div(100);

    await wc.connect(player1).guess(1, GuessType.GUESS_SCORE_00, P1BetAmount);
    await wc.connect(player1).guess(2, GuessType.GUESS_WINLOSE_B_WIN, P1BetAmount);
    await wc.connect(player1).guess(3, GuessType.GUESS_WINLOSE_A_WIN, P1BetAmount);
    await wc.connect(player1).guess(4, GuessType.GUESS_SCORE_13, P1BetAmount);

    await wc.connect(player2).guess(1, GuessType.GUESS_SCORE_20, P2BetAmount);
    await wc.connect(player2).guess(2, GuessType.GUESS_WINLOSE_A_WIN, P2BetAmount);
    await wc.connect(player2).guess(3, GuessType.GUESS_WINLOSE_B_WIN, P2BetAmount);
    await wc.connect(player2).guess(4, GuessType.GUESS_SCORE_43, P2BetAmount);

    await wc.connect(player3).guess(1, GuessType.GUESS_SCORE_30, P3BetAmount);
    await wc.connect(player3).guess(2, GuessType.GUESS_WINLOSE_DRAW, P3BetAmount);
    await wc.connect(player3).guess(3, GuessType.GUESS_WINLOSE_DRAW, P3BetAmount);
    await wc.connect(player3).guess(4, GuessType.GUESS_SCORE_43, P3BetAmount);

    // fast forward to match end
    await ethers.provider.send("evm_setNextBlockTimestamp", [matchEnd]);
    await ethers.provider.send("evm_mine", []);

    await wc.connect(owner).setScores(1, 3, 2);
    await wc.connect(owner).setScores(2, 2, 3);
    await wc.connect(owner).setScores(3, 3, 2);
    await wc.connect(owner).setScores(4, 4, 3);

    await wc.connect(owner).setMatchFinished(1);
    await wc.connect(owner).setMatchFinished(2);
    await wc.connect(owner).setMatchFinished(3);
    await wc.connect(owner).setMatchFinished(4);

    let mat = await ethers.getContractAt("Match", await wc.matches(2));
    let winlose = await ethers.getContractAt("WinLoseGuess", await mat.winLose());
    let scoreguess = await ethers.getContractAt("ScoreGuess", await mat.scoreGuess());
    let betId = await winlose.sequenceRecords(1);

    let beforeBalance = await tt.balanceOf(player1.address);
    await wc.connect(player1).claimReward(2, betId);
    let afterBalance = await tt.balanceOf(player1.address);
    console.log(`claim a match: ${afterBalance.sub(beforeBalance)}`);

    beforeBalance = await tt.balanceOf(player1.address);
    await wc.connect(player1).claimAllRewards();
    afterBalance = await tt.balanceOf(player1.address);
    console.log(`claim all: ${afterBalance.sub(beforeBalance)}`);

    await expect(wc.connect(player1).claimAllRewards()).to.revertedWith("no more rewards");
  });

  it("controller settings", async () => {
    let countryA = Countries.Senegal.id;
    let countryB = Countries.Argentina.id;
    let now = (await ethers.provider.getBlock('latest')).timestamp;
    let matchStart = now + 60 * 60;
    let matchEnd = matchStart + 30*60;
    let guessStart = matchStart - 30 * 60;
    let guessEnd = matchStart;

    await wc.startMatch(countryA, countryB, matchStart, matchEnd, guessStart, guessEnd, tt.address);

    await expect(wc.connect(player1).pauseMatch(1, true)).to.reverted;
    await wc.connect(owner).setSettingRole(player1.address, true);
    await wc.connect(player1).pauseMatch(1, true);

    await wc.connect(owner).setSettingRole(player1.address, false);
    await expect(wc.connect(player1).pauseMatch(1, false)).to.reverted;
  });

  it("winlose nobody win", async () => {
    let countryA = Countries.Senegal.id;
    let countryB = Countries.Argentina.id;
    let now = (await ethers.provider.getBlock('latest')).timestamp;
    let matchStart = now + 60 * 60;
    let matchEnd = matchStart + 30*60;
    let guessStart = matchStart - 30 * 60;
    let guessEnd = matchStart;

    await wc.startMatch(countryA, countryB, matchStart, matchEnd, guessStart, guessEnd, tt.address);
    // fastforward to guess start time
    await ethers.provider.send("evm_setNextBlockTimestamp", [guessStart]);
    await ethers.provider.send("evm_mine", []);

    const P1BetAmount = TT("10");
    const P2BetAmount = TT("15");
    const FEE1 = P1BetAmount.mul(3).div(100);
    const FEE2 = P2BetAmount.mul(3).div(100);

    await wc.connect(player1).guess(1, GuessType.GUESS_WINLOSE_B_WIN, P1BetAmount);
    await wc.connect(player2).guess(1, GuessType.GUESS_WINLOSE_A_WIN, P2BetAmount);

    // fast forward to match end
    await ethers.provider.send("evm_setNextBlockTimestamp", [matchEnd]);
    await ethers.provider.send("evm_mine", []);

    await wc.connect(owner).setScores(1, 3, 3);


    let beforeAmount = await tt.balanceOf(vault.address);
    await wc.connect(owner).setMatchFinished(1);
    let afterAmount = await tt.balanceOf(vault.address);

    expect(afterAmount.sub(beforeAmount)).to.equal(P1BetAmount.add(P2BetAmount).sub(FEE1).sub(FEE2));
  });

  it("scores guess nobody win", async () => {
    let countryA = Countries.Senegal.id;
    let countryB = Countries.Argentina.id;
    let now = (await ethers.provider.getBlock('latest')).timestamp;
    let matchStart = now + 60 * 60;
    let matchEnd = matchStart + 30*60;
    let guessStart = matchStart - 30 * 60;
    let guessEnd = matchStart;

    await wc.startMatch(countryA, countryB, matchStart, matchEnd, guessStart, guessEnd, tt.address);
    // fastforward to guess start time
    await ethers.provider.send("evm_setNextBlockTimestamp", [guessStart]);
    await ethers.provider.send("evm_mine", []);

    const P1BetAmount = TT("10");
    const P2BetAmount = TT("15");
    const FEE1 = P1BetAmount.mul(3).div(100);
    const FEE2 = P2BetAmount.mul(3).div(100);

    await wc.connect(player1).guess(1, GuessType.GUESS_SCORE_11, P1BetAmount);
    await wc.connect(player1).guess(1, GuessType.GUESS_SCORE_31, P1BetAmount);
    await wc.connect(player1).guess(1, GuessType.GUESS_SCORE_04, P1BetAmount);
    await wc.connect(player2).guess(1, GuessType.GUESS_SCORE_03, P2BetAmount);
    await wc.connect(player2).guess(1, GuessType.GUESS_SCORE_24, P2BetAmount);
    await wc.connect(player2).guess(1, GuessType.GUESS_SCORE_43, P2BetAmount);
    await wc.connect(player2).guess(1, GuessType.GUESS_SCORE_OTHER, P2BetAmount);

    // fast forward to match end
    await ethers.provider.send("evm_setNextBlockTimestamp", [matchEnd]);
    await ethers.provider.send("evm_mine", []);

    await wc.connect(owner).setScores(1, 0, 2);

    let beforeAmount = await tt.balanceOf(vault.address);
    await wc.connect(owner).setMatchFinished(1);
    let afterAmount = await tt.balanceOf(vault.address);

    expect(afterAmount.sub(beforeAmount)).to.equal(P1BetAmount.mul(3).add(P2BetAmount.mul(4)).sub(FEE1.mul(3)).sub(FEE2.mul(4)));
  });

  it("recall", async () => {
    let countryA = Countries.Senegal.id;
    let countryB = Countries.Argentina.id;
    let now = (await ethers.provider.getBlock('latest')).timestamp;
    let matchStart = now + 60 * 60;
    let matchEnd = matchStart + 30*60;
    let guessStart = matchStart - 30 * 60;
    let guessEnd = matchStart;

    await wc.startMatch(countryA, countryB, matchStart, matchEnd, guessStart, guessEnd, tt.address);
    // fastforward to guess start time
    await ethers.provider.send("evm_setNextBlockTimestamp", [guessStart]);
    await ethers.provider.send("evm_mine", []);

    const P1BetAmount = TT("10");
    const P2BetAmount = TT("15");

    await wc.connect(player1).guess(1, GuessType.GUESS_WINLOSE_B_WIN, P1BetAmount);
    await wc.connect(player2).guess(1, GuessType.GUESS_WINLOSE_A_WIN, P2BetAmount);

    let mat = await ethers.getContractAt("Match", await wc.matches(1));
    let winlose = await ethers.getContractAt("WinLoseGuess", await mat.winLose());
    let betId = await winlose.sequenceRecords(1);
    await expect(wc.connect(player1).recall(1, betId)).to.rejectedWith("can not recall");

    await wc.pauseMatch(1, true);

    let r = await winlose.getPlayerBetInfo(player1.address, GuessType.GUESS_WINLOSE_B_WIN);
    let betAmount = r[0];

    let beforeAmount = await tt.balanceOf(player1.address);
    await wc.connect(player1).recall(1, betId);
    let afterAmount = await tt.balanceOf(player1.address);

    expect(afterAmount.sub(beforeAmount)).to.equal(betAmount);
  });
});

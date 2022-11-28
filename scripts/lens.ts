import { ethers } from "hardhat";
import { GuessType } from "../test/GuessType";
import { Address, player1, player2, player3 } from "./address";

const BN = ethers.BigNumber;

function printTopNRecord(tag: string, rs: any[]) {
    let counts = rs.length;
    console.log(tag);
    for (let i = 0; i < counts; i++) {
        let ks = rs[i];
        console.log(`
        betId:     ${ks[0]}
        player:    ${ks[1]}
        guessType: ${ks[2]}
        betAmount: ${ks[3]}
        betTime  : ${ks[4]}

        `)
    }
}

function printAllMatches(m: any[]) {

    const showOdds = (odds: any[]) => {
        let cnt = odds.length;
        let s = "";
        for (let i = 0; i < cnt; i++) {
            s += `${odds[i]},`
        }

        return s;
    }

    const showRecords = (rds: any[]) => {
        let s = "";
        for (let it of rds) {
            s += `
                betId:         ${it[0]},
                guessType:     ${it[1]},
                betAmount:     ${it[2]},
                betTime:       ${it[3]},
                claimedAmount: ${it[4]},
                odds:          ${it[5]},
                win:           ${it[6]}

            `;
        }
        return s;
    }

    let count = m.length;
    for (let i = 0; i < count; i++) {
        let mat = m[i];
        console.log(`
        matchId:    ${mat[0]},
        status:     ${mat[1]},
        countryA:   ${mat[2]},
        countryB:   ${mat[3]},
        matchStart: ${mat[4]},
        matchEnd:   ${mat[5]},
        guessStart: ${mat[6]},
        guessEnd:   ${mat[7]},
        scoresA:    ${mat[8]},
        scoresB:    ${mat[9]},
        payToken:   ${mat[10]},

        winLosePool:
            deposited:     ${mat[11][0]},
            withdrawed:    ${mat[11][1]},
            playersAmount: ${mat[11][2]},
            odds: [${showOdds(mat[11][3])}]
            totalBetAmount: [${showOdds(mat[11][4])}]

        scoreGuessPool:
            deposited:     ${mat[12][0]},
            withdrawed:    ${mat[12][1]},
            playersAmount: ${mat[12][2]},
            odds: [${showOdds(mat[12][3])}]
            totalBetAmount: [${showOdds(mat[12][4])}]

        winloseRecords:
            ${showRecords(mat[13])}

        scoreGuessRecords:
            ${showRecords(mat[14])}

        isPaused: ${mat[15]}

        payTokenName:     ${mat[16]}
        payTokenSymbol:   ${mat[17]}
        payTokenDecimals: ${mat[18]}
        -----------------------------------------------

        `)
    }
}

async function main() {

    const lens = await ethers.getContractAt("WorldCupLens", Address.lens);
    for (let player of [player3]) {
        let r = await lens.getAllMatches(Address.qatar, player.getAddress());
        printAllMatches(r);
    }

    for (let i = 1; i <= 1; i++) {
        let topN = await lens.getTopNRecords(Address.qatar, i, 0, 50);
        printTopNRecord(`mathch id ${i} win lose record: `, topN)

        topN = await lens.getTopNRecords(Address.qatar, i, 1, 50);
        printTopNRecord(`mathch id ${i} score guess record: `, topN)
    }

    const wc = await ethers.getContractAt('WorldCupQatar', Address.qatar);
    console.log(`\nfeeRatio:  ${await wc.feeRatio()}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

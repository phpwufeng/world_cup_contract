// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library GuessType {
    uint256 constant GUESS_SCORE_START = 1; // guard label
    uint256 constant GUESS_SCORE_10 = 1;
    uint256 constant GUESS_SCORE_21 = 2;
    uint256 constant GUESS_SCORE_00 = 3;
    uint256 constant GUESS_SCORE_01 = 4;
    uint256 constant GUESS_SCORE_12 = 5;

    uint256 constant GUESS_SCORE_31 = 6;
    uint256 constant GUESS_SCORE_40 = 7;
    uint256 constant GUESS_SCORE_11 = 8;
    uint256 constant GUESS_SCORE_13 = 9;
    uint256 constant GUESS_SCORE_04 = 10;


    uint256 constant GUESS_SCORE_42 = 11;
    uint256 constant GUESS_SCORE_20 = 12;
    uint256 constant GUESS_SCORE_22 = 13;
    uint256 constant GUESS_SCORE_24 = 14;
    uint256 constant GUESS_SCORE_02 = 15;

    uint256 constant GUESS_SCORE_30 = 16;
    uint256 constant GUESS_SCORE_32 = 17;
    uint256 constant GUESS_SCORE_33 = 18;
    uint256 constant GUESS_SCORE_03 = 19;
    uint256 constant GUESS_SCORE_23 = 20;

    uint256 constant GUESS_SCORE_41 = 21;
    uint256 constant GUESS_SCORE_43 = 22;
    uint256 constant GUESS_SCORE_44 = 23;
    uint256 constant GUESS_SCORE_14 = 24;
    uint256 constant GUESS_SCORE_34 = 25;

    uint256 constant GUESS_SCORE_OTHER = 26;
    uint256 constant GUESS_SCORE_END = 26; // guard label


    uint256 constant GUESS_WINLOSE_START = 27; // guard label
    uint256 constant GUESS_WINLOSE_A_WIN = 27;   // countryA 胜
    uint256 constant GUESS_WINLOSE_DRAW = 28;  // countryA 平 countryB
    uint256 constant GUESS_WINLOSE_B_WIN = 29;  // countryB 胜
    uint256 constant GUESS_WINLOSE_END = 29; // guard label

    function isWin(uint256 guessType, uint256 scoresA, uint256 scoresB) internal pure returns(bool) {
        if (scoresA == 0xff && scoresB == 0xff) return false;

        if      (guessType == GUESS_WINLOSE_A_WIN) return scoresA > scoresB;
        else if (guessType == GUESS_WINLOSE_DRAW) return scoresA == scoresB;
        else if (guessType == GUESS_WINLOSE_B_WIN) return scoresA < scoresB;

        else if (guessType == GUESS_SCORE_10) return scoresA == 1 && scoresB == 0;
        else if (guessType == GUESS_SCORE_21) return scoresA == 2 && scoresB == 1;
        else if (guessType == GUESS_SCORE_00) return scoresA == 0 && scoresB == 0;
        else if (guessType == GUESS_SCORE_01) return scoresA == 0 && scoresB == 1;
        else if (guessType == GUESS_SCORE_12) return scoresA == 1 && scoresB == 2;

        else if (guessType == GUESS_SCORE_31) return scoresA == 3 && scoresB == 1;
        else if (guessType == GUESS_SCORE_40) return scoresA == 4 && scoresB == 0;
        else if (guessType == GUESS_SCORE_11) return scoresA == 1 && scoresB == 1;
        else if (guessType == GUESS_SCORE_13) return scoresA == 1 && scoresB == 3;
        else if (guessType == GUESS_SCORE_04) return scoresA == 0 && scoresB == 4;

        else if (guessType == GUESS_SCORE_42) return scoresA == 4 && scoresB == 2;
        else if (guessType == GUESS_SCORE_20) return scoresA == 2 && scoresB == 0;
        else if (guessType == GUESS_SCORE_22) return scoresA == 2 && scoresB == 2;
        else if (guessType == GUESS_SCORE_24) return scoresA == 2 && scoresB == 4;
        else if (guessType == GUESS_SCORE_02) return scoresA == 0 && scoresB == 2;

        else if (guessType == GUESS_SCORE_30) return scoresA == 3 && scoresB == 0;
        else if (guessType == GUESS_SCORE_32) return scoresA == 3 && scoresB == 2;
        else if (guessType == GUESS_SCORE_33) return scoresA == 3 && scoresB == 3;
        else if (guessType == GUESS_SCORE_03) return scoresA == 0 && scoresB == 3;
        else if (guessType == GUESS_SCORE_23) return scoresA == 2 && scoresB == 3;

        else if (guessType == GUESS_SCORE_41) return scoresA == 4 && scoresB == 1;
        else if (guessType == GUESS_SCORE_43) return scoresA == 4 && scoresB == 3;
        else if (guessType == GUESS_SCORE_44) return scoresA == 4 && scoresB == 4;
        else if (guessType == GUESS_SCORE_14) return scoresA == 1 && scoresB == 4;
        else if (guessType == GUESS_SCORE_34) return scoresA == 3 && scoresB == 4;

        else/*if (guessType == GUESS_SCORE_OTHER)*/ {
            return isScoreOtherWin(scoresA, scoresB);
        }
    }

    function isScoreOtherWin(uint256 scoresA, uint256 scoresB) private pure returns(bool) {
        if (
            (scoresA == 1 && scoresB == 0) ||
            (scoresA == 2 && scoresB == 1) ||
            (scoresA == 0 && scoresB == 0) ||
            (scoresA == 0 && scoresB == 1) ||
            (scoresA == 1 && scoresB == 2) ||
            (scoresA == 3 && scoresB == 1) ||
            (scoresA == 4 && scoresB == 0) ||
            (scoresA == 1 && scoresB == 1) ||
            (scoresA == 1 && scoresB == 3) ||
            (scoresA == 0 && scoresB == 4) ||
            (scoresA == 4 && scoresB == 2) ||
            (scoresA == 2 && scoresB == 0) ||
            (scoresA == 2 && scoresB == 2) ||
            (scoresA == 2 && scoresB == 4) ||
            (scoresA == 0 && scoresB == 2) ||
            (scoresA == 3 && scoresB == 0) ||
            (scoresA == 3 && scoresB == 2) ||
            (scoresA == 3 && scoresB == 3) ||
            (scoresA == 0 && scoresB == 3) ||
            (scoresA == 2 && scoresB == 3) ||
            (scoresA == 4 && scoresB == 1) ||
            (scoresA == 4 && scoresB == 3) ||
            (scoresA == 4 && scoresB == 4) ||
            (scoresA == 1 && scoresB == 4) ||
            (scoresA == 3 && scoresB == 4)
        ) return false;
        else return true;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GuessType.sol";
import "./BaseGuess.sol";

contract ScoreGuess is BaseGuess{

    constructor(uint256 matchId) BaseGuess(matchId, GuessType.GUESS_SCORE_START, GuessType.GUESS_SCORE_END - GuessType.GUESS_SCORE_START + 1) {
    }

}
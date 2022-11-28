// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GuessType.sol";
import "./BaseGuess.sol";

contract WinLoseGuess is BaseGuess {

    constructor( uint256 matchId) BaseGuess(matchId, GuessType.GUESS_WINLOSE_START, GuessType.GUESS_WINLOSE_END - GuessType.GUESS_WINLOSE_START + 1) {
    }

}

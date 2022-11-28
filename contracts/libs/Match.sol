// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./GuessType.sol";
import "./WinLoseGuess.sol";
import "./ScoreGuess.sol";

contract Match {

    uint256 public matchId;
    uint256 public countryA;  // match A vs B
    uint256 public countryB;
    uint256 public startTime; // match start time
    uint256 public endTime;   // match end time
    uint256 public guessStartTime;
    uint256 public guessEndTime;
    address public payToken;  // pay erc20 token
    uint256 public finalScores; // 最终比分:   (finalScores & 0xff00) : (finalScores & 0xff )
    bool    public matchFinished; // 比赛最终确定, 可以领取奖励
    bool    public paused;  // status of the match, if paused or not

    address public factory;

    WinLoseGuess public winLose;
    ScoreGuess public scoreGuess;

    constructor(
        uint256 _matchId,
        uint256 _countryA,
        uint256 _countryB,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _guessStartTime,
        uint256 _guessEndTime,
        address _payToken
    ) {
        matchId        = _matchId;
        factory = msg.sender;

        updateSetting(
            _countryA,
            _countryB,
            _startTime,
            _endTime,
            _guessStartTime,
            _guessEndTime,
            _payToken
        );

        winLose = new WinLoseGuess(matchId);
        scoreGuess = new ScoreGuess(matchId);
    }

    function updateSetting(
        uint256 _countryA,
        uint256 _countryB,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _guessStartTime,
        uint256 _guessEndTime,
        address _payToken
    ) public onlyFactory {
        countryA       = _countryA;
        countryB       = _countryB;
        startTime      = _startTime;
        endTime        = _endTime;
        guessStartTime = _guessStartTime;
        guessEndTime   = _guessEndTime;
        payToken       = _payToken;

        finalScores = 0xffffff;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "only factory");
        _;
    }

    function betable() public view returns(bool) {
        return !paused && !matchFinished && guessStartTime <= block.timestamp && block.timestamp <= guessEndTime;
    }

    function finished() public view returns(bool) {
        return finalScores != 0xffffff && matchFinished;
    }

    function recallable() public view returns(bool) {
        return paused && !finished();
    }

    function genBetId(uint256 guessType, address player) internal view returns(uint256 betId) {
        betId = (matchId << 168) | ((guessType & 0xff) << 160) | uint256(uint160(player));
    }

    function isWin(uint256 guessType) public view returns(bool) {
        return GuessType.isWin(guessType, (finalScores & 0xff00) >> 8, finalScores & 0xff);
    }

    function parseBetId(uint256 betId) public pure returns(uint256 matId, uint256 guessType, address player) {
        matId = uint256(betId >> 168);
        guessType = uint256((betId >> 160) & 0xff);
        player = address(uint160(betId));
    }

    // 竞猜
    function guess(address player, uint256 guessType, uint256 payAmount)
        public
        onlyFactory
        returns(uint256 betId)
    {
        betId = genBetId(guessType, player);
        if (guessType >= GuessType.GUESS_WINLOSE_START && guessType <= GuessType.GUESS_WINLOSE_END) {
            winLose.guess(betId, player, guessType, payAmount);
        } else if (GuessType.GUESS_SCORE_START <= guessType && guessType <= GuessType.GUESS_SCORE_END) {
            scoreGuess.guess(betId, player, guessType, payAmount);
        } else {
            require(false, "not support guess type");
        }
    }

    // 用户提取收益
    function claimReward(address player, uint256 betId) public onlyFactory returns(uint256 amount) {
        (uint256 matId, uint256 guessType, address better) = parseBetId(betId);
        require(matId == matchId, "match id not matched");
        require(better == player, "claimer not match better");
        require(isWin(guessType), "not win bet");

        if (GuessType.GUESS_WINLOSE_START <= guessType && guessType <= GuessType.GUESS_WINLOSE_END) {
            amount = winLose.claim(player, guessType);
        } else if (GuessType.GUESS_SCORE_START <= guessType && guessType <= GuessType.GUESS_SCORE_END) {
            amount = scoreGuess.claim(player, guessType);
        } else {
            require(false, "not support guess type");
        }
    }
    // 领取所有未领取的竞猜
    function claimAllRewards(address player) public onlyFactory returns(uint256 amount) {
        amount += claimAGuess(address(winLose), player);
        amount += claimAGuess(address(scoreGuess), player);
    }

    function claimAGuess(address bga, address player) internal returns(uint256) {
        BaseGuess pool = BaseGuess(bga);
        uint256 joined = pool.playerJoinedGuessType(player);
        uint256 count = joined & 0x1F;
        uint256 claimed;
        if (count > 0) {
            joined = joined >> 5;
            for (uint i = 0; i < count; i++) {
                uint256 guessType = ((joined >> (5 * i)) & 0x1F);
                if (!isWin(guessType)) continue;

                (, , uint256 claimedAmount) = pool.getPlayerBetInfo(player, guessType);
                if (claimedAmount > 0) continue;

                uint256 payback = pool.payback(player, guessType);
                if (payback == 0) continue;

                claimed += pool.claim(player, guessType);
            }
        }
        return claimed;
    }

    // 用户提取收益
    function recall(address player, uint256 betId) public onlyFactory returns(uint256 amount) {
        (uint256 matId, uint256 guessType, address better) = parseBetId(betId);
        require(matId == matchId, "match id not matched");
        require(better == player, "player not match better");

        if (GuessType.GUESS_WINLOSE_START <= guessType && guessType <= GuessType.GUESS_WINLOSE_END) {
            amount = winLose.recall(player, guessType);
        } else if (GuessType.GUESS_SCORE_START <= guessType && guessType <= GuessType.GUESS_SCORE_END) {
            amount = scoreGuess.recall(player, guessType);
        } else {
            require(false, "not support guess type");
        }
    }

    // 无人猜中
    function isNobodyWin(uint256 guessType) public view returns(bool , uint256) {
         if(!isWin(guessType)) {
            return (false, 0);
         }
         if (guessType >= GuessType.GUESS_WINLOSE_START && guessType <= GuessType.GUESS_WINLOSE_END) {
            uint256 index = winLose.guessType2Index(guessType);
            (uint256 deposit, uint256 playersAmount,) = winLose.pools(index);
            return (deposit == 0 && playersAmount == 0)
                ? (true, winLose.totalDeposit())
                : (false, 0);
        } else if (GuessType.GUESS_SCORE_START <= guessType && guessType <= GuessType.GUESS_SCORE_END) {
            uint256 index = scoreGuess.guessType2Index(guessType);
            (uint256 deposit, uint256 playersAmount,) = scoreGuess.pools(index);
            return (deposit == 0 && playersAmount == 0)
                ? (true, scoreGuess.totalDeposit())
                : (false, 0);
        } else {
            return (false, 0);
        }
    }
    // 设置最终比分
    function setFinalScores(uint256 scoresA, uint256 scoresB) public onlyFactory {
        // composite final scores
        finalScores = (((scoresA & 0xff) << 8) | (scoresB & 0xff));
    }

    function setMatchFinished() public onlyFactory {
        require(finalScores != 0xffffff, "scores not set");
        matchFinished = true;
    }

    // 暂停比赛
    function pause(bool status) public onlyFactory {
        paused = status;
    }
}
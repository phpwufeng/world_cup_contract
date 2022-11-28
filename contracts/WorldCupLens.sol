// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./WorldCupQatar.sol";
import "./libs/Match.sol";
import "./libs/BaseGuess.sol";

contract WorldCupLens {
    enum MatchStatus {
        GUESS_NOT_START,  // 竞猜未开始
        GUESS_ON_GOING,   // 竞猜进行中
        MATCH_ON_GOING,   // 进行中
        MATCH_FINISHED  // 比赛己完成
    }

    struct GuessPool {
        uint256 deposited;  // 总参与的奖池金额
        uint256 withdrawed; // 总已提取奖金
        uint256 playersAmount; // 总参与人数
        uint256[] odds;        // 赔率列表
        uint256[] eachDeposited;   // 每一个guessType池的总下注额
    }

    struct BetRecord {
        uint256 betId;     // 下注ID
        uint256 guessType; // 竞猜类型
        uint256 betAmount; // 下注数额
        uint256 betTime;   // 下注时间
        uint256 claimedAmount; // 已经领取的奖励
        uint256 odds;     // 胜率
        bool win;     // 是否赢得比赛
    }

    struct MatchStatistics {
        uint256 matchId;    // 比赛id
        MatchStatus status; // 比赛状态
        uint256 countryA;   // 参赛国A
        uint256 countryB;   // 参赛国B
        uint256 matchStartTime; // 比赛开发时间
        uint256 matchEndTime;   // 比赛结束时间
        uint256 guessStartTime;  // 竞猜开始时间
        uint256 guessEndTime;  // 竞猜结束时间
        uint256 scoresA; // 比赛结果 countryA进球数, 如果是 0xff表示没有出比分
        uint256 scoresB; // 比赛结果 countryB进球数
        address payToken; // 支付Token

        GuessPool winlosePool;  // 猜输赢奖池金额
        GuessPool scoreGuessPool;  // 猜比分奖池金额

        BetRecord[] winloseRecords; // player猜输赢的下单
        BetRecord[] scoreGuessRecords; // player猜比分的下单

        bool isPaused;

        string payTokenName;
        string payTokenSymbol;
        uint256 payTokenDecimals;
    }

    function getGuessPoolInfo(address poolAddr) private view returns(GuessPool memory) {
        GuessPool memory guessPool;

        BaseGuess baseGuess = BaseGuess(poolAddr);
        guessPool.deposited = baseGuess.totalDeposit();
        guessPool.withdrawed = baseGuess.totalClaimRewards();
        guessPool.playersAmount = baseGuess.totalBetPlayers();

        uint256 wlPoolsCount = baseGuess.POOL_COUNT();
        uint256 wlPoolsStart = baseGuess.GUESS_TYPE_START();
        guessPool.odds = new uint256[](wlPoolsCount);
        guessPool.eachDeposited = new uint256[](wlPoolsCount);
        for (uint256 i = 0; i < wlPoolsCount; i++) {
            guessPool.odds[i] = baseGuess.odds(wlPoolsStart + i);
            (guessPool.eachDeposited[i],,) = baseGuess.pools(i);
        }

        return guessPool;
    }

    function getGuessRecord(Match mat, address poolAddr, address player) private view returns(BetRecord[] memory) {
        BetRecord[] memory result;
        BaseGuess bg = BaseGuess(poolAddr);
        uint256 r = bg.playerJoinedGuessType(player);
        uint256 count = r & 0x1F;

        if (count > 0) {
            result = new BetRecord[](count);
            r = r >> 5;

            for (uint i = 0; i < count; i++) {
                BetRecord memory rd;
                uint256 guessType = ((r >> (5 * i)) & 0x1F);
                rd.betId = ((mat.matchId() << 168) | ((guessType & 0xff) << 160) | uint256(uint160(player)));
                rd.guessType = guessType;
                (rd.betAmount, rd.betTime, rd.claimedAmount) = bg.getPlayerBetInfo(player, guessType);
                rd.odds = bg.odds(guessType);
                rd.win = mat.isWin(guessType);

                result[i] = rd;
            }
        }

        return result;
    }

    function getMatchStatistics(Match mat, address player) public view returns (MatchStatistics memory ) {
        MatchStatistics memory result;

        result.matchId = mat.matchId();
        result.countryA = mat.countryA();
        result.countryB = mat.countryB();
        result.matchStartTime = mat.startTime();
        result.matchEndTime = mat.endTime();
        result.guessStartTime = mat.guessStartTime();
        result.guessEndTime = mat.guessEndTime();

        uint256 finalScores = mat.finalScores();
        result.scoresA = (finalScores & 0xff00) >> 8;
        result.scoresB = (finalScores & 0xff);

        bool matchFinished = mat.matchFinished();

        if (matchFinished) result.status = MatchStatus.MATCH_FINISHED;
        else if (block.timestamp < result.guessStartTime)  result.status = MatchStatus.GUESS_NOT_START;
        else if (block.timestamp > result.matchStartTime)  result.status = MatchStatus.MATCH_ON_GOING;
        else result.status = MatchStatus.GUESS_ON_GOING;

        result.payToken = mat.payToken();
        result.winlosePool = getGuessPoolInfo(address(mat.winLose()));
        result.scoreGuessPool = getGuessPoolInfo(address(mat.scoreGuess()));

        if (player != address(0)) {
            result.winloseRecords = getGuessRecord(mat, address(mat.winLose()), player);
            result.scoreGuessRecords = getGuessRecord(mat, address(mat.scoreGuess()), player);
        }

        result.isPaused = mat.paused();

        IERC20Metadata payToken = IERC20Metadata(result.payToken);
        result.payTokenName = payToken.name();
        result.payTokenSymbol = payToken.symbol();
        result.payTokenDecimals = payToken.decimals();

        return result;
    }

    function getAllMatches(WorldCupQatar wc, address player) public view returns(MatchStatistics[] memory) {
        uint256 matchesCount = wc.totalMatches();
        MatchStatistics[] memory result = new MatchStatistics[](matchesCount);

        for (uint i = 1; i <= matchesCount; i++) {
            result[i - 1] = getMatchStatistics(wc.matches(i), player);
        }

        return result;
    }

    struct TopNRecords {
        uint256 betId;        // 下注ID
        address player;      // 下注人
        uint256 guessType;   // 竞猜类型 参考GuessType.sol中的类型
        uint256 betAmount;   // 下注额
        uint256 betTime;     // 下注时间
    }

    // 查询当前比赛奖池的topN个投注纪录,
    // @param poolType: 0 猜胜负   1 猜比分
    // @param n : 取前n条
    function getTopNRecords(WorldCupQatar wc, uint256 matchId, uint256 poolType, uint256 n)
        public
        view
        returns(TopNRecords[] memory)
    {
        BaseGuess target;
        Match mat = wc.matches(matchId);

        if (poolType == 0) {
            target = BaseGuess(mat.winLose());
        } else {
            target = BaseGuess(mat.scoreGuess());
        }
        TopNRecords[] memory result;

        uint256 totalRecords = target.totalSeq();
        if (totalRecords > 0) {
            n = n > totalRecords ? totalRecords : n;
            result = new TopNRecords[](n);

            for (uint i = totalRecords; i > (totalRecords - n); i--) {
                TopNRecords memory t;
                t.betId = target.sequenceRecords(i);
                (,t.guessType, t.player) = mat.parseBetId(t.betId);
                (t.betAmount, t.betTime, ) = target.getPlayerBetInfo(t.player, t.guessType);

                result[totalRecords - i] = t;
            }
        }

        return result;
    }
}
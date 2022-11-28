// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./libs/Match.sol";
import "./libs/Country.sol";

contract WorldCupQatar is AccessControl {
    bytes32 public constant SETTING_ROLE = keccak256("SETTING_ROLE");
    uint256 public feeRatio = 0.03E18;
    address public vault;

    uint256 public totalMatches;
    mapping(uint256 => Match) public matches;

    event MatchStarted(
        uint256 indexed matchId,
        uint256 countryA,
        uint256 countryB,
        uint256 startTime,
        uint256 endTime,
        uint256 guessStartTime,
        uint256 guessEndTime,
        address payToken
    );

    event MatchUpdated(
        uint256 indexed matchId,
        uint256 countryA,
        uint256 countryB,
        uint256 startTime,
        uint256 endTime,
        uint256 guessStartTime,
        uint256 guessEndTime,
        address payToken
    );

    event MatchGuessed(
        uint256 indexed matId,
        address indexed player,
        uint256 indexed betId,
        uint256 guessType,
        uint256 payAmount,
        uint256 betAmount
    );

    event MatchFinished(
        uint256 indexed matId,
        uint256 countryA,
        uint256 countryB,
        uint256 scoresA,
        uint256 scoresB
    );

    event MatchPaused(
        uint256 indexed matId,
        bool    paused
    );

    event MatchNobodyWin(
        uint256 indexed matId,
        uint256 guessType
    );

    event RewardClaimed(
        uint256 indexed matId,
        address indexed player,
        uint256 indexed betId,
        uint256 betReward
    );

    event AllRewardClaimed(
        address indexed player,
        uint256 totalClaimed
    );

    event PlayerRecalled(
        uint256 indexed matId,
        address indexed player,
        uint256 indexed betId,
        uint256 betAmount
    );

    constructor(address owner, address _vault) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        _grantRole(SETTING_ROLE, owner);

        vault = _vault;
    }

    // 设置拥有setting权限的账号
    function setSettingRole(address role, bool toGrant) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (toGrant) _grantRole(SETTING_ROLE, role);
        else         _revokeRole(SETTING_ROLE, role);
    }

    // 设置手续费率
    function setFeeRatio(uint256 _feeRatio) public onlyRole(SETTING_ROLE) {
        require(_feeRatio < 1E18, "ratio over 1");
        feeRatio = _feeRatio;
    }

    // 设置猜输赢的最终比分
    function setScores(uint256 matId, uint256 scoresA, uint256 scoresB)
        public
        onlyRole(SETTING_ROLE)
    {
        Match mat = matches[matId];
        require(address(mat) != address(0), "match not exist");
        // require(block.timestamp >= mat.endTime(), "match is not end");
        require(!mat.matchFinished(), "match finished");

        mat.setFinalScores(scoresA, scoresB);

        emit MatchFinished(matId, mat.countryA(), mat.countryB(), scoresA, scoresB);
    }

    // 设置一场比赛结束, 可以领取奖励
    function setMatchFinished(uint256 matId) public onlyRole(SETTING_ROLE) {
        Match mat = matches[matId];
        require(address(mat) != address(0), "match not exist");
        require(!mat.finished(), "already finished");

        mat.setMatchFinished();

        for (uint i = GuessType.GUESS_SCORE_START; i <= GuessType.GUESS_WINLOSE_END; i++) {
            (bool status, uint256 amount) = mat.isNobodyWin(i);
            if (!status || amount == 0) continue;

            chargePayout(mat.payToken(), vault, amount);
        }
    }
    // 暂停/恢复一场比赛
    function pauseMatch(uint256 matId, bool toPause)
        public
        onlyRole(SETTING_ROLE)
    {
        Match mat = matches[matId];
        require(address(mat) != address(0), "match not exist");

        mat.pause(toPause);
        emit MatchPaused(matId, toPause);
    }

    // 设置一场猜胜负的比赛
    function startMatch(
        uint256 countryA,
        uint256 countryB,
        uint256 matchStartTime,
        uint256 matchEndTime,
        uint256 guessStartTime,
        uint256 guessEndTime,
        address payToken
    )
        public
        onlyRole(SETTING_ROLE)
    {
        require(Country.valid(countryA), "countryA unknown");
        require(Country.valid(countryB), "countryB unknown");
        require(countryA != countryB, "same country not allowed");
        require(matchStartTime < matchEndTime,"invalid time setting");
        require(guessStartTime < guessEndTime, "guess time invalid");
        require(guessEndTime <= matchStartTime, "guess end time invalid");
        require(payToken != address(0), "payToken is null address");

        totalMatches += 1;
        uint256 matchId = totalMatches;

        Match mat = new Match(
            matchId,
            countryA,
            countryB,
            matchStartTime,
            matchEndTime,
            guessStartTime,
            guessEndTime,
            payToken
        );

        matches[matchId] = mat;

        emit MatchStarted(matchId, countryA, countryB, matchStartTime, matchEndTime, guessStartTime, guessEndTime, payToken);
    }

    // 更新比赛设置
    function updateMatch(
        uint256 matchId,
        uint256 countryA,
        uint256 countryB,
        uint256 matchStartTime,
        uint256 matchEndTime,
        uint256 guessStartTime,
        uint256 guessEndTime,
        address payToken
    )
        public
        onlyRole(SETTING_ROLE)
    {
        Match mat = matches[matchId];
        require(Country.valid(countryA), "countryA unknown");
        require(Country.valid(countryB), "countryB unknown");
        require(countryA != countryB, "same country not allowed");
        require(address(mat) != address(0), "match not exist");
        require(matchStartTime < matchEndTime,"invalid mat time setting");
        require(guessStartTime < guessEndTime, "guess time setting invalid");
        require(guessEndTime <= matchStartTime, "guess end time invalid");
        require(payToken != address(0), "payToken is null address");
        require(!mat.finished(), "match finished");

        mat.updateSetting(countryA, countryB, matchStartTime, matchEndTime, guessStartTime, guessEndTime, payToken);

        emit MatchUpdated(matchId, countryA, countryB, matchStartTime, matchEndTime, guessStartTime, guessEndTime, payToken);
    }
    /**
    * 竞猜
    *
    * @param matId match id
    * @param guessType guess type: refer to GuessType.sol
    * @param payAmount 压注金额
    */

    function guess(uint256 matId, uint256 guessType, uint256 payAmount) public {
        Match mat = matches[matId];
        require(address(mat) != address(0), "match not exist");
        require(payAmount > 0, "bet amount invalid");
        require(mat.betable(), "match is not betable");

        uint256 betAmount = chargePayin(mat.payToken(), msg.sender, payAmount);

        uint256 betId = mat.guess(msg.sender, guessType, betAmount);

        emit MatchGuessed(matId, msg.sender, betId, guessType, payAmount, betAmount);
    }

    // 领取奖励
    function claimReward(uint256 matId, uint256 betId) public {
        Match mat = matches[matId];
        require(address(mat) != address(0), "match not exist");
        require(mat.finished(), "match is not finished");

        uint256 betReward = mat.claimReward(msg.sender, betId);
        chargePayout(mat.payToken(), msg.sender, betReward);

        emit RewardClaimed(matId, msg.sender, betId, betReward);
    }
    // 领取所有未
    function claimAllRewards() public {
        uint256 totalClaimed;
        for (uint i = 1; i <= totalMatches; i++) {
            Match mat = matches[i];
            if (mat.paused() || !mat.finished()) continue;

            uint256 amount = mat.claimAllRewards(msg.sender);

            if (amount > 0) chargePayout(mat.payToken(), msg.sender, amount);

            totalClaimed += amount;
        }

        require(totalClaimed > 0, "no more rewards");

        emit AllRewardClaimed(msg.sender, totalClaimed);
    }

    // 因为任何暂停, 可以recall
    function recall(uint256 matId, uint256 betId) public {
        Match mat = matches[matId];
        require(address(mat) != address(0), "match not exist");
        require(mat.recallable(), "can not recall");

        uint256 betAmount = mat.recall(msg.sender, betId);
        chargePayout(mat.payToken(), msg.sender, betAmount);

        emit PlayerRecalled(matId, msg.sender, betId, betAmount);
    }

    // 没有任何人猜中, 池子中的奖励归国库
    // function nobodyWin(uint256 matId, uint256 guessType) public {
    //     Match mat = matches[matId];
    //     require(address(mat) != address(0), "match not exist");
    //     require(mat.finished(), "match is not finished");

    //     (bool status, uint256 amount) = mat.isNobodyWin(guessType);
    //     require(status, "somebody win");

    //     chargePayout(mat.payToken(), vault, amount);

    //     emit MatchNobodyWin(matId, guessType);
    // }

    // ---------------- private functions -------------------------------------------------------
    function chargePayin(address token, address from, uint256 amount) private returns(uint256) {
        IERC20 payToken = IERC20(token);
        payToken.transferFrom(from, address(this), amount);

        uint256 fee = amount * feeRatio / 1E18;
        payToken.transfer(vault, fee);

        return amount - fee;
    }

    function chargePayout(address token, address to, uint256 amount) private {
        IERC20 payToken = IERC20(token);
        payToken.transfer(to, amount);
    }
}

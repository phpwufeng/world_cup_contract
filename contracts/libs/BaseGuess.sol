// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "hardhat/console.sol";

contract BaseGuess {

    struct Pool {
        uint256 deposited; // 压注总金额
        uint256 playersAmount; // 压注总账号数
        uint256 withdrawedRewards; // 总共已经领取了的奖励
        mapping(address => uint256) betAmount; // 每账号 => 压注金额
        mapping(address => uint256) betTime; // 每账号 => 压注金额
        mapping(address => uint256) rewardClaimed; // 是否已经领取了收益
    }

    address public factory;
    uint256 public matchId;

    uint256 public totalSeq;
    mapping(uint256 => uint256) public sequenceRecords; // seq betIndex => betId

    uint256 public immutable POOL_COUNT;
    uint256 public immutable GUESS_TYPE_START;
    Pool[] public pools;

    mapping(address => uint256) public playerJoinedGuessType;

    modifier onlyFactory() {
        require(msg.sender == factory, "only factory");
        _;
    }

    constructor(uint256 _matchId, uint256 typeStart, uint256 count) {
        POOL_COUNT = count;
        GUESS_TYPE_START = typeStart;

        matchId = _matchId;
        factory = msg.sender;

        for (uint i = 0; i < POOL_COUNT; i++) {
            pools.push();
        }
    }

    function totalDeposit() public view returns(uint256) {
        uint256 amount;
        for (uint i = 0; i < POOL_COUNT; i++) {
            amount += pools[i].deposited;
        }
        return amount;
    }

    function totalClaimRewards() public view returns(uint256) {
        uint256 amount;
        for (uint i = 0; i < POOL_COUNT; i++) {
            amount += pools[i].withdrawedRewards;
        }
        return amount;
    }

    function totalBetPlayers() public view returns(uint256) {
        uint256 amount;
        for (uint i = 0; i < POOL_COUNT; i++) {
            amount += pools[i].playersAmount;
        }
        return amount;
    }

    function getPlayerBetInfo(address player, uint256 guessType)
        public
        view
        returns(uint256 bAmount, uint256 bTime, uint256 rClaimed)
    {
        uint256 index = guessType2Index(guessType);
        bAmount = pools[index].betAmount[player];
        bTime = pools[index].betTime[player];
        rClaimed = pools[index].rewardClaimed[player];
    }

    function guessType2Index(uint256 guessType) public view returns(uint256 index) {
        return guessType - GUESS_TYPE_START;
    }

    function odds(uint256 guessType) public view returns(uint256) {
        uint256 index = guessType2Index(guessType);
        return pools[index].deposited == 0
               ? 0
               : totalDeposit() * 1E18 / pools[index].deposited;
    }

    function payback(address player, uint256 guessType)
        public
        view
        returns(uint256 amount)
    {
        uint256 index = guessType2Index(guessType);
        amount = odds(guessType) * pools[index].betAmount[player] / 1E18;
    }

    function setSequenceRecord(uint256 betId) private {
        totalSeq++;
        sequenceRecords[totalSeq] = betId;
    }

    function playerJoined(address player, uint256 guessType) private {
        uint256 gType = (guessType & 0x1F);
        uint256 pJoined = playerJoinedGuessType[player];
        uint256 count = (pJoined & 0x1F) + 1;
        pJoined = pJoined >> 5;

        pJoined = ((pJoined << 5) | gType);
        pJoined = (pJoined << 5) | count;
        playerJoinedGuessType[player] = pJoined;
    }

    function guess(uint256 betId, address player, uint256 guessType, uint256 payAmount) public onlyFactory {
        uint256 index = guessType2Index(guessType);
        Pool storage pool = pools[index];

        if (pool.betAmount[player] == 0) {
            pool.playersAmount += 1;
            setSequenceRecord(betId);
            playerJoined(player, guessType);
        }

        pool.betAmount[player] += payAmount;
        pool.betTime[player] = block.timestamp;
        pool.deposited += payAmount;
    }

    function claim(address player, uint256 guessType) public onlyFactory returns(uint256) {
        uint256 rewards = payback(player, guessType);
        require(rewards != 0, "have no rewards");

        uint256 index = guessType2Index(guessType);

        require(pools[index].rewardClaimed[player] == 0, "reward claimed");

        pools[index].rewardClaimed[player] = rewards;
        pools[index].withdrawedRewards += rewards;

        return rewards;
    }

    function recall(address player, uint256 guessType) public onlyFactory returns(uint256 amount) {
        uint256 index = guessType2Index(guessType);

        amount = pools[index].betAmount[player];
        require(amount != 0, "not joined pool");

        delete pools[index].betAmount[player];

        pools[index].deposited -= amount;

        // YES, I don't sub pools[index].playersAmount because I can not get its sequence id now
        // and just KEEP it is no matter.
    }
}
# WorldCupQatar Contracts

## 部署
合约可以部署到bsc和heco链上.   

### 部署到bsc  
```bash
PRIVATE_KEY=4313d6bb58d91ad2d112ba1e9ec07852e0bd952809ecd83dfd6892b9f0799ad6 OWNER=0xa3f45b3ab5ff54d24d61c4ea3f39cc98ebcb3c7e VAULT=0x11e07aed82f1210ddab32fcd9419f56162b2794f npx hardhat run scripts/deploy_on_chain.ts --network bsc
```

请替换以上参数为实际的参数.  
* PRIVATE_KEY    部署合约账号, 需要有BNB作为手续费
* OWNER          合约的owner账号, 用于管理合约.  **合约中无法再更改这个地址**
* VAULT          国库账号, 用于接收管理费或无人猜中的比赛的奖励. **合约中无法再更改这个地址**

### 部署到heco
```bash
PRIVATE_KEY=4313d6bb58d91ad2d112ba1e9ec07852e0bd952809ecd83dfd6892b9f0799ad6 OWNER=0xa3f45b3ab5ff54d24d61c4ea3f39cc98ebcb3c7e VAULT=0x11e07aed82f1210ddab32fcd9419f56162b2794f npx hardhat run scripts/deploy_on_chain.ts --network heco
```
同样请替换以上参数为真实的参数.

## 管理合约方法

### 设置参数设置账号
> 用于设置一个账号的权限, 使得它可以执行开启比赛等操作.
* 原型:  
`function setSettingRole(address role, bool toGrant)`

需要OWNER权限.  
参数:  
`role`: 账号地址  
`toGrant`: true / false, 表示是否授权.

### 开启一场比赛
> 用于设置一场比赛. 
```js
function startMatch(
        uint256 countryA,
        uint256 countryB,
        uint256 matchStartTime,
        uint256 matchEndTime,
        uint256 guessStartTime,
        uint256 guessEndTime,
        address payToken
    )
```
需要SETTING ROLE权限.  
参数:  
`countryA`: 比赛国家A的编号  
`countryB`: 比赛国家B的编号  
`matchStartTime`: 比赛开始时间  
`matchEndTime`:   比赛结束时间  
`guessStartTime`: 下注开始时间  
`guessEndTime`:    下注结束时间  
`payToke`:       TT的地址  

注意:  1. 国家编号请参考Country.sol文件   2. 时间均为EPOCH的seconds数.

### 更新比赛信息
> 用于某些情况下, 开启了一场错误的比赛, 需要更新参数.  
```
function updateMatch(
        uint256 matchId,
        uint256 countryA,
        uint256 countryB,
        uint256 startTime,
        uint256 endTime,
        uint256 guessStartTime,
        uint256 guessEndTime,
        address payToken
    )
```

参数中除了`matchId`是需要提供的之外, 其它参数同`startMatch`.

### 设置比赛结果  
> 用于设置比分

`function setScores(uint256 matId, uint256 scoresA, uint256 scoresB)`   
需要SETTING ROLE权限.  

参数:  
`matId` 比赛的ID  
`scoresA`  比赛国家A的进球数.  
`scoresB`  比赛国家B的进球数.  

### 暂停比赛
> 用于特殊情况下, 暂停一场比赛

`function pauseMatch(uint256 matId, bool toPause)`  
需要SETTING ROLE权限.  
参数:  
`matId` 比赛的ID  
`toPause` true/false, 对应是否暂停/恢复比赛.  

## 玩家参与方法
1. 参与竞猜  
`function guess(uint256 matId, uint256 guessType, uint256 payAmount)`   
2. 领取奖励  
`function claimReward(uint256 matId, uint256 betId) public`  
3. 比赛暂停情况下撤回下单  
`function recall(uint256 matId, uint256 betId) public`
4. 无人猜中时, 将奖励归入国库
`function nobodyWin(uint256 matId, uint256 guessType) public`

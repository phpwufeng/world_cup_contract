// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Country {
    uint256 constant Senegal = 1;       // 塞内加尔
    uint256 constant Holland = 2;       // 荷兰
    uint256 constant Qatar   = 3;       // 卡塔尔
    uint256 constant Ecuador = 4;       // 厄瓜多尔

    uint256 constant England = 5;       // 英格兰
    uint256 constant Iran    = 6;       // 伊朗
    uint256 constant Usa     = 7;       // 美国
    uint256 constant Welsh   = 8;       // 威尔士

    uint256 constant Argentina = 9;     // 阿根廷
    uint256 constant Saudi     = 10;    // 沙特
    uint256 constant Mexico    = 11;    // 墨西哥
    uint256 constant Poland    = 12;    // 波兰

    uint256 constant Denmark    = 13;   // 丹麦
    uint256 constant Tunisia    = 14;   // 突尼斯
    uint256 constant France     = 15;   // 法国
    uint256 constant Australia  = 16;   // 澳大利亚

    uint256 constant Germany   = 17;    // 德国
    uint256 constant Japan     = 18;    // 日本
    uint256 constant Spanish   = 19;    // 西班牙
    uint256 constant CostaRica = 20;    // 哥斯达黎加

    uint256 constant Morocco = 21;      // 摩洛哥
    uint256 constant Croatia = 22;      // 克罗地亚
    uint256 constant Belgium = 23;      // 比利时
    uint256 constant Canada  = 24;      // 加拿大

    uint256 constant Switzerland  = 25; // 瑞士
    uint256 constant Cameroon     = 26; // 喀麦隆
    uint256 constant Brazil       = 27; // 巴西
    uint256 constant Serbia       = 28; // 塞尔维亚

    uint256 constant Uruguay  = 29;     // 乌拉圭
    uint256 constant Korea    = 30;     // 韩国
    uint256 constant Portugal = 31;     // 葡萄牙
    uint256 constant Ghana    = 32;     // 加纳

    function valid(uint256 country) internal pure returns(bool) {
        return Senegal <= country && country <= Ghana;
    }
}
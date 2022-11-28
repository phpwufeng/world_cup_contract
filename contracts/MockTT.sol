// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MockTT is ERC20 {

    constructor() ERC20("MockTT", "TT") {}

    function mint(address recipient, uint256 amount) public {
        _mint(recipient, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Pool {
    using SafeMath for uint256;

    uint256 public TVL;
    mapping(address => uint256) public globalDeposits;

    constructor() {}

    function updateDeposit(uint256 _amount, address _user) external {
        TVL = TVL.add(_amount);
        globalDeposits[_user] = globalDeposits[_user].add(_amount);
    }

    function getTotalDeposit(address _user) external view returns (uint256){
        return globalDeposits[_user];
    }
}

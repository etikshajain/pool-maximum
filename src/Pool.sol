// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./PrizePool.sol";

contract Pool is Ownable {
    using SafeMath for uint256;

    uint256 public TVL;
    mapping(address => uint256) public globalDeposits;

    constructor() {
    }

    struct PrizePoolStruct {
        address prizePoolAddress;
        address tokenAddress;
        address yearnVaultAddress;
        uint256 depositionDeadline;
        uint256 withdrawalTime;
        uint256 winnerAwardShare;
    }
    PrizePoolStruct[] public prizePools;

    function createPrizePool(string memory name, string memory symbol, address yearnVaultAddress, address token, uint256 awardShare) onlyOwner public {
        PrizePool pp = new PrizePool(name, symbol, yearnVaultAddress, token, address(this), awardShare);
        prizePools.push(PrizePoolStruct(address(pp), token, yearnVaultAddress, pp.depositDeadline(), pp.nextDrawTime(), awardShare));
    }

    function fetchPools() public view returns(PrizePoolStruct[] memory) {
        return prizePools;
    }

    function updateUserDeposit(uint256 _amount, address _user) external {
        TVL = TVL.add(_amount);
        globalDeposits[_user] = globalDeposits[_user].add(_amount);
    }

    function getUserTotalDeposit(address _user) external view returns (uint256){
        return globalDeposits[_user];
    }
}

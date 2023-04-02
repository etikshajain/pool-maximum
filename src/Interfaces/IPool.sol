// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IPool {

    function updateUserDeposit(uint256 _amount, address _user) external;

    function getUserTotalDeposit(address _user) external view returns (uint256);
}

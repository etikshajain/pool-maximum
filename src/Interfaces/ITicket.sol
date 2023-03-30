// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IControlledToken.sol";

interface ITicket is IControlledToken {
    function getBalance(address _user) external view returns(uint256);
}

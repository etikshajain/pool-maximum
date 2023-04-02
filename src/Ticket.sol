// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./ControlledToken.sol";

contract Ticket is ControlledToken {
    mapping(address => uint256) internal userBalance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _controller
    ) ControlledToken(_name, _symbol, decimals_, _controller) {}

    function getBalance(address _user) external view returns(uint256) {
        return userBalance[_user];
    }
}


// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {VaultAPI} from "http://github.com/yearn/yearn-vaults/contracts/BaseStrategy.sol";
import "./IPool.sol";
import "./ITicket.sol";

contract PrizePool is Ownable {
    using SafeMath for uint256;

    address public vaultAddress;
    IPool public pool;
    address public token; //token to be deposited into vault-eth address
    ITicket public ticket;

    uint256 public winner;
    uint256 public nextDrawTime;
    uint256 public depositDeadline;

    mapping(address => uint256) public deposits;
    mapping(uint256 => address) public index;
    mapping(address => uint256) public tickets;

    uint256 public count;
    uint256 public totalDeposits;
    uint256 public totalTicketSupply;
    uint256 public totalFundsRetrieved;
    uint256 public totalInterest;
    // percentage of interest to be given to the winner and rest to be distributed among the rest
    uint256 public awardShare;

    VaultAPI public v;

    mapping(address => uint256) public globalDeposits;
    uint256 public totalGlobalDeposits;

    constructor(address _ticketAddress, address _vaultAddress, address _token, address _poolAddress, uint256 _awardShare) {
        // deploy ticket 
        ticket = ITicket(_ticketAddress);
        pool = IPool(_poolAddress);
        nextDrawTime = block.timestamp + 1 weeks;
        depositDeadline = block.timestamp + 1 days;
        vaultAddress = _vaultAddress;
        token = _token;
        count = 0;
        awardShare = _awardShare;
        v = VaultAPI(vaultAddress);
    }

    function deposit(uint256 _amount) external {
        require(block.timestamp < depositDeadline, "Sorry the deposit deadline is passed, please wait till the next round starts.");
        require(IERC20(token).transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // check if user has already deposited
        if(deposits[msg.sender] == 0){
            index[count] = msg.sender;
            count = count.add(1);
        }

        totalDeposits = totalDeposits.add(_amount);
        deposits[msg.sender] = deposits[msg.sender].add(_amount);
    }

    function depositToYv() external {
        require(block.timestamp > depositDeadline, "Deposition perios is still going on!");
        require(block.timestamp < nextDrawTime, "Cannot deposit to vault now!");
        require(totalDeposits > 0, "Amount must be greater than 0");

        // balance of prizepool in vault before this round
        uint256 beforeBalance = v.balanceOf(address(this));
        // approve the vault to use our deposit
        IERC20(token).approve(address(v), totalDeposits);
        // deposit funds into vault
        v.deposit(totalDeposits);
        // balance of prizepool in vault after deposit
        uint256 afterBalance = v.balanceOf(address(this));
        // shares of prizepool in vault
        uint256 shares = afterBalance - beforeBalance;
        require(shares > 0, "Shares must be greater than 0");

        totalTicketSupply = shares;

        // mint tokens
        for(uint i = 0; i <= count; i++) {
            tickets[index[i]] = (deposits[index[i]].div(totalDeposits)).mul(totalTicketSupply);
            ticket.controllerMint(index[i], tickets[index[i]]);
            // update global deposit amount of the user
            pool.updateDeposit(tickets[index[i]], index[i]);
            globalDeposits[index[i]] = pool.getTotalDeposit(index[i]);
            totalGlobalDeposits = totalGlobalDeposits.add(globalDeposits[index[i]]);
        }
    }

    function withdrawFromYv() external {
        require(totalTicketSupply > 0, "Amount must be greater than 0");
        require(totalTicketSupply <= v.balanceOf(address(this)), "Insufficient balance");
        totalTicketSupply = 0;
        // balance of prizepool eth before withdrawal
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        // withdraw whole amount from vault
        v.withdraw(totalTicketSupply);
        // balance of prizepool eth after withdrawal
        uint256 afterBalance = IERC20(token).balanceOf(address(this));
        require(afterBalance > beforeBalance, "Withdrawal failed");
        totalFundsRetrieved = afterBalance - beforeBalance;
        totalInterest = totalFundsRetrieved - totalDeposits;

        // draw out winner
        winner = drawWinner();
    }

    function claim() external {
        // require(IERC20(token).transfer(msg.sender, afterBalance - beforeBalance), "Transfer failed");
        require(block.timestamp >= nextDrawTime, "Withdrawal time not started yet.");
        require(deposits[msg.sender] > 0, "You have not deposited any amount.");

        // burn tickets
        ticket.controllerBurn(msg.sender, tickets[msg.sender]);

        uint256 amount = calculateInterest(msg.sender);
        require(IERC20(token).transfer(msg.sender, amount.add(deposits[msg.sender])), "Transfer failed");

        totalDeposits = totalDeposits.sub(amount);
        deposits[msg.sender] = 0;
        tickets[msg.sender] = 0;

        require(IERC20(token).transfer(msg.sender, amount), "Transfer failed");
    }

    function drawWinner() private onlyOwner returns (uint256){
        require(block.timestamp >= nextDrawTime, "Not enough time elapsed");

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        winner = uint256(uint256(randomNumber) % count);
        return winner;
    }

    function calculateInterest(address _user) private view returns(uint256) {
        // check if user is winner
        if(index[winner]==_user){
            // you are a winner
            return (totalInterest.mul(awardShare)).div(100);
        }
        else{
            // you are not a winner
            uint256 interest = (totalInterest.mul(100-awardShare)).div(100);
            return ((interest).div(totalGlobalDeposits)).mul(globalDeposits[_user]);
        }
    }
}

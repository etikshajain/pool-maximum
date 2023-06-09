// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {VaultAPI} from "./BaseStrategy.sol";
import "./IPool.sol";
import "./Ticket.sol";

contract PrizePool is Ownable {
    using SafeMath for uint256;

    address public vaultAddress;
    IPool public pool;
    address public token; //token to be deposited into vault-eth address
    Ticket public ticket;

    // percentage of interest to be given to the winner and rest to be distributed among the rest
    uint256 public awardShare;

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

    VaultAPI public v;

    mapping(address => uint256) public globalDeposits;
    uint256 public totalGlobalDeposits;

    constructor(string memory name, string memory symbol, address _vaultAddress, address _token, address _poolAddress, uint256 _awardShare) {
        // deploy ticket 
        ticket = new Ticket(name, symbol, 18, address(this));
        pool = IPool(_poolAddress);
        nextDrawTime = block.timestamp + 2 hours;
        depositDeadline = block.timestamp + 1 hours;
        vaultAddress = _vaultAddress;
        token = _token;
        count = 0;
        awardShare = _awardShare;
        v = VaultAPI(vaultAddress);
    }

    // UI approval()
    function deposit() external payable returns (uint256){
        require(block.timestamp < depositDeadline, "Sorry the deposit deadline is passed, please wait till the next round starts.");
        // require(IERC20(token).transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // check if user has already deposited
        if(deposits[msg.sender] == 0){
            index[count] = msg.sender;
            count = count.add(1);
        }

        totalDeposits = totalDeposits.add(msg.value);
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        return deposits[msg.sender];
    }

    function depositToYv() onlyOwner external returns (uint256){
        require(block.timestamp > depositDeadline, "Deposition period is still going on!");
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
        
        uint256 curr_count = count;
        // mint tokens
        for(uint i = 0; i <= curr_count;) {

            tickets[index[i]] = (deposits[index[i]].div(totalDeposits)).mul(totalTicketSupply);
            ticket.controllerMint(index[i], tickets[index[i]]);
            // update global deposit amount of the user
            pool.updateUserDeposit(tickets[index[i]], index[i]);
            globalDeposits[index[i]] = pool.getUserTotalDeposit(index[i]);
            totalGlobalDeposits = totalGlobalDeposits.add(globalDeposits[index[i]]);

            unchecked{
                ++i;
            }
        }
        return totalTicketSupply;
    }

    function withdrawFromYv() onlyOwner external {
        // deadline check
        require(totalTicketSupply > 0, "Amount must be greater than 0");
        require(totalTicketSupply <= v.balanceOf(address(this)), "Insufficient balance");
        // balance of prizepool eth before withdrawal
        uint256 beforeBalance = IERC20(token).balanceOf(address(this));
        // withdraw whole amount from vault
        v.withdraw(totalTicketSupply);
        totalTicketSupply = 0;
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

    function checkwinner() public view returns(bool) {
        require(block.timestamp >= nextDrawTime, "Not enough time elapsed");
        return index[winner] == msg.sender;
    }

    function calculateInterest(address _user) public view returns(uint256) {
        require(block.timestamp >= nextDrawTime, "Not enough time elapsed");

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Test} from "../lib/forge-std/src/Test.sol";
import {console} from "../lib/forge-std/src/console.sol";
import {Pool} from "../src/Pool.sol";
import {PrizePool} from "../src/PrizePool.sol";
import {VaultAPI} from "../src/BaseStrategy.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import {ERC20Detailed} from "openzeppelin-contracts/contracts/token/ERC20/ERC20Detailed.sol";


contract PoolMaxiTester is Test {

    uint256 ethFork;
    
    Pool public pool_maxi;

    string public name = "Darpit";
    string public symbol = "Aww";
    address public yearnAddress = 0xe1237aA7f535b0CC33Fd973D66cBf830354D16c7;
    address token = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 awardShare = 80;

    address weth_token = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    VaultAPI v = VaultAPI(yearnAddress);


    function setUp() public{
        ethFork = vm.createFork("https://eth.llamarpc.com", 16963400);
        vm.selectFork(ethFork);
        pool_maxi = new Pool();
    }

    function testPoolAddress() public {
        console.log(address(pool_maxi));
    }

    // function testCreatePrizePool() public {
    //     PrizePool deployed_pp = pool_maxi.createPrizePool(name,symbol,yearnAddress,token,awardShare);
    //     console.log(address(deployed_pp));
    //     console.log("ticketERC20 is");
    //     console.log(address(deployed_pp.ticket()));
    //     console.log("The name is ");
    //     console.log(deployed_pp.v().name());
    // }

    // prizePool contract is an Ownable contract

    function testDepositFlow() public {
        PrizePool deployed_pp = pool_maxi.createPrizePool(name,symbol,yearnAddress,token,awardShare);
        address prizePool = address(deployed_pp);

        // defined two addresses
        address chandler = makeAddr("chandler");
        address joey = makeAddr("joey");
        address rich = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;

        // send weth
        vm.startPrank(rich);
        IERC20(weth_token).transfer(chandler, 10*10**18);
        IERC20(weth_token).transfer(joey, 20*10**18);
        vm.stopPrank();

        // Chandler Approves weth to PrizePool.sol
        vm.startPrank(chandler);
        IERC20(weth_token).approve(prizePool, type(uint256).max);
        vm.stopPrank();

        // joey calls deposit
        vm.startPrank(joey);
        vm.expectRevert();
        deployed_pp.deposit(10*10**18);
        vm.stopPrank();

        // Joey approves pp.sol
        vm.startPrank(joey);
        IERC20(weth_token).approve(prizePool, type(uint256).max);
        vm.stopPrank();

        // chandler calls deposit
        vm.startPrank(chandler);
        uint256 d1 = deployed_pp.deposit(1*10**18);
        vm.stopPrank();

        // joey calls deposit
        vm.startPrank(joey);
        uint256 d2 = deployed_pp.deposit(2*10**18);
        vm.stopPrank();

        // deposits and totalDeposits
        console.log("totalDeposits");
        console.log(IERC20(weth_token).balanceOf(prizePool));
        console.log(deployed_pp.totalDeposits());
        assertEq(IERC20(weth_token).balanceOf(prizePool), deployed_pp.totalDeposits());
        console.log("chandler");
        console.log(d1);
        console.log(deployed_pp.deposits(chandler));
        console.log("joey");
        console.log(d2);
        console.log(deployed_pp.deposits(joey));
        assertEq(d1, deployed_pp.deposits(chandler));
        assertEq(d2, deployed_pp.deposits(joey));
        console.log("count");
        console.log(deployed_pp.count());
        assertEq(2, deployed_pp.count());


        // deposit to yearn vault
        vm.startPrank(address(pool_maxi));
        console.log("yeanr balance before deposit");
        console.log(v.balanceOf(prizePool));

        // wait for 2 mins for deposition period to get over
        vm.makePersistent(address(deployed_pp));
        vm.makePersistent(address(pool_maxi));
        vm.makePersistent(address(chandler));
        vm.makePersistent(address(joey));
        vm.makePersistent(address(weth_token));
        vm.makePersistent(address(yearnAddress));
        vm.makePersistent(address(this));
        // vm.makePersistent(address(ERC20Detailed));
        vm.rollFork(16963412);
        vm.selectFork(ethFork);
        // checking deposits and total deposits persistency
        // deposits and totalDeposits
        console.log("chandler balance");
        console.log(IERC20(weth_token).balanceOf(chandler));
        console.log("joey balance");
        console.log(IERC20(weth_token).balanceOf(joey));
        console.log("totalDeposits");
        console.log(IERC20(weth_token).balanceOf(prizePool));
        console.log(deployed_pp.totalDeposits());
        assertEq(IERC20(weth_token).balanceOf(prizePool), deployed_pp.totalDeposits());
        console.log("chandler");
        console.log(d1);
        console.log(deployed_pp.deposits(chandler));
        console.log("joey");
        console.log(d2);
        console.log(deployed_pp.deposits(joey));
        assertEq(d1, deployed_pp.deposits(chandler));
        assertEq(d2, deployed_pp.deposits(joey));
        console.log("count");
        console.log(deployed_pp.count());
        assertEq(2, deployed_pp.count());

        console.log("withdrawal time");
        console.log(deployed_pp.nextDrawTime());
        console.log("timestamp");
        console.log(block.timestamp);
        console.log("deposit deadline");
        console.log(deployed_pp.depositDeadline());
        console.log("withdrawal time");
        console.log(deployed_pp.nextDrawTime());

        // deposit to Yv
        console.log("vault balance before dep");
        console.log(v.balanceOf(prizePool));
        uint256 tickets = deployed_pp.depositToYv();
        // tickets minted
        console.log("tickets");
        console.log(tickets);
        console.log("yeanr balance after deposit");        
        console.log(v.balanceOf(prizePool));
        // console.log("shares received from vault");
        // console.log(tickets);
        vm.stopPrank();
    }








}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../Util.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/the-rewarder/FlashLoanerPool.sol";
import {TheRewarderPool, RewardToken, AccountingToken} from "../../src/the-rewarder/TheRewarderPool.sol";

contract TheRewarderTest is Test{
    uint256 constant TOKENS_IN_LENDER_POOL = 1_000_000e18;
    Util util = new Util();
    address payable internal deployer;
    address payable internal alice;
    address payable internal bob;
    address payable internal charlie;
    address payable internal david;
    address payable internal player;

    TheRewarderPool rewarderPool;
    RewardToken rewardToken;
    AccountingToken accountingToken;
    DamnValuableToken liquidityToken;
    FlashLoanerPool flashLoanPool;

    function setUp() public{
        address payable[] memory users = util.createUsers(6);
        
        alice = users[0];
        bob = users[1];
        charlie = users[2];
        david = users[3];
        
        address payable[] memory someUsers = util.createUsers(2);
        deployer = someUsers[0];
        player = someUsers[1];

        liquidityToken = new DamnValuableToken();
        flashLoanPool = new FlashLoanerPool(address(liquidityToken));

        liquidityToken.transfer(address(flashLoanPool), TOKENS_IN_LENDER_POOL);

        rewarderPool = new TheRewarderPool(address(liquidityToken));
        rewardToken = RewardToken(rewarderPool.rewardToken());
        accountingToken = AccountingToken(rewarderPool.accountingToken());

        assertEq(accountingToken.owner(), address(rewarderPool));

        uint256 mintRole = accountingToken.MINTER_ROLE();
        uint256 snapShotRole = accountingToken.SNAPSHOT_ROLE();
        uint256 burnerRole = accountingToken.BURNER_ROLE();

        assertTrue(accountingToken.hasAllRoles(address(rewarderPool), mintRole | snapShotRole | burnerRole));

        uint256 depositAmount = 100e18;
        for (uint256 i=0;i < users.length; i++){
            liquidityToken.transfer(users[i], depositAmount);
            vm.startPrank(users[i]);
            liquidityToken.approve(address(rewarderPool), depositAmount);
            rewarderPool.deposit(depositAmount);
            assertEq(accountingToken.balanceOf(users[i]), depositAmount);
            vm.stopPrank();
        }
    }

    function testExploit() public{
        /** CODE YOUR SOLUTION HERE */

        validation();
    }

    function validation() public{

    }
}
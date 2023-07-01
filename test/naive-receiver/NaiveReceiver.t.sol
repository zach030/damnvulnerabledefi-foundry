// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../Util.sol";
import "../../src/naive-receiver/FlashLoanReceiver.sol";
import "../../src/naive-receiver/NaiveReceiverLenderPool.sol";
import "./Attacker.sol";

contract NaiveReceiverTest is Test{
    uint256 constant ETHER_IN_POOL = 10_000e18;
    uint256 constant ETHER_IN_RECEIVER = 10e18;
    Util internal util;
    
    address payable deployer;
    address payable user;
    address payable player;

    NaiveReceiverLenderPool public pool;
    FlashLoanReceiver public receiver;

    function setUp() public{
        util = new Util();
        address payable[] memory users = util.createUsers(3);
        deployer = users[0];
        user = users[1];
        player = users[2];

        pool = new NaiveReceiverLenderPool();
        vm.deal(address(pool), ETHER_IN_POOL);
        address eth = pool.ETH();
        assertEq(address(pool).balance, ETHER_IN_POOL);
        assertEq(pool.maxFlashLoan(eth), ETHER_IN_POOL);
        assertEq(pool.flashFee(eth,0), 1e18);

        receiver = new FlashLoanReceiver(address(pool));
        vm.deal(address(receiver), ETHER_IN_RECEIVER);
        
        vm.expectRevert();
        receiver.onFlashLoan(address(deployer), eth, ETHER_IN_RECEIVER, 1e18, "0x");

        assertEq(address(receiver).balance, ETHER_IN_RECEIVER);
    }

    function testExploit() public{
        /** CODE YOUR SOLUTION HERE */
        new Attacker(payable(pool), payable(receiver));
        /* */
        validation();
    }

    function validation() internal{
       assertEq(address(receiver).balance, 0 );
       assertEq(address(pool).balance, ETHER_IN_POOL + ETHER_IN_RECEIVER);
    }
}
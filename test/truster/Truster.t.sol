// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../Util.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/truster/TrusterLenderPool.sol";
import "./Attacker.sol";

contract TrusterTest is Test{
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;
    Util util;
    address payable internal deployer;
    address payable internal player;
    DamnValuableToken token;
    TrusterLenderPool pool;

    function setUp() public{
        util = new Util();
        address payable[] memory users = util.createUsers(2);
        deployer = users[0];
        player = users[1];

        vm.startPrank(deployer);
        token = new DamnValuableToken();
        pool = new TrusterLenderPool(token);
        
        token.transfer(address(pool), TOKENS_IN_POOL);
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(address(player)), 0);
        vm.stopPrank();
    }

    function testExploit() public{
        /** CODE YOUR SOLUTION HERE */
        /* */
        vm.startPrank(player);
        console.log("start attack");
        new Attacker(address(pool), address(token));
        vm.stopPrank();
        validation();
    }

    function validation() internal{
        assertEq(token.balanceOf(address(player)), TOKENS_IN_POOL);
        assertEq(token.balanceOf(address(pool)), 0);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../Util.sol";
import "../../src/side-entrance/SideEntranceLenderPool.sol";
import "./Attacker.sol";

contract SideEntranceTest is Test{
    uint256 internal constant ETHER_IN_POOL = 1_000e18;
    uint256 internal constant PLAYER_INITIAL_ETH_BALANCE = 1e18;
    Util util = new Util();
    address payable deployer;
    address payable player;
    SideEntranceLenderPool pool;

    function setUp() public {
        address payable[] memory users = util.createUsers(2);
        deployer = users[0];
        player = users[1];

        pool = new SideEntranceLenderPool();
        pool.deposit{value: ETHER_IN_POOL}();
        assertEq(address(pool).balance, ETHER_IN_POOL);

        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(address(player).balance, PLAYER_INITIAL_ETH_BALANCE);
    }

    function testExploit() public {
        /** CODE YOUR SOLUTION HERE */
        /* */
        vm.startPrank(player);
        Attacker attacker = new Attacker(address(pool));
        attacker.attack(ETHER_IN_POOL);
        attacker.withdraw();
        vm.stopPrank();
        validation();
    }

    function validation() public {
        assertEq(address(pool).balance, 0);
        assertGt(address(player).balance, ETHER_IN_POOL);
    }
}
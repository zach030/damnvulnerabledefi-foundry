// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../Util.sol";
import "../../src/DamnValuableToken.sol";
import "../../src/puppet/PuppetPool.sol";

interface UniswapV1Exchange {
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline)
        external
        payable
        returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenToEthSwapInput(uint256 tokens_sold, uint256 min_eth, uint256 deadline) external returns (uint256);

    function getTokenToEthInputPrice(uint256 tokens_sold) external view returns (uint256);
}

interface UniswapV1Factory {
    function initializeFactory(address template) external;

    function createExchange(address token) external returns (address);
}

contract PuppetTest is Test{
    Util util = new Util();

    address deployer = makeAddr('deployer');
    address player = makeAddr('player');

    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 10e18;
    uint256 constant UNISWAP_INITIAL_ETH_RESERVE = 10e18;

    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 1000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 25e18;

    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 100_000e18;

    DamnValuableToken token;
    UniswapV1Exchange internal uniswapV1ExchangeTemplate;
    UniswapV1Exchange internal uniswapExchange;
    UniswapV1Factory internal uniswapV1Factory;

    PuppetPool lendingPool;

    function setUp() public{
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
        
        token = new DamnValuableToken();

        uniswapV1Factory = UniswapV1Factory(deployCode("./src/build-uniswap/v1/UniswapV1Factory.json"));
        uniswapV1ExchangeTemplate = UniswapV1Exchange(deployCode("./src/build-uniswap/v1/UniswapV1Exchange.json"));

        uniswapV1Factory.initializeFactory(address(uniswapV1ExchangeTemplate));
        
        uniswapExchange = UniswapV1Exchange(uniswapV1Factory.createExchange(address(token)));

        lendingPool = new PuppetPool(address(token), address(uniswapExchange));

        token.approve(address(uniswapExchange), UNISWAP_INITIAL_TOKEN_RESERVE);

        uniswapExchange.addLiquidity{value: UNISWAP_INITIAL_ETH_RESERVE}(0, UNISWAP_INITIAL_TOKEN_RESERVE, block.timestamp*2);

        assertEq(
            uniswapExchange.getTokenToEthInputPrice(1e18), 
            calculateTokenToEthInputPrice(1e18, UNISWAP_INITIAL_TOKEN_RESERVE, UNISWAP_INITIAL_ETH_RESERVE)
            );

        token.transfer(address(player), PLAYER_INITIAL_TOKEN_BALANCE);
        token.transfer(address(lendingPool), POOL_INITIAL_TOKEN_BALANCE);

        assertEq(lendingPool.calculateDepositRequired(1e18), 2e18);
        assertEq(lendingPool.calculateDepositRequired(POOL_INITIAL_TOKEN_BALANCE), 2*POOL_INITIAL_TOKEN_BALANCE);
    }

    function testExploit() public {
        /*Code your solution here*/

        validation();
    }


    function validation() public{
        assertEq(vm.getNonce(player), 1);
        assertEq(token.balanceOf(address(lendingPool)), 0);
        assertGt(token.balanceOf(address(player)), POOL_INITIAL_TOKEN_BALANCE);
    }
    
    // Calculates how much ETH (in wei) Uniswap will pay for the given amount of tokens
    function calculateTokenToEthInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve)
        pure
        internal
        returns (uint256)
    {
        uint256 input_amount_with_fee = input_amount * 997;
        uint256 numerator = input_amount_with_fee * output_reserve;
        uint256 denominator = (input_reserve * 1000) + input_amount_with_fee;
        return numerator / denominator;
    }
}
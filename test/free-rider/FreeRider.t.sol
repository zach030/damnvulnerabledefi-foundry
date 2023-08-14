// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../Util.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {DamnValuableNFT} from "../../src/DamnValuableNFT.sol";
import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "../../src/uniswap/Interface.sol";
import {FreeRiderNFTMarketplace} from "../../src/free-rider/FreeRiderNFTMarketplace.sol";
import {FreeRiderRecovery} from "../../src/free-rider/FreeRiderRecovery.sol";

contract FreeRiderTest is Test{
    uint256 internal constant NFT_PRICE = 15e18;
    uint256 internal constant AMOUNT_OF_NFTS = 6;
    uint256 internal constant MARKETPLACE_INITIAL_ETH_BALANCE = 90e18;
    uint256 internal constant PLAYER_INITIAL_ETH_BALANCE = 1e17;
    uint256 internal constant BOUNTY = 45e18;
    // Initial reserves for the Uniswap v2 pool
    uint256 internal constant UNISWAP_INITIAL_TOKEN_RESERVE = 15000e18;
    uint256 internal constant UNISWAP_INITIAL_WETH_RESERVE = 9000e18;

    address deployer;
    address player;
    address devs;
    WETH weth;
    DamnValuableToken token;
    DamnValuableNFT nft;
    IUniswapV2Pair internal uniswapV2Pair;
    IUniswapV2Factory internal uniswapV2Factory;
    IUniswapV2Router02 internal uniswapV2Router;

    FreeRiderNFTMarketplace marketplace;
    FreeRiderRecovery recovery;

    function setUp() public {
        player = makeAddr('player');
        deployer = makeAddr('deployer');
        devs = makeAddr('devs');
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);
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
            address(token),                 // address token,
            UNISWAP_INITIAL_TOKEN_RESERVE,  // uint256 amountTokenDesired,
            0,                              // uint256 amountTokenMin,
            0,                              // uint256 amountETHMin,
            address(deployer),              // address to,
            block.timestamp*2               // uint256 deadline
        );

        marketplace = new FreeRiderNFTMarketplace{value: MARKETPLACE_INITIAL_ETH_BALANCE}(AMOUNT_OF_NFTS);
        nft = DamnValuableNFT(marketplace.token());

        for (uint256 i=0; i < AMOUNT_OF_NFTS; i++){
            assertEq(nft.ownerOf(i), address(deployer));
        }
        nft.setApprovalForAll(address(marketplace), true);
        
        uint256[] memory tokenIds = new uint256[](6);
        uint256[] memory prices = new uint256[](6);
        marketplace.offerMany(tokenIds, prices);
        assertEq(marketplace.offersCount(), 6);

        recovery = new FreeRiderRecovery(address(player), address(nft));
    }

    function testExploit() public{

        validation();
    }

    function validation() public {
        vm.startPrank(devs);
        for (uint256 i=0; i < AMOUNT_OF_NFTS; i++){
            nft.transferFrom(address(recovery), address(devs), i);
        }
        assertEq(marketplace.offersCount(), 0);
        assertLe(address(marketplace).balance, MARKETPLACE_INITIAL_ETH_BALANCE);

        assertGt(address(player).balance, BOUNTY);
        assertEq(address(devs).balance, 0);
    }
}
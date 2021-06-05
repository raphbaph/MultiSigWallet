pragma solidity 0.7.5;

import "./Ownable.sol";

contract Destroyable is Ownable{
    
    function killswitch() public onlyOwner {
        selfdestruct(owner);
    }
}

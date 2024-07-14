// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";

contract MockToken is ERC20, Owned {
    constructor(string memory name, string memory symbol, uint8 decimals, address owner)
        ERC20(name, symbol, decimals)
        Owned(owner)
    {
        _mint(owner, 20000 ether);
    }

    function mint(address target, uint256 amount) public onlyOwner {
        _mint(target, amount);
    }
}

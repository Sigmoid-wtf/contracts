// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "solmate/tokens/ERC20.sol";
import "solmate/auth/Owned.sol";

contract StakedToken is ERC20, Owned {
    event BridgeIncome(address indexed receiver, uint256 amount);
    event BridgeRequested(address indexed sender, string sigmoidAddress, uint256 amount);

    constructor(string memory name, string memory symbol, uint8 decimals, address owner)
        ERC20(name, symbol, decimals)
        Owned(owner)
    {}

    function mint(address target, uint256 amount) public onlyOwner {
        _mint(target, amount);
        emit BridgeIncome(target, amount);
    }

    function bridge(string memory sigmoidAddress, uint256 amount) public {
        require(amount <= balanceOf[msg.sender], "Not enough tokens");
        _burn(msg.sender, amount);
        emit BridgeRequested(msg.sender, sigmoidAddress, amount);
    }
}

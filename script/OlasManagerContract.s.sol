// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/OlasManagerContract.sol";
import {MockToken} from "./mock/MockToken.sol";

contract OlasManagerScript is Script {
    function setUp() public {}

    function run() public {
        address owner = address(0x8137d2ad383b642Aa0E3E50f0cFeAb24dd7Ab8dE);
        address treasury = address(0xCeF9eBDcDA12991bDE0086DfB0d5EbD60E9a8002);
        vm.startBroadcast();
        MockToken mockToken = new MockToken("MockToken", "MCK", 18, owner);
        console2.log("mockToken", address(mockToken));
        OlasManager olasManager = new OlasManager(address(mockToken), owner, owner, treasury, treasury, 100 ether);
        console2.log("OlasManager", address(olasManager));
        vm.stopBroadcast();
    }
}

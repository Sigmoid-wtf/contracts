// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/StakedToken.sol";

contract StakedTokenScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        StakedToken stakedToken = new StakedToken("sigmaTAO", "sigTAO", 9, address(0xCeF9eBDcDA12991bDE0086DfB0d5EbD60E9a8002));
        console2.log("StakedToken", address(stakedToken));
        vm.stopBroadcast();
    }
}

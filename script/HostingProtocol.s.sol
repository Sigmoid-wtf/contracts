// SPDX-Lipragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/HostingProtocol.sol";
import "./mock/RoflanToken.sol";

contract HostingProtocolScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        RoflanToken roflanToken = new RoflanToken("RoflanToken", "RFL", 18, address(0x58a1ea996831599D2234a801c3B192Dd5e800d88));
        console2.log("RoflanToken", address(roflanToken));
        HostingProtocol hostingProtocol = new HostingProtocol(address(0x58a1ea996831599D2234a801c3B192Dd5e800d88), address(0x58a1ea996831599D2234a801c3B192Dd5e800d88));
        console2.log("HostingProtocol", address(hostingProtocol));
        vm.stopBroadcast();
    }
}
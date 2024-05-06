// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {StakedToken} from "../src/StakedToken.sol";

contract StakedTokenTest is Test {
    StakedToken public stakedToken;

    function setUp() public {
        stakedToken = new StakedToken("sigmaTAO", "sigTAO", 18, address(this));
    }

    function testMintSuccess() public {
        stakedToken.mint(address(this), 1 ether);
        assertEq(stakedToken.balanceOf(address(this)), 1 ether);
    }

    function testBridgeSuccess() public {
        stakedToken.mint(address(this), 2 ether);
        stakedToken.bridge("sigmoidAddress", 1 ether);
        assertEq(stakedToken.balanceOf(address(this)), 1 ether);
    }
}

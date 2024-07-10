// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {OlasManager} from "../src/OlasManagerContract.sol";

contract OlasManagerTest is Test {
    OlasManager public olasManager;

    function setUp() public {
        olasManager = new OlasManager(
            address(0x0001A500A6B18995B03f44bb040A5fFc28E45CB0),
            address(this),
            address(uint160(uint256(keccak256("relayer")))),
            address(uint160(uint256(keccak256("treasury")))),
            address(uint160(uint256(keccak256("emergency reasury")))),
            address(uint160(uint256(keccak256("hosting protocol")))),
            20
        );
    }

    function testMintSuccess() public {
        address newTreasury = address(uint160(uint256(keccak256("treasury"))));
        olasManager.setTreasury(newTreasury);
        assertEq(olasManager.treasury(), newTreasury);
    }
}

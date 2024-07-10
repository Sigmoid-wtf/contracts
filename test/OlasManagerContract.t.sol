// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Test, console} from "forge-std/Test.sol";
import {OlasManager} from "../src/OlasManagerContract.sol";
import {MockToken} from "./mock/MockToken.sol";

contract OlasManagerTest is Test {
    MockToken public olasToken;
    OlasManager public olasManager;

    function setUp() public {
        olasToken = new MockToken("Autonolas", "OLAS");

        olasManager = new OlasManager(
            address(olasToken),
            address(this),
            address(uint160(uint256(keccak256("relayer")))),
            address(uint160(uint256(keccak256("treasury")))),
            address(uint160(uint256(keccak256("emergency reasury")))),
            address(uint160(uint256(keccak256("hosting protocol")))),
            10 ether
        );
        olasManager.makePrivate();

        address[] memory addresses = new address[](1);
        addresses[0] = address(this);
        olasManager.addStakersToAllowList(addresses);
    }

    function test_SetTreasury() public {
        address newTreasury = address(uint160(uint256(keccak256("treasury"))));
        olasManager.setTreasury(newTreasury);
        assertEq(olasManager.treasury(), newTreasury);
    }

    function test_AddDepositorsToAllowList() public {
        address[] memory addresses = new address[](1);
        addresses[0] = address(uint160(uint256(keccak256("new staker"))));
        olasManager.addStakersToAllowList(addresses);
        address[] memory stakers = olasManager.stakersAllowList();
        assertEq(stakers.length, 2);
        assertEq(address(this), stakers[0]);
        assertEq(addresses[0], stakers[1]);
    }

    function test_StakeTokenAsVerifiedStaker() public {
        olasToken.approve(address(olasManager), 2 ether);
        olasManager.stakeToken(2 ether);
        assertEq(olasManager.balanceOf(address(this)), 2 ether);
    }

    function testFail_StakeTokenAsNotVerifiedStaker() public {
        vm.prank(address(0));
        olasToken.approve(address(olasManager), 2 ether);
        olasManager.stakeToken(2 ether);
    }

    function testFail_StakeTokenOverMaxThreshold() public {
        olasToken.approve(address(olasManager), 20 ether);
        olasManager.stakeToken(20 ether);
    }
}

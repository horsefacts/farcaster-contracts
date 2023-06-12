// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../TestConstants.sol";

import {FixedPriceStorage} from "../../src/FixedPriceStorage.sol";
import {StorageTestSuite} from "./StorageTestSuite.sol";

/* solhint-disable state-visibility */

contract VRGDAStorageTest is StorageTestSuite {
    address mallory = makeAddr("mallory");

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    function testOwner() public {
        assertEq(vrgdaStorage.owner(), owner);
    }

    function testEpochEnd() public {
        assertEq(vrgdaStorage.epochEnd(), block.timestamp + 365 days);
    }

    function testPurchase() public {
        assertEq(vrgdaStorage.purchasePrice(), 0.002500502566798067 ether);
        for (uint256 i; i < 1_000; i++) {
            vrgdaStorage.purchase{value: vrgdaStorage.purchasePrice()}(1);
        }
        assertEq(vrgdaStorage.unitsSold(), 1_000);
        assertEq(vrgdaStorage.purchasePrice(), 0.003057196506449139 ether);
        for (uint256 i; i < 9_000; i++) {
            vrgdaStorage.purchase{value: vrgdaStorage.purchasePrice()}(1);
        }
        assertEq(vrgdaStorage.unitsSold(), 10_000);
        assertEq(vrgdaStorage.purchasePrice(), 0.018664511222719706 ether);
        for (uint256 i; i < 90_000; i++) {
            vrgdaStorage.purchase{value: vrgdaStorage.purchasePrice()}(1);
        }
        assertEq(vrgdaStorage.unitsSold(), 100_000);
        assertEq(vrgdaStorage.purchasePrice(), 1435174.55315603082139716 ether);
    }

    function testPurchaseSchedule() public {
        assertEq(vrgdaStorage.purchasePrice(), 0.002500502566798067 ether);
        for (uint256 i; i < 1_000; i++) {
            vrgdaStorage.purchase{value: vrgdaStorage.purchasePrice()}(1);
        }
        assertEq(vrgdaStorage.unitsSold(), 1_000);
        assertEq(vrgdaStorage.purchasePrice(), 0.003057196506449139 ether);
        vm.warp(block.timestamp + 1 days);
        for (uint256 i; i < 100; i++) {
            vrgdaStorage.purchase{value: vrgdaStorage.purchasePrice()}(1);
        }
        assertEq(vrgdaStorage.unitsSold(), 1_100);
        assertEq(vrgdaStorage.purchasePrice(), 0.003088077285786052 ether);
        vm.warp(block.timestamp + 1 days);
        for (uint256 i; i < 100; i++) {
            vrgdaStorage.purchase{value: vrgdaStorage.purchasePrice()}(1);
        }
        assertEq(vrgdaStorage.unitsSold(), 1_200);
        assertEq(vrgdaStorage.purchasePrice(), 0.003119270006059485 ether);

        assertEq(vrgdaStorage.getTargetSaleTime(1000e18), 19.99998666667068e18);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../TestConstants.sol";

import {FixedPriceStorage} from "../../src/FixedPriceStorage.sol";
import {StorageTestSuite} from "./StorageTestSuite.sol";

/* solhint-disable state-visibility */

contract GDAStorageTest is StorageTestSuite {
    address mallory = makeAddr("mallory");

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    function testOwner() public {
        assertEq(gdaStorage.owner(), owner);
    }

    function testEpochEnd() public {
        assertEq(gdaStorage.epochEnd(), block.timestamp + 365 days);
    }

    function testPurchase() public {
        uint256 start = block.timestamp;

        vm.warp(start + 2.675 hours);
        assertEq(gdaStorage.purchasePrice(1), 0.002370438021902501 ether);
        assertEq(gdaStorage.purchasePrice(2), 0.004749424999571362 ether);
        assertEq(gdaStorage.purchasePrice(10), 0.02409280648519088 ether);
        assertEq(gdaStorage.purchasePrice(100), 0.284814640194665502 ether);

        gdaStorage.purchase{value: gdaStorage.purchasePrice(10)}(1, 10);
        assertEq(gdaStorage.purchasePrice(1), 0.002457328434149608 ether);
        assertEq(gdaStorage.purchasePrice(2), 0.004923519193275805 ether);
        assertEq(gdaStorage.purchasePrice(10), 0.024975948701247569 ether);
        assertEq(gdaStorage.purchasePrice(100), 0.295254761924008835 ether);
    }

    receive() external payable {}
}

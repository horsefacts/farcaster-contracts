// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "../TestConstants.sol";

import {Storage} from "../../src/Storage.sol";
import {StorageTestSuite} from "./StorageTestSuite.sol";

/* solhint-disable state-visibility */

contract StorageTest is StorageTestSuite {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                             REGISTER TESTS
    //////////////////////////////////////////////////////////////*/

    function testOwner() public {
        assertEq(fcStorage.owner(), owner);
    }

    function testEpochEnd() public {
        assertEq(fcStorage.epochEnd(), block.timestamp + 365 days);
    }

    function testFuzzPurchaseEmitsEvent(address msgSender, uint256 id, uint256 units) public {
        vm.startPrank(msgSender);
        vm.expectEmit(true, true, false, true);
        emit Purchase(msgSender, id, units);
        fcStorage.purchase(id, units);
        vm.stopPrank();
    }

    function testFuzzPurchaseRevertsAfterDeadline(address msgSender, uint256 id, uint256 units) public {
        vm.warp(fcStorage.epochEnd() + 1);
        vm.startPrank(msgSender);
        vm.expectRevert(Storage.EpochOver.selector);
        fcStorage.purchase(id, units);
        vm.stopPrank();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "../TestConstants.sol";

import {FixedPriceStorage} from "../../src/FixedPriceStorage.sol";
import {StorageTestSuite} from "./StorageTestSuite.sol";

/* solhint-disable state-visibility */

contract FixedPriceStorageTest is StorageTestSuite {
    address mallory = makeAddr("mallory");

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    function testOwner() public {
        assertEq(fcStorage.owner(), owner);
    }

    function testPriceFeed() public {
        assertEq(address(fcStorage.priceFeed()), address(priceFeed));
    }

    function testEpochEnd() public {
        assertEq(fcStorage.epochEnd(), block.timestamp + 365 days);
    }

    function testFuzzPurchaseEmitsEvent(address msgSender, uint256 id, uint200 units) public {
        uint256 price = fcStorage.unitPrice() * units;
        vm.deal(msgSender, price);
        vm.startPrank(msgSender);
        vm.expectEmit(true, true, false, true);
        emit Purchase(msgSender, id, units);
        fcStorage.purchase{value: price}(id, units);
        vm.stopPrank();
    }

    function testFuzzPurchaseRevertsAfterDeadline(address msgSender, uint256 id, uint256 units) public {
        vm.warp(fcStorage.epochEnd() + 1);
        vm.startPrank(msgSender);
        vm.expectRevert(FixedPriceStorage.EpochOver.selector);
        fcStorage.purchase(id, units);
        vm.stopPrank();
    }

    function testUnitPrice() public {
        assertEq(fcStorage.unitPrice(), 0.0025 ether);
    }

    function testFuzzWithdrawal(address msgSender, uint256 id, uint200 units) public {
        uint256 balanceBefore = address(owner).balance;

        uint256 price = fcStorage.unitPrice() * units;
        vm.deal(msgSender, price);
        vm.startPrank(msgSender);
        vm.expectEmit(true, true, false, true);
        emit Purchase(msgSender, id, units);
        fcStorage.purchase{value: price}(id, units);

        vm.prank(owner);
        fcStorage.withdraw(owner);

        uint256 balanceAfter = address(owner).balance;
        uint256 balanceChange = balanceAfter - balanceBefore;

        assertEq(balanceChange, price);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(mallory);
        vm.expectRevert("Ownable: caller is not the owner");
        fcStorage.withdraw(owner);
    }

    receive() external payable {}
}

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
        assertEq(fpStorage.owner(), owner);
    }

    function testPriceFeed() public {
        assertEq(address(fpStorage.priceFeed()), address(priceFeed));
    }

    function testEpochEnd() public {
        assertEq(fpStorage.epochEnd(), block.timestamp + 365 days);
    }

    function testFuzzPurchaseEmitsEvent(address msgSender, uint256 id, uint200 units) public {
        uint256 price = fpStorage.unitPrice() * units;
        vm.deal(msgSender, price);
        vm.startPrank(msgSender);
        vm.expectEmit(true, true, false, true);
        emit Purchase(msgSender, id, units);
        fpStorage.purchase{value: price}(id, units);
        vm.stopPrank();
    }

    function testFuzzPurchaseRevertsAfterDeadline(address msgSender, uint256 id, uint256 units) public {
        vm.warp(fpStorage.epochEnd() + 1);
        vm.startPrank(msgSender);
        vm.expectRevert(FixedPriceStorage.EpochOver.selector);
        fpStorage.purchase(id, units);
        vm.stopPrank();
    }

    function testUnitPrice() public {
        assertEq(fpStorage.unitPrice(), 0.0025 ether);
    }

    function testFuzzWithdrawal(address msgSender, uint256 id, uint200 units) public {
        uint256 balanceBefore = address(owner).balance;

        uint256 price = fpStorage.unitPrice() * units;
        vm.deal(msgSender, price);
        vm.startPrank(msgSender);
        vm.expectEmit(true, true, false, true);
        emit Purchase(msgSender, id, units);
        fpStorage.purchase{value: price}(id, units);

        vm.prank(owner);
        fpStorage.withdraw(owner);

        uint256 balanceAfter = address(owner).balance;
        uint256 balanceChange = balanceAfter - balanceBefore;

        assertEq(balanceChange, price);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.prank(mallory);
        vm.expectRevert("Ownable: caller is not the owner");
        fpStorage.withdraw(owner);
    }

    receive() external payable {}
}

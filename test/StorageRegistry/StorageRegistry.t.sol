// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

import "../TestConstants.sol";

import {StorageRegistry} from "../../src/StorageRegistry.sol";
import {StorageRegistryTestSuite} from "./StorageRegistryTestSuite.sol";
import {MockPriceFeed, MockUptimeFeed} from "../Utils.sol";

/* solhint-disable state-visibility */

contract StorageRegistryTest is StorageRegistryTestSuite {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Rent(address indexed buyer, uint256 indexed id, uint256 units);
    event SetPrice(uint256 oldPrice, uint256 newPrice);
    event SetMaxUnits(uint256 oldMax, uint256 newMax);
    event SetRentalPeriodEnd(uint256 oldTimestamp, uint256 newTimestamp);
    event Withdraw(address indexed to, uint256 amount);

    function testOwnerDefault() public {
        assertEq(fcStorage.owner(), owner);
    }

    function testPriceFeedDefault() public {
        assertEq(address(fcStorage.priceFeed()), address(priceFeed));
    }

    function testUptimeFeedDefault() public {
        assertEq(address(fcStorage.uptimeFeed()), address(uptimeFeed));
    }

    function testRentalPeriodEndDefault() public {
        assertEq(fcStorage.rentalPeriodEnd(), 1 + INITIAL_RENTAL_PERIOD);
    }

    function testUsdUnitPriceDefault() public {
        assertEq(fcStorage.usdUnitPrice(), INITIAL_USD_UNIT_PRICE);
    }

    function testMaxUnitsDefault() public {
        assertEq(fcStorage.maxUnits(), INITIAL_MAX_UNITS);
    }

    function testFuzzRent(address msgSender, uint256 id, uint200 units) public {
        _rentStorage(msgSender, id, units);
    }

    function testFuzzRentRevertsAfterDeadline(address msgSender, uint256 id, uint256 units) public {
        vm.warp(fcStorage.rentalPeriodEnd() + 1);

        vm.expectRevert(StorageRegistry.RentalPeriodHasEnded.selector);
        vm.prank(msgSender);
        fcStorage.rent(id, units);
    }

    function testFuzzRentRevertsInsufficientPayment(
        address msgSender,
        uint256 id,
        uint256 units,
        uint256 delta
    ) public {
        units = bound(units, 1, fcStorage.maxUnits());
        uint256 price = fcStorage.price(units);
        uint256 value = price - bound(delta, 1, price);
        vm.deal(msgSender, value);

        vm.expectRevert(StorageRegistry.InvalidPayment.selector);
        vm.prank(msgSender);
        fcStorage.rent{value: value}(id, units);
    }

    function testFuzzRentRevertsExcessPayment(address msgSender, uint256 id, uint256 units, uint256 delta) public {
        // Buy between 1 and maxUnits units.
        units = bound(units, 1, fcStorage.maxUnits());

        // Add a fuzzed amount to the price.
        uint256 price = fcStorage.price(units);
        uint256 value = price + bound(delta, 1, type(uint256).max - price);
        vm.deal(msgSender, value);

        vm.expectRevert(StorageRegistry.InvalidPayment.selector);
        vm.prank(msgSender);
        fcStorage.rent{value: value}(id, units);
    }

    function testFuzzRentRevertsExceedsCapacity(address msgSender, uint256 id, uint256 units) public {
        // Buy all the available units.
        uint256 maxUnits = fcStorage.maxUnits();
        uint256 maxUnitsPrice = fcStorage.price(maxUnits);
        vm.deal(address(this), maxUnitsPrice);
        fcStorage.rent{value: maxUnitsPrice}(0, maxUnits);

        // Attempt to buy a fuzzed amount units.
        units = bound(units, 1, fcStorage.maxUnits());
        uint256 price = fcStorage.unitPrice() * units;
        vm.deal(msgSender, price);

        vm.expectRevert(StorageRegistry.ExceedsCapacity.selector);
        vm.prank(msgSender);
        fcStorage.rent{value: price}(id, units);
    }

    function testFuzzInitialPrice(uint128 quantity) public {
        assertEq(fcStorage.price(quantity), INITIAL_PRICE_IN_ETH * quantity);
    }

    function testInitialUnitPrice() public {
        assertEq(fcStorage.unitPrice(), INITIAL_PRICE_IN_ETH);
    }

    function testFuzzBatchRent(address msgSender, uint256[] calldata _ids, uint16[] calldata _units) public {
        // Throw away runs with empty arrays.
        vm.assume(_ids.length > 0);
        vm.assume(_units.length > 0);

        // Set a high max capacity to avoid overflow.
        fcStorage.setMaxUnits(uint256(256) * type(uint16).max);

        // Fuzzed dynamic arrays have a fuzzed length up to 256 elements.
        // Truncate the longer one so their lengths match.
        uint256 length = _ids.length <= _units.length ? _ids.length : _units.length;
        uint256[] memory ids = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            ids[i] = _ids[i];
        }
        uint256[] memory units = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            units[i] = _units[i];
        }
        _batchRentStorage(msgSender, ids, units);
    }

    function testFuzzBatchRentRevertsAfterDeadline(
        address msgSender,
        uint256[] calldata _ids,
        uint16[] calldata _units
    ) public {
        fcStorage.setMaxUnits(uint256(256) * type(uint16).max);
        uint256 length = _ids.length <= _units.length ? _ids.length : _units.length;
        uint256[] memory ids = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            ids[i] = _ids[i];
        }
        uint256[] memory units = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            units[i] = _units[i];
        }
        vm.warp(fcStorage.rentalPeriodEnd() + 1);
        uint256 totalUnits;
        for (uint256 i; i < units.length; ++i) {
            totalUnits += units[i];
        }
        uint256 totalCost = fcStorage.price(totalUnits);
        vm.assume(totalUnits <= fcStorage.maxUnits() - fcStorage.rentedUnits());
        vm.deal(msgSender, totalCost);
        vm.prank(msgSender);
        vm.expectRevert(StorageRegistry.RentalPeriodHasEnded.selector);
        fcStorage.batchRent{value: totalCost}(ids, units);
    }

    function testFuzzBatchRentRevertsEmptyArray(
        address msgSender,
        uint256[] memory ids,
        uint256[] memory units,
        bool emptyIds
    ) public {
        // Switch on emptyIds and set one array to length zero.
        if (emptyIds) {
            ids = new uint256[](0);
        } else {
            units = new uint256[](0);
        }

        vm.prank(msgSender);
        vm.expectRevert(StorageRegistry.InvalidBatchInput.selector);
        fcStorage.batchRent{value: 0}(ids, units);
    }

    function testFuzzBatchRentRevertsMismatchedArrayLength(
        address msgSender,
        uint256[] calldata _ids,
        uint16[] calldata _units
    ) public {
        fcStorage.setMaxUnits(uint256(256) * type(uint16).max);

        uint256 length = _ids.length <= _units.length ? _ids.length : _units.length;
        uint256[] memory ids = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            ids[i] = _ids[i];
        }

        // Add an extra element to the units array
        uint256[] memory units = new uint256[](length + 1);
        for (uint256 i; i < length; ++i) {
            units[i] = _units[i];
        }

        uint256 totalUnits;
        for (uint256 i; i < units.length; ++i) {
            totalUnits += units[i];
        }
        uint256 totalCost = fcStorage.price(totalUnits);
        vm.assume(totalUnits <= fcStorage.maxUnits() - fcStorage.rentedUnits());
        vm.deal(msgSender, totalCost);

        vm.prank(msgSender);
        vm.expectRevert(StorageRegistry.InvalidBatchInput.selector);
        fcStorage.batchRent{value: totalCost}(ids, units);
    }

    function testFuzzBatchRentRevertsInsufficientPayment(
        address msgSender,
        uint256[] calldata _ids,
        uint16[] calldata _units,
        uint256 delta
    ) public {
        // Throw away runs with empty arrays.
        vm.assume(_ids.length > 0);
        vm.assume(_units.length > 0);

        // Set a high max capacity to avoid overflow.
        fcStorage.setMaxUnits(uint256(256) * type(uint16).max);
        uint256 length = _ids.length <= _units.length ? _ids.length : _units.length;
        uint256[] memory ids = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            ids[i] = _ids[i];
        }
        uint256[] memory units = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            units[i] = _units[i];
        }

        // Calculate the number of total units purchased
        uint256 totalUnits;
        for (uint256 i; i < units.length; ++i) {
            totalUnits += units[i];
        }

        // Throw away the run if the total units is zero
        vm.assume(totalUnits > 0);

        // Throw away runs where the total units exceed max capacity
        uint256 totalCost = fcStorage.price(totalUnits);
        uint256 value = totalCost - bound(delta, 1, totalCost);
        vm.assume(totalUnits <= fcStorage.maxUnits() - fcStorage.rentedUnits());
        vm.deal(msgSender, totalCost);

        vm.prank(msgSender);
        vm.expectRevert(StorageRegistry.InvalidPayment.selector);
        fcStorage.batchRent{value: value}(ids, units);
    }

    function testFuzzBatchRentRevertsExcessPayment(
        address msgSender,
        uint256[] calldata _ids,
        uint16[] calldata _units,
        uint256 delta
    ) public {
        // Throw away runs with empty arrays.
        vm.assume(_ids.length > 0);
        vm.assume(_units.length > 0);

        // Set a high max capacity to avoid overflow.
        fcStorage.setMaxUnits(uint256(256) * type(uint16).max);
        uint256 length = _ids.length <= _units.length ? _ids.length : _units.length;
        uint256[] memory ids = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            ids[i] = _ids[i];
        }
        uint256[] memory units = new uint256[](length);
        for (uint256 i; i < length; ++i) {
            units[i] = _units[i];
        }

        // Calculate the number of total units purchased
        uint256 totalUnits;
        for (uint256 i; i < units.length; ++i) {
            totalUnits += units[i];
        }

        // Throw away the run if the total units is zero or exceed max capacity
        vm.assume(totalUnits > 0);
        vm.assume(totalUnits <= fcStorage.maxUnits() - fcStorage.rentedUnits());

        // Add an extra fuzzed amount to the required payment
        uint256 totalCost = fcStorage.price(totalUnits);
        uint256 value = totalCost + bound(delta, 1, type(uint256).max - totalCost);

        vm.deal(msgSender, value);
        vm.prank(msgSender);
        vm.expectRevert(StorageRegistry.InvalidPayment.selector);
        fcStorage.batchRent{value: value}(ids, units);
    }

    function testFuzzUnitPrice(uint48 usdUnitPrice, int256 ethUsdPrice) public {
        // Ensure Chainlink price is positive
        ethUsdPrice = bound(ethUsdPrice, 1, type(int256).max);

        priceFeed.setPrice(ethUsdPrice);
        fcStorage.setPrice(usdUnitPrice);

        assertEq(fcStorage.unitPrice(), uint256(usdUnitPrice) * 1e18 / uint256(ethUsdPrice));
    }

    function testFuzzPrice(uint48 usdUnitPrice, uint128 units, int256 ethUsdPrice) public {
        // Ensure Chainlink price is positive
        ethUsdPrice = bound(ethUsdPrice, 1, type(int256).max);

        priceFeed.setPrice(ethUsdPrice);
        fcStorage.setPrice(usdUnitPrice);

        assertEq(fcStorage.price(units), uint256(usdUnitPrice) * units * 1e18 / uint256(ethUsdPrice));
    }

    function testFuzzPriceFeedRevertsInvalidPrice(int256 price) public {
        // Ensure price is zero or negative
        price = price > 0 ? -price : price;
        priceFeed.setPrice(price);

        vm.expectRevert(StorageRegistry.InvalidPrice.selector);
        fcStorage.unitPrice();
    }

    function testPriceFeedRevertsStalePrice() public {
        // Set stale answeredInRound value
        priceFeed.setRoundData(
            MockPriceFeed.RoundData({
                roundId: 2,
                answer: 2000e8,
                startedAt: block.timestamp,
                timeStamp: block.timestamp,
                answeredInRound: 1
            })
        );

        vm.expectRevert(StorageRegistry.StalePrice.selector);
        fcStorage.unitPrice();
    }

    function testPriceFeedRevertsIncompleteRound() public {
        // Set zero timeStamp value
        priceFeed.setRoundData(
            MockPriceFeed.RoundData({
                roundId: 1,
                answer: 2000e8,
                startedAt: block.timestamp,
                timeStamp: 0,
                answeredInRound: 1
            })
        );
        vm.expectRevert(StorageRegistry.IncompleteRound.selector);
        fcStorage.unitPrice();
    }

    function testUptimeFeedRevertsSequencerDown(int256 answer) public {
        if (answer == 0) ++answer;
        // Set nonzero answer. It's counterintuitive, but a zero answer
        // means the sequencer is up.
        uptimeFeed.setRoundData(
            MockUptimeFeed.RoundData({
                roundId: 1,
                answer: answer,
                startedAt: 0,
                timeStamp: block.timestamp,
                answeredInRound: 1
            })
        );

        vm.expectRevert(StorageRegistry.SequencerDown.selector);
        fcStorage.unitPrice();
    }

    function testUptimeFeedRevertsGracePeriodNotOver() public {
        // Set startedAt == timeStamp, meaning the sequencer just restarted.
        uptimeFeed.setRoundData(
            MockUptimeFeed.RoundData({
                roundId: 1,
                answer: 0,
                startedAt: block.timestamp,
                timeStamp: block.timestamp,
                answeredInRound: 1
            })
        );

        vm.expectRevert(StorageRegistry.GracePeriodNotOver.selector);
        fcStorage.unitPrice();
    }

    function testFuzzOnlyOwnerCanSetUSDUnitPrice(uint256 unitPrice) public {
        vm.prank(mallory);
        vm.expectRevert("Ownable: caller is not the owner");
        fcStorage.setPrice(unitPrice);
    }

    function testFuzzSetUSDUnitPrice(uint256 unitPrice) public {
        uint256 currentPrice = fcStorage.usdUnitPrice();

        vm.expectEmit(false, false, false, true);
        emit SetPrice(currentPrice, unitPrice);

        fcStorage.setPrice(unitPrice);

        assertEq(fcStorage.usdUnitPrice(), unitPrice);
    }

    function testFuzzOnlyOwnerCanSetMaxUnits(uint256 maxUnits) public {
        vm.prank(mallory);
        vm.expectRevert("Ownable: caller is not the owner");
        fcStorage.setMaxUnits(maxUnits);
    }

    function testFuzzSetMaxUnitsEmitsEvent(uint256 maxUnits) public {
        uint256 currentMax = fcStorage.maxUnits();

        vm.expectEmit(false, false, false, true);
        emit SetMaxUnits(currentMax, maxUnits);

        fcStorage.setMaxUnits(maxUnits);

        assertEq(fcStorage.maxUnits(), maxUnits);
    }

    function testFuzzOnlyOwnerCanSetRentalPeriodEnd(uint256 periodEnd) public {
        vm.prank(mallory);
        vm.expectRevert("Ownable: caller is not the owner");
        fcStorage.setRentalPeriodEnd(periodEnd);
    }

    function testFuzzSetRentalPeriodEnd(uint256 timestamp) public {
        uint256 currentEnd = fcStorage.rentalPeriodEnd();

        vm.expectEmit(false, false, false, true);
        emit SetRentalPeriodEnd(currentEnd, timestamp);

        fcStorage.setRentalPeriodEnd(timestamp);

        assertEq(fcStorage.rentalPeriodEnd(), timestamp);
    }

    function testFuzzWithdrawal(address msgSender, uint256 id, uint200 units, uint256 amount) public {
        uint256 balanceBefore = address(owner).balance;

        _rentStorage(msgSender, id, units);

        // Don't withdraw more than the contract balance
        amount = bound(amount, 0, address(fcStorage).balance);

        vm.expectEmit(true, false, false, true);
        emit Withdraw(owner, amount);

        vm.prank(owner);
        fcStorage.withdraw(owner, amount);

        uint256 balanceAfter = address(owner).balance;
        uint256 balanceChange = balanceAfter - balanceBefore;

        assertEq(balanceChange, amount);
    }

    function testFuzzWithdrawalRevertsInsufficientFunds(uint256 amount) public {
        // Ensure amount is positive
        amount = bound(amount, 1, type(uint256).max);

        vm.prank(owner);
        vm.expectRevert(StorageRegistry.InsufficientFunds.selector);
        fcStorage.withdraw(owner, amount);
    }

    function testFuzzWithdrawalRevertsCallFailed() public {
        uint256 price = fcStorage.price(1);
        fcStorage.rent{value: price}(1, 1);

        vm.prank(owner);
        vm.expectRevert(StorageRegistry.CallFailed.selector);
        fcStorage.withdraw(address(revertOnReceive), price);
    }

    function testFuzzOnlyOwnerCanWithdraw(address to, uint256 amount) public {
        vm.prank(mallory);
        vm.expectRevert("Ownable: caller is not the owner");
        fcStorage.withdraw(to, amount);
    }

    function _batchRentStorage(
        address msgSender,
        uint256[] memory ids,
        uint256[] memory units
    ) internal returns (uint256) {
        uint256 rented = fcStorage.rentedUnits();
        uint256 totalUnits;
        for (uint256 i; i < units.length; ++i) {
            totalUnits += units[i];
        }
        uint256 totalCost = fcStorage.price(totalUnits);
        vm.deal(msgSender, totalCost);
        vm.assume(totalUnits <= fcStorage.maxUnits() - fcStorage.rentedUnits());

        // Expect emitted events
        for (uint256 i; i < ids.length; ++i) {
            if (units[i] != 0) {
                vm.expectEmit(true, true, false, true);
                emit Rent(msgSender, ids[i], units[i]);
            }
        }
        vm.prank(msgSender);
        fcStorage.batchRent{value: totalCost}(ids, units);

        // Expect rented units to increase
        assertEq(fcStorage.rentedUnits(), rented + totalUnits);
        return totalCost;
    }

    function _rentStorage(address msgSender, uint256 id, uint256 units) internal returns (uint256) {
        uint256 rented = fcStorage.rentedUnits();
        units = bound(units, 0, fcStorage.maxUnits() - fcStorage.rentedUnits());
        uint256 price = fcStorage.price(units);
        vm.deal(msgSender, price);

        // Expect emitted event
        vm.expectEmit(true, true, false, true);
        emit Rent(msgSender, id, units);

        vm.prank(msgSender);
        fcStorage.rent{value: price}(id, units);

        // Expect rented units to increase
        assertEq(fcStorage.rentedUnits(), rented + units);
        return price;
    }

    receive() external payable {}
}

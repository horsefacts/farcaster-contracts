// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {LogisticVRGDA} from "VRGDAs/LogisticVRGDA.sol";

import {toDaysWadUnsafe, toWadUnsafe} from "solmate/utils/SignedWadMath.sol";

contract VRGDAStorage is LogisticVRGDA, Ownable {
    error EpochOver();
    error InsufficientPayment();
    error InsufficientAvailableUnits();
    error TransferFailed();

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    uint256 public epochEnd;
    uint256 public unitsSold;
    uint256 public immutable startTime = block.timestamp;

    constructor(
        int256 _targetPrice,
        int256 _priceDecayPercent,
        int256 _maxSellable,
        int256 _timeScale
    ) LogisticVRGDA(_targetPrice, _priceDecayPercent, _maxSellable, _timeScale) Ownable() {
        epochEnd = block.timestamp + 365 days;
    }

    function purchase(uint256 id) external payable {
        if (block.timestamp >= epochEnd) revert EpochOver();

        uint256 price = getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), unitsSold++);
        if (msg.value < price) revert InsufficientPayment();

        emit Purchase(msg.sender, id, 1);

        payable(msg.sender).call{value: msg.value - price}("");
    }

    function purchasePrice() external view returns (uint256) {
        return getVRGDAPrice(toDaysWadUnsafe(block.timestamp - startTime), unitsSold);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

import {console} from "forge-std/console.sol";

contract GDAStorage is Ownable {
    using PRBMathSD59x18 for int256;

    error EpochOver();
    error InsufficientPayment();
    error InsufficientAvailableUnits();
    error TransferFailed();

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    uint256 public epochEnd;

    int256 internal initialPrice;
    int256 internal decayConstant;
    int256 internal emissionRate;
    int256 internal lastAvailableAuctionStartTime;

    constructor(int256 _initialPrice, int256 _decayConstant, int256 _emissionRate) Ownable() {
        initialPrice = _initialPrice;
        decayConstant = _decayConstant;
        emissionRate = _emissionRate;
        lastAvailableAuctionStartTime = int256(block.timestamp).fromInt();
        epochEnd = block.timestamp + 365 days;
    }

    function purchase(uint256 id, uint256 units) external payable {
        if (block.timestamp >= epochEnd) revert EpochOver();

        int256 secondsOfEmissionsAvailable = int256(block.timestamp).fromInt() - lastAvailableAuctionStartTime;
        int256 secondsOfEmissionsToPurchase = int256(units).fromInt().div(emissionRate);

        if (secondsOfEmissionsToPurchase > secondsOfEmissionsAvailable) revert InsufficientAvailableUnits();

        uint256 cost = purchasePrice(units);
        if (msg.value < cost) revert InsufficientPayment();

        lastAvailableAuctionStartTime += secondsOfEmissionsToPurchase;
        emit Purchase(msg.sender, id, units);
    }

    function purchasePrice(uint256 units) public view returns (uint256) {
        int256 quantity = int256(units).fromInt();
        int256 timeSinceLastAuctionStart = int256(block.timestamp).fromInt() - lastAvailableAuctionStartTime;
        int256 n1 = initialPrice.div(decayConstant);
        int256 n2 = decayConstant.mul(quantity).div(emissionRate).exp() - PRBMathSD59x18.fromInt(1);
        int256 den = decayConstant.mul(timeSinceLastAuctionStart).exp();
        int256 totalCost = n1.mul(n2).div(den);
        return uint256(totalCost);
    }
}

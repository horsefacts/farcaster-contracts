// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";
import {SD59x18, sd} from "prb-math/SD59x18.sol";

contract GDAStorage is Ownable {
    error EpochOver();
    error InsufficientPayment();
    error InsufficientAvailableUnits();
    error TransferFailed();

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    uint256 public epochEnd;

    SD59x18 internal initialPrice;
    SD59x18 internal decayConstant;
    SD59x18 internal emissionRate;
    SD59x18 internal lastAvailableAuctionStartTime;

    constructor(int256 _initialPrice, int256 _decayConstant, int256 _emissionRate) Ownable() {
        initialPrice = sd(_initialPrice);
        decayConstant = sd(_decayConstant);
        emissionRate = sd(_emissionRate);
        epochEnd = block.timestamp + 365 days;
    }

    function purchase(uint256 id, uint256 units) external payable {
        if (block.timestamp >= epochEnd) revert EpochOver();

        SD59x18 secondsOfEmissionsAvailable = sd(int256(block.timestamp)).sub(lastAvailableAuctionStartTime);
        SD59x18 secondsOfEmissionsToPurchase = sd(int256(units)).div(emissionRate);

        if (secondsOfEmissionsToPurchase.gt(secondsOfEmissionsAvailable)) revert InsufficientAvailableUnits();

        uint256 cost = purchasePrice(units);
        if (msg.value < cost) revert InsufficientPayment();

        lastAvailableAuctionStartTime = lastAvailableAuctionStartTime.add(secondsOfEmissionsToPurchase);
        emit Purchase(msg.sender, id, units);
    }

    function purchasePrice(uint256 units) public view returns (uint256) {
        SD59x18 quantity = sd(int256(units));
        SD59x18 timeSinceLastAuctionStart = sd(int256(block.timestamp)).sub(lastAvailableAuctionStartTime);
        SD59x18 n1 = initialPrice.div(decayConstant);
        SD59x18 n2 = decayConstant.mul(quantity).div(emissionRate).exp().sub(sd(1));
        SD59x18 den = decayConstant.mul(timeSinceLastAuctionStart).exp();
        SD59x18 totalCost = n1.mul(n2).div(den);
        return totalCost.intoUint256();
    }
}

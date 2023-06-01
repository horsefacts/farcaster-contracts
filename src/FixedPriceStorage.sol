// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {AggregatorV3Interface} from "chainlink/v0.8/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

contract FixedPriceStorage is Ownable {
    error EpochOver();
    error InvalidPayment();
    error TransferFailed();

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    AggregatorV3Interface public priceFeed;

    uint256 public epochEnd;
    uint256 public usdUnitPrice = 5e8;

    constructor(AggregatorV3Interface _priceFeed) Ownable() {
        priceFeed = _priceFeed;
        epochEnd = block.timestamp + 365 days;
    }

    function purchase(uint256 id, uint256 units) external payable {
        if (block.timestamp >= epochEnd) revert EpochOver();
        if (msg.value != unitPrice() * units) revert InvalidPayment();

        emit Purchase(msg.sender, id, units);
    }

    function unitPrice() public view returns (uint256) {
        (, int256 ethUsdPrice,,,) = priceFeed.latestRoundData();
        return usdUnitPrice * 1e18 / uint256(ethUsdPrice);
    }

    function withdraw(address to) external onlyOwner {
        (bool success,) = payable(to).call{value: address(this).balance}("");
        if (!success) revert TransferFailed();
    }
}

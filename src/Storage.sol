// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Ownable} from "openzeppelin/contracts/access/Ownable.sol";

contract Storage is Ownable {
    error EpochOver();

    event Purchase(address indexed buyer, uint256 indexed id, uint256 units);

    uint256 public epochEnd;

    constructor() Ownable() {
        epochEnd = block.timestamp + 365 days;
    }

    function purchase(uint256 id, uint256 units) external {
        if (block.timestamp >= epochEnd) revert EpochOver();
        emit Purchase(msg.sender, id, units);
    }
}

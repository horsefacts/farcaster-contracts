// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {AggregatorV3Interface} from "chainlink/v0.8/interfaces/AggregatorV3Interface.sol";

import {BundleRegistry} from "../src/BundleRegistry.sol";
import {IdRegistry} from "../src/IdRegistry.sol";
import {NameRegistry} from "../src/NameRegistry.sol";
import {FixedPriceStorage} from "../src/FixedPriceStorage.sol";
import {GDAStorage} from "../src/GDAStorage.sol";

/* solhint-disable no-empty-blocks */

/**
 * @dev IdRegistryHarness exposes IdRegistry's private methods for test assertions.
 */
contract IdRegistryHarness is IdRegistry {
    constructor(address forwarder) IdRegistry(forwarder) {}

    function getIdCounter() public view returns (uint256) {
        return idCounter;
    }

    function getRecoveryOf(uint256 id) public view returns (address) {
        return recoveryOf[id];
    }

    function getRecoveryTsOf(uint256 id) public view returns (uint256) {
        return uint256(recoveryStateOf[id].startTs);
    }

    function getRecoveryDestinationOf(uint256 id) public view returns (address) {
        return recoveryStateOf[id].destination;
    }

    function getTrustedCaller() public view returns (address) {
        return trustedCaller;
    }

    function getTrustedOnly() public view returns (uint256) {
        return trustedOnly;
    }

    function getPendingOwner() public view returns (address) {
        return pendingOwner;
    }
}

/**
 * @dev NameRegistryHarness exposes NameRegistry's struct values with concise accessors for testing.
 */
contract NameRegistryHarness is NameRegistry {
    constructor(address forwarder) NameRegistry(forwarder) {}

    /// @dev Get the recovery address for a tokenId
    function recoveryOf(uint256 tokenId) public view returns (address) {
        return metadataOf[tokenId].recovery;
    }

    /// @dev Get the expiry timestamp for a tokenId
    function expiryTsOf(uint256 tokenId) public view returns (uint256) {
        return uint256(metadataOf[tokenId].expiryTs);
    }

    /// @dev Get the recovery destination for a tokenId
    function recoveryDestinationOf(uint256 tokenId) public view returns (address) {
        return recoveryStateOf[tokenId].destination;
    }

    /// @dev Get the recovery timestamp for a tokenId
    function recoveryTsOf(uint256 tokenId) public view returns (uint256) {
        return uint256(recoveryStateOf[tokenId].startTs);
    }
}

/**
 * @dev BundleRegistryHarness exposes IdRegistry's private methods for test assertions.
 */
contract BundleRegistryHarness is BundleRegistry {
    constructor(
        address idRegistry,
        address nameRegistry,
        address trustedCaller
    ) BundleRegistry(idRegistry, nameRegistry, trustedCaller) {}

    function getTrustedCaller() public view returns (address) {
        return trustedCaller;
    }
}

contract FixedPriceStorageHarness is FixedPriceStorage {
    constructor(AggregatorV3Interface _priceFeed) FixedPriceStorage(_priceFeed) {}
}

contract GDAStorageHarness is GDAStorage {
    constructor(
        int256 _initialPrice,
        int256 _decayConstant,
        int256 _emissionRate
    ) GDAStorage(_initialPrice, _decayConstant, _emissionRate) {}
}

contract MockPriceFeed is AggregatorV3Interface {
    struct RoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 timeStamp;
        uint80 answeredInRound;
    }

    RoundData public roundData;

    uint8 public decimals = 8;
    string public description = "Mock ETH/USD Price Feed";
    uint256 public version = 1;

    function setRoundData(RoundData calldata _roundData) external {
        roundData = _roundData;
    }

    function getRoundData(uint80) external view returns (uint80, int256, uint256, uint256, uint80) {
        return latestRoundData();
    }

    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        return
            (roundData.roundId, roundData.answer, roundData.startedAt, roundData.timeStamp, roundData.answeredInRound);
    }
}

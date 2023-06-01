// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import {FixedPriceStorageHarness, MockPriceFeed} from "../Utils.sol";

/* solhint-disable state-visibility */

abstract contract StorageTestSuite is Test {
    FixedPriceStorageHarness fcStorage;
    MockPriceFeed priceFeed;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    //address constant FORWARDER = address(0xC8223c8AD514A19Cc10B0C94c39b52D4B43ee61A);

    address owner = address(this);

    function setUp() public {
        priceFeed = new MockPriceFeed();
        fcStorage = new FixedPriceStorageHarness(priceFeed);

        priceFeed.setRoundData(
            MockPriceFeed.RoundData({
                roundId: 1,
                answer: 2000e8, // $2000 USD/ETH
                startedAt: block.timestamp,
                timeStamp: block.timestamp,
                answeredInRound: 1
            })
        );
    }

    /*//////////////////////////////////////////////////////////////
                              TEST HELPERS
    //////////////////////////////////////////////////////////////*/
}

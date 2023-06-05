// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import {FixedPriceStorageHarness, GDAStorageHarness, MockPriceFeed} from "../Utils.sol";
import {PRBMathSD59x18} from "prb-math/PRBMathSD59x18.sol";

/* solhint-disable state-visibility */

abstract contract StorageTestSuite is Test {
    using PRBMathSD59x18 for int256;

    FixedPriceStorageHarness fcStorage;
    GDAStorageHarness gdaStorage;
    MockPriceFeed priceFeed;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    //address constant FORWARDER = address(0xC8223c8AD514A19Cc10B0C94c39b52D4B43ee61A);

    address owner = address(this);

    function setUp() public {
        priceFeed = new MockPriceFeed();
        fcStorage = new FixedPriceStorageHarness(priceFeed);
        gdaStorage = new GDAStorageHarness(
            PRBMathSD59x18.fromInt(10),
            PRBMathSD59x18.fromInt(1).div(PRBMathSD59x18.fromInt(1000)),
            PRBMathSD59x18.fromInt(1000).div(PRBMathSD59x18.fromInt(1 hours))
        );

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

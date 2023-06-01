// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "forge-std/Test.sol";

import {StorageHarness} from "../Utils.sol";

/* solhint-disable state-visibility */

abstract contract StorageTestSuite is Test {
    StorageHarness fcStorage;

    /*//////////////////////////////////////////////////////////////
                                CONSTANTS
    //////////////////////////////////////////////////////////////*/

    //address constant FORWARDER = address(0xC8223c8AD514A19Cc10B0C94c39b52D4B43ee61A);

    address owner = address(this);

    function setUp() public {
        fcStorage = new StorageHarness();
    }

    /*//////////////////////////////////////////////////////////////
                              TEST HELPERS
    //////////////////////////////////////////////////////////////*/
}

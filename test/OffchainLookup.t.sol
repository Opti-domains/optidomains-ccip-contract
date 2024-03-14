// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "test/setup/DeployCCIP.sol";

contract OffchainLookupTest is Test, DeployCCIP {
    function setUp() public virtual override {
        super.setUp();
    }

    function testAddr() public {
        address addr = resolver.addr(0x1a63898c3849a1c65b7e5b98128ab7f7d61ba88b58e5c89f445b9ef5db234349);
        console2.log(addr);
        assertEq(addr, 0xf01Dd015Bc442d872275A79b9caE84A6ff9B2A27);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "test/setup/DeployCCIP.sol";

// nick.eth: 0x05a67c0ee82964c4f7394cdd47fee7f4d9503a23c09c38341779ea012afe6e00

bytes32 constant NICK_ETH = 0x05a67c0ee82964c4f7394cdd47fee7f4d9503a23c09c38341779ea012afe6e00;

contract FallbackExistingTest is Test, DeployCCIP {
    function setUp() public virtual override {
        uint256 forkId = vm.createFork(vm.envString("FORK_URL"), 19_400_000);
        vm.selectFork(forkId);

        super.setUp();
    }

    function testAddr() public {
        vm.prank(0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5);
        resolver.setAddr(NICK_ETH, 0x4200000000000000000000000000000000000042);
        vm.stopPrank();

        assertEq(resolver.addr(NICK_ETH), 0x4200000000000000000000000000000000000042);
    }

    function testText() public {
        vm.prank(0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5);
        resolver.setText(NICK_ETH, "com.twitter", "optidomains");
        vm.stopPrank();

        // com.twitter
        assertEq(resolver.text(NICK_ETH, "com.twitter"), "optidomains");

        vm.prank(0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5);
        resolver.setText(NICK_ETH, "newrecord", "something");
        vm.stopPrank();

        // newrecord
        assertEq(resolver.text(NICK_ETH, "newrecord"), "something");
    }

    function testContentHash() public {
        assertEq(
            resolver.contenthash(NICK_ETH),
            hex"e5010172002408011220066e20f72cc583d769bc8df5fedff24942b3b8941e827f023d306bdc7aecf5ac"
        );
    }
}

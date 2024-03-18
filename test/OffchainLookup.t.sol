// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "test/setup/DeployCCIP.sol";

bytes32 constant NICK_ETH = 0x05a67c0ee82964c4f7394cdd47fee7f4d9503a23c09c38341779ea012afe6e00;

contract OffchainLookupTest is Test, DeployCCIP {
    function setUp() public virtual override {
        uint256 forkId = vm.createFork(vm.envString("FORK_URL"), 19_400_000);
        vm.selectFork(forkId);

        super.setUp();
    }

    function testText() public {
        resolver.text(NICK_ETH, "newrecord");
    }
}

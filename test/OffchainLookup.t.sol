// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "test/setup/DeployCCIP.sol";

contract OffchainLookupTest is Test, DeployCCIP {
    function setUp() public virtual override {
        uint256 forkId = vm.createFork(vm.envString("FORK_URL"), 19_400_000);
        vm.selectFork(forkId);

        super.setUp();
    }
}

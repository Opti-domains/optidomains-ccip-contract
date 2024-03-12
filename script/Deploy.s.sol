// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";

import {OptiL1ResolverMetadata, IOptiL1ResolverMetadata} from "src/metadata/OptiL1ResolverMetadata.sol";

address constant DEPLOYER = 0x4200000000000000000000000000000000000021;

contract Deploy is Script {
    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        // require(msg.sender == DEPLOYER, "Not DEPLOYER");
        _;
        vm.stopBroadcast();
    }

    /// @notice Modifier that wraps a function in prank.
    modifier prank() {
        vm.startPrank(DEPLOYER);
        _;
        vm.stopPrank();
    }

    function setUp() public {}

    function deployResolverMetadata() internal returns (OptiL1ResolverMetadata) {
        return new OptiL1ResolverMetadata();
    }

    function deployResolverMetadataProxy(address impl, address owner) internal {}

    function deployDiamondResolver(address owner) internal {}

    function _run() internal {
        OptiL1ResolverMetadata resolverMetadata = deployResolverMetadata();

        deployResolverMetadataProxy(address(resolverMetadata), DEPLOYER);
        deployDiamondResolver(DEPLOYER);
    }

    function runBroadcast() public broadcast {
        _run();
    }

    function runPrank() public prank {
        _run();
    }

    function run() public {
        runBroadcast();
    }
}

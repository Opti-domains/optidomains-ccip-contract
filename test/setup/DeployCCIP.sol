// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {console2} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";
import {Deploy, OptiL1Metadata, DiamondResolver, OptiL1PublicResolverFallback} from "script/Deploy.s.sol";

contract DeployCCIP {
    /// @notice The address of the foundry Vm contract.
    Vm private constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    /// @notice The address of the Deploy contract. Set into state with `etch` to avoid
    ///         mutating any nonces. MUST not have constructor logic.
    Deploy internal constant deploy = Deploy(address(uint160(uint256(keccak256(abi.encode("optimism.deploy"))))));

    OptiL1Metadata resolverMetadata;
    DiamondResolver diamondResolver;
    OptiL1PublicResolverFallback publicResolverFallback;

    OptiL1PublicResolverFallback resolver;

    /// @dev Deploys the Deploy contract without including its bytecode in the bytecode
    ///      of this contract by fetching the bytecode dynamically using `vm.getCode()`.
    ///      If the Deploy bytecode is included in this contract, then it will double
    ///      the compile time and bloat all of the test contract artifacts since they
    ///      will also need to include the bytecode for the Deploy contract.
    ///      This is a hack as we are pushing solidity to the edge.
    function setUp() public virtual {
        vm.etch(address(deploy), vm.getDeployedCode("Deploy.s.sol:Deploy"));
        vm.allowCheatcodes(address(deploy));
        deploy.setUp();

        deployCCIP();
    }

    function deployCCIP() public {
        deploy.runDebug();

        resolverMetadata = deploy.resolverMetadata();
        diamondResolver = deploy.diamondResolver();
        publicResolverFallback = deploy.publicResolverFallback();

        resolver = OptiL1PublicResolverFallback(address(diamondResolver));
    }
}

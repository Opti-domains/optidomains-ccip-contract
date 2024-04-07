// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ICREATE3Factory} from "lib/create3-factory/src/ICREATE3Factory.sol";
import {IDiamondWritableInternal} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import "src/metadata/OptiL1Metadata.sol";
import {OptiL1PublicResolverFacet} from "src/facet/OptiL1PublicResolverFacet.sol";
import {OptiL1PublicResolverFallback} from "src/metadata/OptiL1PublicResolverFallback.sol";
import {OptiL1DiamondResolver} from "src/ccip/OptiL1DiamondResolver.sol";

address constant DEPLOYER = 0x424242554b027D8661cf60C87195949f8426BCA5;

address constant CREATE3FACTORY = 0x9fBB3DF7C40Da2e5A0dE984fFE2CCB7C47cd0ABf;

// 0x4242ff8798CdDFf600c41c818F4f9d3E922B609f
bytes32 constant METADATA_SALT = 0x0000000000000000000000000000000000000000f75b656fc843dfea68723db7;

// 0x4242008c912fEA62C3fe4C8d4Cd4eD3319738ef0
bytes32 constant DIAMOND_RESOLVER_SALT = 0x0000000000000000000000000000000000000000ae1787e6c414de748181697a;

// address constant ENS_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
address constant OP_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
address constant OP_STORAGE = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
bytes32 constant OP_NAMEHASH = 0x070904f45402bbf3992472be342c636609db649a8ec20a8aaa65faaafd4b8701;

contract Deploy is Script {
    using Strings for uint256;

    OptiL1Metadata public resolverMetadata;
    OptiL1DiamondResolver public diamondResolver;
    OptiL1PublicResolverFallback public publicResolverFallback;

    string RPC_URL;

    address NAME_WRAPPER;
    address[] OFFICIAL_RESOLVERS;
    string[] GATEWAY_URLS;

    bool UPGRADE_PUBLIC_RESOLVER_FALLBACK;
    bool UPGRADE_PUBLIC_RESOLVER_FACET;
    bool UPGRADE_RESOLVER_CONTROLLER_FACET;

    modifier env() {
        RPC_URL = vm.envString("RPC_URL");

        NAME_WRAPPER = vm.envAddress(string.concat("NAME_WRAPPER_", block.chainid.toString()));
        OFFICIAL_RESOLVERS = vm.envAddress(string.concat("OFFICIAL_RESOLVERS_", block.chainid.toString()), ",");
        GATEWAY_URLS = vm.envString("GATEWAY_URLS", ",");

        UPGRADE_PUBLIC_RESOLVER_FALLBACK = vm.envOr("UPGRADE_PUBLIC_RESOLVER_FALLBACK", false);
        UPGRADE_PUBLIC_RESOLVER_FACET = vm.envOr("UPGRADE_PUBLIC_RESOLVER_FACET", false);
        UPGRADE_RESOLVER_CONTROLLER_FACET = vm.envOr("UPGRADE_RESOLVER_CONTROLLER_FACET", false);

        _;
    }

    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        // require(msg.sender == DEPLOYER, "Not DEPLOYER");
        _;
        vm.stopBroadcast();
    }

    /// @notice Modifier that wraps a function in broadcasting for debug mode.
    modifier debug() {
        UPGRADE_PUBLIC_RESOLVER_FALLBACK = true;
        UPGRADE_PUBLIC_RESOLVER_FACET = true;
        UPGRADE_RESOLVER_CONTROLLER_FACET = true;

        vm.deal(DEPLOYER, 1000 ether);
        vm.startBroadcast(DEPLOYER);
        _;
        vm.stopBroadcast();
    }

    function setUp() public {}

    function deployPublicResolverFallback(address l1ResolverFallback) internal returns (OptiL1PublicResolverFallback) {
        return new OptiL1PublicResolverFallback(ENS(ENS_REGISTRY), INameWrapper(NAME_WRAPPER), l1ResolverFallback);
    }

    function deployMetadata(address owner) internal returns (OptiL1Metadata, bool) {
        address target = ICREATE3Factory(CREATE3FACTORY).getDeployed(DEPLOYER, METADATA_SALT);

        if (target.code.length > 0) {
            return (OptiL1Metadata(payable(target)), false);
        }

        address deployed = ICREATE3Factory(CREATE3FACTORY).deploy(
            METADATA_SALT, abi.encodePacked(type(OptiL1Metadata).creationCode, abi.encode(owner, OP_NAMEHASH))
        );

        return (OptiL1Metadata(payable(deployed)), true);
    }

    function deployDiamondResolver(address owner) internal returns (OptiL1DiamondResolver, bool) {
        address target = ICREATE3Factory(CREATE3FACTORY).getDeployed(DEPLOYER, DIAMOND_RESOLVER_SALT);

        if (target.code.length > 0) {
            return (OptiL1DiamondResolver(payable(target)), false);
        }

        address deployed = ICREATE3Factory(CREATE3FACTORY).deploy(
            DIAMOND_RESOLVER_SALT, abi.encodePacked(type(OptiL1DiamondResolver).creationCode, abi.encode(owner))
        );

        return (OptiL1DiamondResolver(payable(deployed)), true);
    }

    function registerPublicResolverFacet(OptiL1DiamondResolver diamond, IDiamondWritableInternal.FacetCutAction action)
        internal
    {
        OptiL1PublicResolverFacet facet = new OptiL1PublicResolverFacet();

        bytes4[] memory selectors = new bytes4[](23);
        uint256 selectorIndex;

        // Register selectors (Since some of resolver method is not available on the interface, we need low level)
        selectors[selectorIndex++] = 0x2203ab56; // ABI(bytes32,uint256)
        selectors[selectorIndex++] = 0x3b3b57de; // addr(bytes32)
        selectors[selectorIndex++] = 0xf1cb7e06; // addr(bytes32,uint256)
        selectors[selectorIndex++] = 0xbc1c58d1; // contenthash(bytes32)
        selectors[selectorIndex++] = 0xa8fa5682; // dnsRecord(bytes32,bytes32,uint16)
        selectors[selectorIndex++] = 0x4cbf6ba4; // hasDNSRecords(bytes32,bytes32)
        selectors[selectorIndex++] = 0x124a319c; // interfaceImplementer(bytes32,bytes4)
        selectors[selectorIndex++] = 0x691f3431; // name(bytes32)
        selectors[selectorIndex++] = 0xc8690233; // pubkey(bytes32)
        selectors[selectorIndex++] = 0x623195b0; // setABI(bytes32,uint256,bytes)
        selectors[selectorIndex++] = 0x8b95dd71; // setAddr(bytes32,uint256,bytes)
        selectors[selectorIndex++] = 0xd5fa2b00; // setAddr(bytes32,address)
        selectors[selectorIndex++] = 0x0988c55d; // setAddrWithRef(bytes32,uint256,bytes32,bytes)
        selectors[selectorIndex++] = 0x304e6ade; // setContenthash(bytes32,bytes)
        selectors[selectorIndex++] = 0x0af179d7; // setDNSRecords(bytes32,bytes)
        selectors[selectorIndex++] = 0xe59d895d; // setInterface(bytes32,bytes4,address)
        selectors[selectorIndex++] = 0x77372213; // setName(bytes32,string)
        selectors[selectorIndex++] = 0x29cd62ea; // setPubkey(bytes32,bytes32,bytes32)
        selectors[selectorIndex++] = 0x10f13a8c; // setText(bytes32,string,string)
        selectors[selectorIndex++] = 0x966bf6d6; // setTextWithRef(bytes32,bytes32,string,string)
        selectors[selectorIndex++] = 0xce3decdc; // setZonehash(bytes32,bytes)
        selectors[selectorIndex++] = 0x59d1d43c; // text(bytes32,string)
        selectors[selectorIndex++] = 0x5c98042b; // zonehash(bytes32)

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        facetCuts[0] = IDiamondWritableInternal.FacetCut({target: address(facet), action: action, selectors: selectors});

        // Diamond cut and initialize
        diamond.diamondCut(facetCuts, address(facet), abi.encodeWithSelector(0x8129fc1c));
    }

    function _run() internal {
        bool resolverMetadataInitMode = false;
        bool diamondResolverInitMode = false;

        (resolverMetadata, resolverMetadataInitMode) = deployMetadata(DEPLOYER);

        if (UPGRADE_PUBLIC_RESOLVER_FALLBACK) {
            publicResolverFallback = deployPublicResolverFallback(address(resolverMetadata));

            OFFICIAL_RESOLVERS.push(address(publicResolverFallback));

            if (!resolverMetadataInitMode) {
                resolverMetadata.set(
                    METADATA_WRITE_RESOLVER, bytes32(uint256(uint160(address(publicResolverFallback))))
                );

                address[] memory publicResolverFallbackArray = new address[](1);
                publicResolverFallbackArray[0] = address(publicResolverFallback);

                resolverMetadata.initParams(
                    new bytes32[](0), new bytes32[](0), new string[](0), publicResolverFallbackArray
                );
            }
        } else {
            publicResolverFallback = OptiL1PublicResolverFallback(resolverMetadata.configAddr(METADATA_WRITE_RESOLVER));
        }

        (diamondResolver, diamondResolverInitMode) = deployDiamondResolver(DEPLOYER);

        if (resolverMetadataInitMode) {
            bytes32[] memory keys = new bytes32[](5);
            bytes32[] memory values = new bytes32[](5);

            keys[0] = METADATA_CCIP_RESOLVER;
            values[0] = bytes32(uint256(uint160(address(diamondResolver))));

            keys[1] = METADATA_WRITE_RESOLVER;
            values[1] = bytes32(uint256(uint160(address(publicResolverFallback))));

            keys[2] = METADATA_OP_REGISTRY;
            values[2] = bytes32(uint256(uint160(OP_REGISTRY)));

            keys[3] = METADATA_OP_STORAGE;
            values[3] = bytes32(uint256(uint160(OP_STORAGE)));

            keys[4] = METADATA_NAME_WRAPPER;
            values[4] = bytes32(uint256(uint160(NAME_WRAPPER)));

            resolverMetadata.initParams(keys, values, GATEWAY_URLS, OFFICIAL_RESOLVERS);
        }

        if (UPGRADE_PUBLIC_RESOLVER_FACET) {
            registerPublicResolverFacet(
                diamondResolver,
                diamondResolverInitMode
                    ? IDiamondWritableInternal.FacetCutAction.ADD
                    : IDiamondWritableInternal.FacetCutAction.REPLACE
            );
        }

        // console2.log("OptiL1ResolverMetadata:", address(resolverMetadata));
        // console2.log("DiamondResolver:", address(diamondResolver));
    }

    function runBroadcast() public env broadcast {
        _run();
    }

    function runDebug() public env debug {
        _run();
    }

    function scratchpad() public {
        // OptiL1PublicResolverFallback resolver = OptiL1PublicResolverFallback(address(diamondResolver));
        // address addr = resolver.addr(0x1a63898c3849a1c65b7e5b98128ab7f7d61ba88b58e5c89f445b9ef5db234349);
        // console2.log(addr);
        // resolver.text(0x1a63898c3849a1c65b7e5b98128ab7f7d61ba88b58e5c89f445b9ef5db234349, "newrecord");
    }

    function run() public env {
        if (keccak256(abi.encode(RPC_URL)) == keccak256(abi.encode("http://127.0.0.1:8545"))) {
            runDebug();
        } else {
            runBroadcast();
        }

        scratchpad();
    }
}

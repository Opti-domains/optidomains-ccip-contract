// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ICREATE3Factory} from "lib/create3-factory/src/ICREATE3Factory.sol";
import {DiamondResolver} from "@optidomains/modular-ens-contracts/current/diamond/DiamondResolver.sol";
import {IDiamondWritableInternal} from "@solidstate/contracts/proxy/diamond/writable/IDiamondWritableInternal.sol";

import {
    OptiL1ResolverMetadata,
    OptiL1ResolverFallback,
    IOptiL1ResolverMetadata
} from "src/metadata/OptiL1ResolverMetadata.sol";
import {OwnableUpgradeableProxy} from "src/proxy/OwnableUpgradeableProxy.sol";
import {OptiL1PublicResolverFallback, ENS, INameWrapper} from "src/fallback/OptiL1PublicResolverFallback.sol";
import {OptiL1PublicResolverFacet} from "src/facet/OptiL1PublicResolverFacet.sol";
import {OptiL1ResolverControllerFacet} from "src/facet/OptiL1ResolverControllerFacet.sol";

address constant DEPLOYER = 0x424242554b027D8661cf60C87195949f8426BCA5;

address constant CREATE3FACTORY = 0x9fBB3DF7C40Da2e5A0dE984fFE2CCB7C47cd0ABf;

// 0x4242ff8798CdDFf600c41c818F4f9d3E922B609f
bytes32 constant RESOLVER_METADATA_SALT = 0x0000000000000000000000000000000000000000f75b656fc843dfea68723db7;

// 0x4242008c912fEA62C3fe4C8d4Cd4eD3319738ef0
bytes32 constant DIAMOND_RESOLVER_SALT = 0x0000000000000000000000000000000000000000ae1787e6c414de748181697a;

address constant ENS_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
address constant OP_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
address constant OP_BASE_RESOLVER = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
bytes32 constant OP_NAMEHASH = 0x070904f45402bbf3992472be342c636609db649a8ec20a8aaa65faaafd4b8701;

contract Deploy is Script {
    using Strings for uint256;

    OptiL1ResolverMetadata public resolverMetadata;
    DiamondResolver public diamondResolver;
    OptiL1PublicResolverFallback public publicResolverFallback;

    string RPC_URL = vm.envString("RPC_URL");

    address NAME_WRAPPER = vm.envAddress(string.concat("NAME_WRAPPER_", block.chainid.toString()));
    address[] OFFICIAL_RESOLVERS = vm.envAddress(string.concat("OFFICIAL_RESOLVERS_", block.chainid.toString()), ",");
    string[] GATEWAY_URLS = vm.envString("GATEWAY_URLS", ",");

    bool UPGRADE_RESOLVER_METADATA = vm.envOr("UPGRADE_RESOLVER_METADATA", false);
    bool UPGRADE_PUBLIC_RESOLVER_FALLBACK = vm.envOr("UPGRADE_PUBLIC_RESOLVER_FALLBACK", false);
    bool UPGRADE_PUBLIC_RESOLVER_FACET = vm.envOr("UPGRADE_PUBLIC_RESOLVER_FACET", false);
    bool UPGRADE_RESOLVER_CONTROLLER_FACET = vm.envOr("UPGRADE_RESOLVER_CONTROLLER_FACET", false);

    /// @notice Modifier that wraps a function in broadcasting.
    modifier broadcast() {
        vm.startBroadcast(msg.sender);
        // require(msg.sender == DEPLOYER, "Not DEPLOYER");
        _;
        vm.stopBroadcast();
    }

    /// @notice Modifier that wraps a function in broadcasting for debug mode.
    modifier debug() {
        UPGRADE_RESOLVER_METADATA = true;
        UPGRADE_PUBLIC_RESOLVER_FALLBACK = true;
        UPGRADE_PUBLIC_RESOLVER_FACET = true;
        UPGRADE_RESOLVER_CONTROLLER_FACET = true;

        vm.deal(DEPLOYER, 1000 ether);
        vm.startBroadcast(DEPLOYER);
        _;
        vm.stopBroadcast();
    }

    function setUp() public {}

    function deployResolverMetadata() internal returns (OptiL1ResolverMetadata) {
        return new OptiL1ResolverMetadata();
    }

    function deployPublicResolverFallback(address l1ResolverFallback) internal returns (OptiL1PublicResolverFallback) {
        return new OptiL1PublicResolverFallback(ENS(ENS_REGISTRY), INameWrapper(NAME_WRAPPER), l1ResolverFallback);
    }

    function deployResolverMetadataProxy(address impl, address owner) internal returns (OptiL1ResolverMetadata, bool) {
        address target = ICREATE3Factory(CREATE3FACTORY).getDeployed(DEPLOYER, RESOLVER_METADATA_SALT);

        if (target.code.length > 0) {
            return (OptiL1ResolverMetadata(payable(target)), false);
        }

        address deployed = ICREATE3Factory(CREATE3FACTORY).deploy(
            RESOLVER_METADATA_SALT,
            abi.encodePacked(type(OwnableUpgradeableProxy).creationCode, abi.encode(impl, owner))
        );

        return (OptiL1ResolverMetadata(payable(deployed)), true);
    }

    function deployDiamondResolver(address owner) internal returns (DiamondResolver, bool) {
        address target = ICREATE3Factory(CREATE3FACTORY).getDeployed(DEPLOYER, DIAMOND_RESOLVER_SALT);

        if (target.code.length > 0) {
            return (DiamondResolver(payable(target)), false);
        }

        address deployed = ICREATE3Factory(CREATE3FACTORY).deploy(
            DIAMOND_RESOLVER_SALT, abi.encodePacked(type(DiamondResolver).creationCode, abi.encode(owner))
        );

        return (DiamondResolver(payable(deployed)), true);
    }

    function registerPublicResolverFacet(DiamondResolver diamond, IDiamondWritableInternal.FacetCutAction action)
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

    function registerResolverControllerFacet(
        DiamondResolver diamond,
        IDiamondWritableInternal.FacetCutAction action,
        bytes32 tldNameHash
    ) internal {
        OptiL1ResolverControllerFacet facet = new OptiL1ResolverControllerFacet();

        bytes4[] memory selectors = new bytes4[](4);
        uint256 selectorIndex;

        selectors[selectorIndex++] = 0x15346a5f; // setTarget(bytes32,bytes32)
        selectors[selectorIndex++] = 0x90c9d877; // target(bytes32)
        selectors[selectorIndex++] = 0xfca56f27; // enableWildcard(bytes32,bool)
        selectors[selectorIndex++] = 0xdbae4c62; // isWildcardEnabled(bytes32)

        IDiamondWritableInternal.FacetCut[] memory facetCuts = new IDiamondWritableInternal.FacetCut[](1);

        facetCuts[0] = IDiamondWritableInternal.FacetCut({target: address(facet), action: action, selectors: selectors});

        // Diamond cut and initialize
        diamond.diamondCut(facetCuts, address(facet), abi.encodeWithSelector(0x9498bd71, tldNameHash));
    }

    function _run() internal {
        bool resolverMetadataInitMode = false;
        bool diamondResolverInitMode = false;

        if (UPGRADE_RESOLVER_METADATA) {
            OptiL1ResolverMetadata resolverMetadataImpl = deployResolverMetadata();
            (resolverMetadata, resolverMetadataInitMode) =
                deployResolverMetadataProxy(address(resolverMetadataImpl), DEPLOYER);

            if (!resolverMetadataInitMode) {
                OwnableUpgradeableProxy(payable(address(resolverMetadata))).setImplementation(
                    address(resolverMetadataImpl)
                );
            }
        } else {
            (resolverMetadata, resolverMetadataInitMode) = deployResolverMetadataProxy(address(0), msg.sender);
        }

        if (UPGRADE_PUBLIC_RESOLVER_FALLBACK) {
            publicResolverFallback = deployPublicResolverFallback(address(resolverMetadata));

            OFFICIAL_RESOLVERS.push(address(publicResolverFallback));

            if (!resolverMetadataInitMode) {
                resolverMetadata.setWriteResolver(address(publicResolverFallback));
            }
        } else {
            publicResolverFallback = OptiL1PublicResolverFallback(resolverMetadata.writeResolver());
        }

        (diamondResolver, diamondResolverInitMode) = deployDiamondResolver(DEPLOYER);

        if (resolverMetadataInitMode) {
            resolverMetadata.initParams(
                address(publicResolverFallback),
                address(diamondResolver),
                OP_REGISTRY,
                OP_BASE_RESOLVER,
                NAME_WRAPPER,
                OFFICIAL_RESOLVERS,
                GATEWAY_URLS
            );
        }

        if (UPGRADE_PUBLIC_RESOLVER_FACET) {
            registerPublicResolverFacet(
                diamondResolver,
                diamondResolverInitMode
                    ? IDiamondWritableInternal.FacetCutAction.ADD
                    : IDiamondWritableInternal.FacetCutAction.REPLACE
            );
        }

        if (UPGRADE_RESOLVER_CONTROLLER_FACET) {
            registerResolverControllerFacet(
                diamondResolver,
                diamondResolverInitMode
                    ? IDiamondWritableInternal.FacetCutAction.ADD
                    : IDiamondWritableInternal.FacetCutAction.REPLACE,
                OP_NAMEHASH
            );
        }

        console2.log("OptiL1ResolverMetadata:", address(resolverMetadata));
        console2.log("DiamondResolver:", address(diamondResolver));
    }

    function runBroadcast() public broadcast {
        _run();
    }

    function runDebug() public debug {
        _run();
    }

    function scratchpad() public {
        OptiL1PublicResolverFallback resolver = OptiL1PublicResolverFallback(address(diamondResolver));
        address addr = resolver.addr(0x1a63898c3849a1c65b7e5b98128ab7f7d61ba88b58e5c89f445b9ef5db234349);
        console2.log(addr);
    }

    function run() public {
        if (keccak256(abi.encode(RPC_URL)) == keccak256(abi.encode("http://127.0.0.1:8545"))) {
            runDebug();
        } else {
            runBroadcast();
        }

        scratchpad();
    }
}

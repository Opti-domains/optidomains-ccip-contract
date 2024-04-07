// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "test/setup/DeployCCIP.sol";

bytes32 constant NICK_ETH = 0x05a67c0ee82964c4f7394cdd47fee7f4d9503a23c09c38341779ea012afe6e00;
address constant NICK_OWNER = 0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5;

bytes32 constant RESOLVER_STORAGE_NAMESPACE = keccak256("optidomains.resolver.storage");

// Schemas
bytes32 constant ABI_RESOLVER_SCHEMA =
    keccak256(abi.encodePacked("bytes32 node,uint256 contentType,bytes abi", address(0), true));
bytes32 constant ADDR_RESOLVER_SCHEMA =
    keccak256(abi.encodePacked("bytes32 node,uint256 coinType,bytes address", address(0), true));
bytes32 constant CONTENT_RESOLVER_SCHEMA = keccak256(abi.encodePacked("bytes32 node,bytes hash", address(0), true));
bytes32 constant DNS_RESOLVER_SCHEMA_ZONEHASHES =
    keccak256(abi.encodePacked("bytes32 node,bytes zonehashes", address(0), true));
bytes32 constant DNS_RESOLVER_SCHEMA_RECORDS =
    keccak256(abi.encodePacked("bytes32 node,bytes32 nameHash,uint16 resource,bytes data", address(0), true));
bytes32 constant DNS_RESOLVER_SCHEMA_COUNT =
    keccak256(abi.encodePacked("bytes32 node,bytes32 nameHash,uint16 count", address(0), true));
bytes32 constant INTERFACE_RESOLVER_SCHEMA =
    keccak256(abi.encodePacked("bytes32 node,bytes4 interfaceID,address implementer", address(0), true));
bytes32 constant NAME_RESOLVER_SCHEMA = keccak256(abi.encodePacked("bytes32 node,string name", address(0), true));
bytes32 constant PUBKEY_RESOLVER_STORAGE = keccak256("optidomains.resolver.PubkeyResolverStorage");
bytes32 constant PUBKEY_RESOLVER_SCHEMA =
    keccak256(abi.encodePacked("bytes32 node,bytes32 x,bytes32 y", address(0), true));
bytes32 constant TEXT_RESOLVER_SCHEMA =
    keccak256(abi.encodePacked("bytes32 node,string key,string value", address(0), true));

contract OffchainLookupTest is Test, DeployCCIP {
    error HeaderMustIncludeNode();
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);

    string[] GATEWAY_URLS = vm.envString("GATEWAY_URLS", ",");

    function _storageSlotCommon(bytes32 schema, address recipient, bytes memory header)
        private
        pure
        returns (bytes32 s)
    {
        if (header.length < 32) revert HeaderMustIncludeNode();

        bytes memory packed = abi.encodePacked(header, schema, recipient, RESOLVER_STORAGE_NAMESPACE);
        uint256 packedLength = packed.length;

        assembly {
            // keccak256 hash omiting node
            s := keccak256(add(packed, 0x40), sub(packedLength, 0x20))
        }
    }

    function offchainLookup(bytes32 schema, bytes memory header, bytes memory callbackData)
        internal
        view
        returns (bytes memory)
    {
        bytes32 ensNode;
        assembly {
            ensNode := mload(add(header, 0x20))
        }

        bytes32[] memory slots = new bytes32[](1);
        slots[0] = _storageSlotCommon(schema, NICK_OWNER, header);

        // return abi.encodeWithSelector(OffchainLookup.selector, address(resolver), GATEWAY_URLS, , OptiFetchTarget.ccipAttCallback.selector, abi.encode(ensNode, slots, callbackData));
    }

    function setUp() public virtual override {
        uint256 forkId = vm.createFork(vm.envString("FORK_URL"), 19_400_000);
        vm.selectFork(forkId);

        super.setUp();
    }

    function testText() public {
        // resolver.text(NICK_ETH, "newrecord");
    }
}

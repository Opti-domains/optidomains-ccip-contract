// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Deployment from Create3
address constant OPTI_L1_RESOLVER_METADATA = 0x4242ff8798CdDFf600c41c818F4f9d3E922B609f;

// Config keys
bytes32 constant METADATA_CCIP_RESOLVER = keccak256("CCIP_RESOLVER");
bytes32 constant METADATA_WRITE_RESOLVER = keccak256("WRITE_RESOLVER");
bytes32 constant METADATA_OP_REGISTRY = keccak256("OP_REGISTRY");
bytes32 constant METADATA_OP_STORAGE = keccak256("OP_STORAGE");
bytes32 constant METADATA_NAME_WRAPPER = keccak256("NAME_WRAPPER");

interface IOptiL1Metadata {
    function config(bytes32 key) external view returns (bytes32);
    function configAddr(bytes32 key) external view returns (address);
    function target(bytes32 key) external view returns (bytes32);
    function wildcardEnabled(bytes32 key) external view returns (bool);

    function gatewayURLs() external view returns (string[] memory);
    function officialResolvers() external view returns (address[] memory);

    function write(address caller, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../ccip/UseENSAuth.sol";
import "./IOptiL1Metadata.sol";

bytes32 constant ETH_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

contract OptiL1Metadata is Ownable, UseENSAuth, IOptiL1Metadata {
    using Address for address;

    error Unauthorised();
    error NotCCIP();

    event SetConfig(address indexed caller, bytes32 indexed key, bytes32 value);
    event SetTarget(address indexed caller, bytes32 indexed ensNode, bytes32 indexed opNode, bool enableWildcard);

    mapping(bytes32 => bytes32) public config;
    mapping(bytes32 => bytes32) public target;
    mapping(bytes32 => bool) public wildcardEnabled;
    string[] internal _gatewayURLs;
    address[] internal _officialResolvers;

    constructor(address _owner, bytes32 _tld) Ownable(_owner) {
        target[ETH_NODE] = _tld;
    }

    function gatewayURLs() public view returns (string[] memory) {
        return _gatewayURLs;
    }

    function officialResolvers() public view returns (address[] memory) {
        return _officialResolvers;
    }

    function configAddr(bytes32 key) public view returns (address) {
        return address(uint160(uint256(config[key])));
    }

    function set(bytes32 key, bytes32 value) public onlyOwner {
        config[key] = value;
        emit SetConfig(msg.sender, key, value);
    }

    function setTarget(bytes32 ensNode, bytes32 opNode, bool enableWildcard) public {
        if (!isAuthorised(msg.sender, ensNode)) revert Unauthorised();
        target[ensNode] = opNode;
        wildcardEnabled[ensNode] = enableWildcard;
        emit SetTarget(msg.sender, ensNode, opNode, enableWildcard);
    }

    function _processCCIPFallback(bytes memory response) private pure {
        uint256 responseLength = response.length;

        if (responseLength == 0) return;

        bytes memory emptyBytes = new bytes(responseLength);

        // Empty primitive data types
        if (keccak256(response) == keccak256(emptyBytes)) return;

        // Empty bytes memory
        if (responseLength >= 64) {
            emptyBytes[31] = 0x20;
            if (keccak256(response) == keccak256(emptyBytes)) return;
        }

        // Forward low level call return data
        assembly {
            // Return response removing length prefix (0x20)
            return(add(response, 0x20), responseLength)
        }
    }

    fallback() external payable virtual {
        unchecked {
            uint256 officialResolversLength = _officialResolvers.length;

            for (uint256 i = 1; i <= officialResolversLength; ++i) {
                (bool success, bytes memory response) =
                    _officialResolvers[officialResolversLength - i].staticcall(msg.data);
                if (success) {
                    _processCCIPFallback(response);
                }
            }

            revert();
        }
    }

    receive() external payable virtual {
        revert();
    }

    function write(address caller, bytes calldata data) external {
        if (msg.sender != configAddr(METADATA_CCIP_RESOLVER)) revert NotCCIP();
        bytes memory response = configAddr(METADATA_WRITE_RESOLVER).functionCall(abi.encodePacked(data, caller));

        // Forward low level call return data
        assembly {
            // Return response removing length prefix (0x20)
            return(add(response, 0x20), mload(response))
        }
    }

    function initParams(
        bytes32[] calldata keys,
        bytes32[] calldata values,
        string[] calldata urls,
        address[] calldata resolvers
    ) public onlyOwner {
        if (urls.length > 0) _gatewayURLs = urls;
        if (resolvers.length > 0) {
            unchecked {
                uint256 resolversLength = resolvers.length;
                for (uint256 i = 0; i < resolversLength; ++i) {
                    _officialResolvers.push(resolvers[i]);
                }
            }
        }

        unchecked {
            uint256 keysLength = keys.length;
            for (uint256 i = 0; i < keysLength; ++i) {
                set(keys[i], values[i]);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../fallback/OptiL1ResolverFallback.sol";
import "./IOptiL1ResolverMetadata.sol";

contract OptiL1ResolverMetadata is OptiL1ResolverFallback, IOptiL1ResolverMetadata {
    address public opRegistry;
    address public opBaseResolver;
    string[] internal _gatewayURLs;

    constructor(
        address _owner,
        address _writeResolver,
        address _opRegistry,
        address _opBaseResolver,
        string[] memory _urls
    ) OptiL1ResolverFallback(_owner, _writeResolver) {
        opRegistry = _opRegistry;
        opBaseResolver = _opBaseResolver;
        _gatewayURLs = _urls;
    }

    event SetOpRegistry(address indexed caller, address indexed addr);
    event SetOpBaseResolver(address indexed caller, address indexed addr);
    event SetGatewayUrls(address indexed caller, string[] urls);

    function setOpRegistry(address addr) external onlyOwner {
        opRegistry = addr;
        emit SetOpRegistry(msg.sender, addr);
    }

    function setOpBaseResolver(address addr) external onlyOwner {
        opBaseResolver = addr;
        emit SetOpBaseResolver(msg.sender, addr);
    }

    function gatewayURLs() public view returns (string[] memory) {
        return _gatewayURLs;
    }

    function setGatewayUrls(string[] calldata _urls) external onlyOwner {
        _gatewayURLs = _urls;
        emit SetGatewayUrls(msg.sender, _urls);
    }
}

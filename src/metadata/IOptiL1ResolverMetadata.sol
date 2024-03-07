// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../fallback/IOptiL1ResolverFallback.sol";

interface IOptiL1ResolverMetadata is IOptiL1ResolverFallback {
    function opRegistry() external view returns (address);
    function opBaseResolver() external view returns (address);
    function nameWrapper() external view returns (address);
    function gatewayURLs() external view returns (string[] memory);
}

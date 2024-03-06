// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOptiL1ResolverFallback {
    function officialResolvers() external view returns (address[] memory);
    function writeResolver() external view returns (address);
    function ccipResolver() external view returns (address);

    function write(address caller, bytes calldata data) external;
}

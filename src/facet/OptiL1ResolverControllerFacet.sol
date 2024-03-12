// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../ccip/UseENSAuth.sol";
import "../ccip/OptiL1ResolverStorage.sol";

bytes32 constant ENS_NODE = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

contract OptiL1ResolverControllerFacet is UseENSAuth {
    modifier authorised(bytes32 node) {
        require(isAuthorised(msg.sender, node));
        _;
    }

    event SetTarget(address indexed caller, bytes32 indexed ensNode, bytes32 indexed opNode);

    function setTarget(bytes32 ensNode, bytes32 opNode) public authorised(ensNode) {
        OptiL1ResolverStorage.Layout storage S = OptiL1ResolverStorage.layout();
        S.domainMapping[ensNode] = opNode;
        emit SetTarget(msg.sender, ensNode, opNode);
    }

    function target(bytes32 ensNode) public view returns (bytes32) {
        return OptiL1ResolverStorage.layout().domainMapping[ensNode];
    }

    event EnableWildcard(address indexed caller, bytes32 indexed ensNode, bool enabled);

    function enableWildcard(bytes32 ensNode, bool enabled) public authorised(ensNode) {
        OptiL1ResolverStorage.Layout storage S = OptiL1ResolverStorage.layout();
        S.enableWildcard[ensNode] = enabled;
        emit EnableWildcard(msg.sender, ensNode, enabled);
    }

    function isWildcardEnabled(bytes32 ensNode) public view returns (bool) {
        return OptiL1ResolverStorage.layout().enableWildcard[ensNode];
    }

    function initialize(bytes32 tldNameHash) public virtual {
        OptiL1ResolverStorage.Layout storage S = OptiL1ResolverStorage.layout();
        S.domainMapping[ENS_NODE] = tldNameHash;
        emit SetTarget(msg.sender, ENS_NODE, tldNameHash);
    }
}

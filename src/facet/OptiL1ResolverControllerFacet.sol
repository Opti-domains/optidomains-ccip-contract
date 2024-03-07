// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../ccip/UseENSAuth.sol";
import "../ccip/OptiL1ResolverStorage.sol";

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

    event EnableWildcard(address indexed caller, bytes32 indexed ensNode, bool enabled);

    function enableWildcard(bytes32 ensNode, bool enabled) public authorised(ensNode) {
        OptiL1ResolverStorage.Layout storage S = OptiL1ResolverStorage.layout();
        S.enableWildcard[ensNode] = enabled;
        emit EnableWildcard(msg.sender, ensNode, enabled);
    }
}

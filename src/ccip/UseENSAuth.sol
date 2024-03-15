// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ensdomains/ens-contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";
import "../metadata/IOptiL1ResolverMetadata.sol";
import {OPTI_L1_RESOLVER_METADATA} from "../metadata/OptiL1ResolverMetadataAddress.sol";

address constant ENS_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;

contract UseENSAuth {
    function _extractSender() internal pure returns (address sender) {
        uint256 length = msg.data.length;
        bytes memory senderRaw = msg.data[length - 20:length];
        assembly {
            sender := div(mload(add(senderRaw, 32)), exp(256, 12))
        }
    }

    function isAuthorised(address sender, bytes32 node) internal view virtual returns (bool) {
        address owner = ENS(ENS_REGISTRY).owner(node);
        address nameWrapper = IOptiL1ResolverMetadata(OPTI_L1_RESOLVER_METADATA).nameWrapper();
        if (owner == nameWrapper) {
            owner = INameWrapper(nameWrapper).ownerOf(uint256(node));
        }
        return owner == sender;
    }
}

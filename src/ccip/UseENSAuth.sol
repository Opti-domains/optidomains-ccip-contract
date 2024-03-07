// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@ensdomains/ens-contracts/registry/ENS.sol";
import "@ensdomains/ens-contracts/wrapper/INameWrapper.sol";

address constant ENS_REGISTRY = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
address constant NAME_WRAPPER_MAINNET = 0xD4416b13d2b3a9aBae7AcD5D6C2BbDBE25686401;
address constant NAME_WRAPPER_SEPOLIA = 0x0635513f179D50A207757E05759CbD106d7dFcE8;

contract UseENSAuth {
    function _extractSender() internal pure returns (address sender) {
        uint256 length = msg.data.length;
        return abi.decode(msg.data[length - 20:length], (address));
    }

    function isAuthorised(address sender, bytes32 node) internal view virtual returns (bool) {
        address owner = ENS(ENS_REGISTRY).owner(node);
        if (owner == NAME_WRAPPER_MAINNET) {
            owner = INameWrapper(NAME_WRAPPER_MAINNET).ownerOf(uint256(node));
        }
        if (owner == NAME_WRAPPER_SEPOLIA) {
            owner = INameWrapper(NAME_WRAPPER_SEPOLIA).ownerOf(uint256(node));
        }
        return owner == sender;
    }
}

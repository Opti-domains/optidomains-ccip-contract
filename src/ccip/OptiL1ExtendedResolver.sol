// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC165} from "@solidstate/contracts/interfaces/IERC165.sol";
import {IExtendedResolver} from "@ensdomains/ens-contracts/resolvers/profiles/IExtendedResolver.sol";
import {DNS_ENCODED_NAME_SELECTOR} from "./OptiL1ResolverAttester.sol";

contract OptiL1ExtendedResolver is IERC165 {
    function resolve(bytes memory name, bytes memory data) external view returns (bytes memory) {
        bytes memory forwardedData = data;

        if (name.length > 0) {
            bytes32 checksum = keccak256(abi.encodePacked(block.prevrandao, DNS_ENCODED_NAME_SELECTOR));
            forwardedData = abi.encodePacked(data, name.length, name, msg.data.length, checksum);
        }

        (bool success, bytes memory result) = address(this).staticcall(forwardedData);
        if (success) {
            return result;
        } else {
            // Revert with the reason provided by the call
            assembly {
                revert(add(result, 0x20), mload(result))
            }
        }
    }

    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
        return interfaceID == type(IExtendedResolver).interfaceId;
    }
}

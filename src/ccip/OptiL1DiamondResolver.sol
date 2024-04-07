// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DiamondResolver} from "@optidomains/modular-ens-contracts/current/diamond/DiamondResolver.sol";
import {OPTI_L1_RESOLVER_METADATA} from "../metadata/IOptiL1Metadata.sol";

contract OptiL1DiamondResolver is DiamondResolver {
    constructor(address _owner) DiamondResolver(_owner) {}

    function _initCCIPFallback() private view {
        unchecked {
            (bool success, bytes memory response) = OPTI_L1_RESOLVER_METADATA.staticcall(msg.data);

            if (success) {
                // Forward low level call return data
                assembly {
                    // Return response removing length prefix (0x20)
                    return(add(response, 0x20), mload(response))
                }
            }
        }
    }

    function getImplementation(bytes4 sig) public view virtual override returns (address implementation) {
        _initCCIPFallback();
        return super.getImplementation(sig);
    }
}

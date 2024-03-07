// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {EVMFetcher} from "@ensdomains/evm-verifier/contracts/EVMFetcher.sol";
import {IEVMVerifier} from "@ensdomains/evm-verifier/contracts/IEVMVerifier.sol";
import {IOptiL1ResolverMetadata} from "../metadata/IOptiL1ResolverMetadata.sol";
import {OPTI_L1_RESOLVER_METADATA} from "../metadata/OptiL1ResolverMetadataAddress.sol";

library OptiL1ResolverUtils {
    using EVMFetcher for EVMFetcher.EVMFetchRequest;

    function _addOperation(EVMFetcher.EVMFetchRequest memory request, uint8 op) private pure {
        uint256 commandIdx = request.commands.length - 1;
        request.commands[commandIdx] =
            request.commands[commandIdx] | (bytes32(bytes1(op)) >> (8 * request.operationIdx++));
    }

    function getOpResolverAddress(bytes32 opNode) public view returns (address predictedAddress) {
        address opBaseResolver = IOptiL1ResolverMetadata(OPTI_L1_RESOLVER_METADATA).opBaseResolver();
        bytes32 saltHash =
            keccak256(abi.encodePacked(IOptiL1ResolverMetadata(OPTI_L1_RESOLVER_METADATA).opRegistry(), opNode));
        predictedAddress = Clones.predictDeterministicAddress(opBaseResolver, saltHash, opBaseResolver);
    }

    function buildAttFetchRequest(bytes32 opNode, bytes32[] calldata slots)
        public
        view
        returns (EVMFetcher.EVMFetchRequest memory request, address target)
    {
        target = getOpResolverAddress(opNode);
        request = EVMFetcher.newFetchRequest(IEVMVerifier(address(this)), target);

        unchecked {
            uint256 slotsLength = slots.length;
            for (uint256 i = 0; i < slotsLength; ++i) {
                request.getStatic(uint256(keccak256(abi.encodePacked(opNode, slots[i]))));
            }

            if (request.commands.length > 0 && request.operationIdx < 32) {
                // Terminate last command
                _addOperation(request, 0xff);
            }
        }
    }
}

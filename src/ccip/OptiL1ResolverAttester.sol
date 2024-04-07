// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EVMFetchTarget} from "@ensdomains/evm-verifier/contracts/EVMFetchTarget.sol";
import {OptiFetchTarget} from "./OptiFetchTarget.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "@ensdomains/ens-contracts/registry/ENS.sol";
import "@optidomains/modular-ens-contracts/current/resolver/attester/OptiResolverAttesterBase.sol";
import "@optidomains/modular-ens-contracts/current/resolver/auth/OptiResolverAuth.sol";
import "../metadata/IOptiL1Metadata.sol";
import "./OptiL1ResolverUtils.sol";
import "./IOptiL1Gateway.sol";
import {Script, console2} from "forge-std/Script.sol";

// keccak256("CCIP_CALLBACK_SELECTOR")
bytes32 constant CCIP_CALLBACK_SELECTOR = (0x008005059b29fe32430d77b550e3fd6faed6e319156c99f488cac9c10006b476);

// keccak256("DNS_ENCODED_NAME_SELECTOR")
bytes32 constant DNS_ENCODED_NAME_SELECTOR = (0x1bc8709fa4e9a9a9d0c17c26a82f1a28d50ebe5469b3220f3e4253c914e56bc1);

bytes32 constant RESOLVER_STORAGE_NAMESPACE = keccak256("optidomains.resolver.storage");

error FreeMemoryOccupied();
error CCIPSlotOverflow();
error PleaseWriteOnL2();
error InvalidSlot();

contract OptiL1ResolverAttester is OptiResolverAttesterBase, OptiResolverAuth {
    using EVMFetcher for EVMFetcher.EVMFetchRequest;
    using Address for address;

    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);
    error HeaderMustIncludeNode();

    function _storageSlotCommon(bytes32 schema, address recipient, bytes memory header)
        private
        pure
        returns (bytes32 s)
    {
        if (header.length < 32) revert HeaderMustIncludeNode();

        bytes memory packed = abi.encodePacked(header, schema, recipient, RESOLVER_STORAGE_NAMESPACE);
        uint256 packedLength = packed.length;

        assembly {
            // keccak256 hash omiting node
            s := keccak256(add(packed, 0x40), sub(packedLength, 0x20))
        }
    }

    function _isCCIPCallback() private view returns (bool result) {
        // Verify the following format: [funcsig[4], ..., len[32], keccak256(prevrandao, CCIP_CALLBACK_SELECTOR)[32]]
        assembly {
            // Load calldata size
            let calldataLength := calldatasize()

            // Check minimum calldata length requirement
            if gt(calldataLength, 67) {
                // Calculate checksum: keccak256(block.prevrandao, CCIP_CALLBACK_SELECTOR)
                mstore(0x80, prevrandao()) // Load block.prevrandao value
                mstore(0xA0, CCIP_CALLBACK_SELECTOR) // Append CCIP_CALLBACK_SELECTOR after prevrandao
                let checksum := keccak256(0x80, 0x40) // Compute keccak256 hash of combined values

                // Load the calldata checksum (last 32 bytes of calldata)
                let calldataChecksum := calldataload(sub(calldataLength, 0x20))

                // Compare checksums and return result
                result := eq(checksum, calldataChecksum)
            }
        }
    }

    function _initCCIPCallback() private pure {
        assembly {
            // Allocate calldata pointer to the first slot
            mstore(0xC0, calldataload(sub(calldatasize(), 0x40)))
        }
    }

    function _readCCIPCallback() private pure returns (bytes32 slot, bytes memory data) {
        unchecked {
            uint256 p;
            uint256 dataLength;

            assembly {
                // Load calldata pointer
                p := mload(0xC0)

                // First value is the slot
                slot := calldataload(p)

                // Second value is the data length
                dataLength := calldataload(add(p, 0x20))

                // Move pointer to the start of data
                p := add(p, 0x40)
            }

            data = msg.data[p:p + dataLength];

            assembly {
                // Move new pointer to the next calldata
                mstore(0xC0, add(p, dataLength))
            }
        }
    }

    function _initCCIPFetch() private view returns (bool isInitial) {
        bool isOccupied = false;
        assembly {
            // If 0x80 is marked with prevrandao then it is initialized
            if iszero(eq(mload(0x80), prevrandao())) {
                // Mark as the first initialization
                isInitial := true

                if iszero(eq(mload(0x40), 0x80)) { isOccupied := true }

                // Mark 0x80 with prevrandao to indicate that ccip fetch has been initialized
                mstore(0x80, prevrandao())

                // Move free memory pointer to slot 35
                mstore(0x40, 0x4E0)
            }
        }

        if (isOccupied) revert FreeMemoryOccupied();
    }

    function _appendCCIPslot(bytes32 slot) private pure {
        console2.log("Go to here");

        unchecked {
            uint256 length;
            assembly {
                // Fetch length from the first memory pointer
                length := add(mload(0xC0), 1)
            }

            if (length > 32) {
                revert CCIPSlotOverflow();
            }

            assembly {
                // Increase length of array
                mstore(0xC0, length)

                // Push slot to the end of array
                mstore(add(0xC0, mul(length, 32)), slot)
            }
        }

        console2.log("Go out here");
    }

    event CCIPSlot(bytes32 slot);

    function _finalizeCCIP() private view {
        unchecked {
            bytes32[] memory slots;
            assembly {
                slots := 0xC0
            }

            bytes32 ensNode = bytes32(msg.data[4:36]);
            bytes memory dnsEncodedName;

            // Try to fetch dns-encoded name
            if (msg.sender == address(this)) {
                assembly {
                    // Load calldata size
                    let calldataLength := calldatasize()

                    // Check minimum calldata length requirement
                    if gt(calldataLength, 67) {
                        // Calculate checksum: keccak256(block.prevrandao, DNS_ENCODED_NAME_SELECTOR)
                        mstore(0x80, prevrandao()) // Load block.prevrandao value
                        mstore(0xA0, DNS_ENCODED_NAME_SELECTOR) // Append DNS_ENCODED_NAME_SELECTOR after prevrandao
                        let checksum := keccak256(0x80, 0x40) // Compute keccak256 hash of combined values

                        // Load the calldata checksum (last 32 bytes of calldata)
                        let calldataChecksum := calldataload(sub(calldataLength, 0x20))

                        // Compare checksums and return result
                        if eq(checksum, calldataChecksum) {
                            // Allocate new memory for DNS encoded name
                            dnsEncodedName := mload(0x40)

                            // Get offset equal to the length of typical calldata
                            let offset := calldataload(sub(calldataLength, 0x40))

                            // [length][...dnsEncodedName...]
                            let dataLength := add(calldataload(offset), 0x20)

                            // Copy calldata to memory starting at ptr
                            calldatacopy(dnsEncodedName, offset, dataLength)

                            // Move the free memory pointer by the amount we copied over
                            mstore(0x40, add(dnsEncodedName, dataLength))
                        }
                    }
                }
            }

            revert OffchainLookup(
                address(this),
                IOptiL1Metadata(OPTI_L1_RESOLVER_METADATA).gatewayURLs(),
                abi.encodeCall(IOptiL1Gateway.getAttestations, (ensNode, slots, dnsEncodedName)),
                OptiFetchTarget.ccipAttCallback.selector,
                abi.encode(ensNode, slots, msg.data)
            );
        }
    }

    function _read(bytes32 schema, address recipient, bytes memory header)
        internal
        view
        virtual
        override
        returns (bytes memory result)
    {
        bool isCallback;
        uint256 dbg;
        assembly {
            // If length > 32 then it's a callback pointer position because
            // Minimum pointer position = 4 (funcsig) + 32 (node) = 36
            isCallback := gt(mload(0xC0), 32)
            dbg := mload(0xC0)
        }

        console2.log("Start here");

        bytes32 s = _storageSlotCommon(schema, recipient, header);

        console2.log("Get common storage", dbg);

        if (isCallback) {
            console2.log("this is callback");

            (bytes32 slot, bytes memory data) = _readCCIPCallback();
            if (slot != s) {
                revert InvalidSlot();
            }
            result = data;
        } else {
            _appendCCIPslot(s);
        }
    }

    function _writeFallback() internal {
        // This function will return globally
        IOptiL1Metadata(OPTI_L1_RESOLVER_METADATA).write(msg.sender, msg.data);

        // Force end the transaction
        assembly {
            return(0, 0)
        }
    }

    function _write(bytes32, address, uint64, bool, bytes memory, bytes memory)
        internal
        virtual
        override
        returns (bytes32)
    {
        _writeFallback();
    }

    function _revoke(bytes32, address, bytes memory) internal virtual override returns (bytes32) {
        _writeFallback();
    }

    function _ccipBefore() internal view virtual override returns (bool isInitial) {
        isInitial = _initCCIPFetch();
        bool isCallback = _isCCIPCallback();

        if (isInitial && isCallback) _initCCIPCallback();
    }

    function _ccipAfter() internal view virtual override {
        bool isCallback;
        assembly {
            // If length > 32 then it's a callback pointer position because
            // Minimum pointer position = 4 (funcsig) + 32 (node) = 36
            isCallback := gt(mload(0xC0), 32)
        }

        if (!isCallback) _finalizeCCIP();
    }

    function _isAuthorised(bytes32) internal view virtual override returns (bool) {
        return true;
    }
}

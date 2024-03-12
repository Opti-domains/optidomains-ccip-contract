// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./IOptiL1ResolverFallback.sol";

contract OptiL1ResolverFallback is OwnableUpgradeable, IOptiL1ResolverFallback {
    using Address for address;

    error NotCCIP();

    address[] internal _officialResolvers;
    address public writeResolver;
    address public ccipResolver;

    event AppendOfficialResolver(address indexed caller, address indexed addr);
    event PopOfficialResolver(address indexed caller, address indexed addr);
    event SetWriteResolver(address indexed caller, address indexed addr);
    event SetCCIPResolver(address indexed caller, address indexed addr);

    function initialize(address owner) public initializer {
        __Ownable_init(owner);
    }

    function officialResolvers() public view returns (address[] memory) {
        return _officialResolvers;
    }

    function appendOfficialResolver(address addr) external onlyOwner {
        _officialResolvers.push(addr);
        emit AppendOfficialResolver(msg.sender, addr);
    }

    function popOfficialResolver() external onlyOwner {
        emit PopOfficialResolver(msg.sender, _officialResolvers[_officialResolvers.length - 1]);
        _officialResolvers.pop();
    }

    function setWriteResolver(address addr) external onlyOwner {
        writeResolver = addr;
        emit SetWriteResolver(msg.sender, addr);
    }

    function setCCIPResolver(address addr) external onlyOwner {
        ccipResolver = addr;
        emit SetCCIPResolver(msg.sender, addr);
    }

    function _processCCIPFallback(bytes memory response) private pure {
        uint256 responseLength = response.length;

        if (responseLength == 0) return;

        bytes memory emptyBytes = new bytes(responseLength);

        // Empty primitive data types
        if (keccak256(response) == keccak256(emptyBytes)) return;

        // Empty bytes memory
        if (responseLength >= 64) {
            emptyBytes[31] = 0x20;
            if (keccak256(response) == keccak256(emptyBytes)) return;
        }

        // Forward low level call return data
        assembly {
            // Return response removing length prefix (0x20)
            return(add(response, 0x20), responseLength)
        }
    }

    fallback() external payable virtual {
        unchecked {
            uint256 officialResolversLength = _officialResolvers.length;

            for (uint256 i = 1; i <= officialResolversLength; ++i) {
                (bool success, bytes memory response) =
                    _officialResolvers[officialResolversLength - i].staticcall(msg.data);
                if (success) {
                    _processCCIPFallback(response);
                }
            }

            revert();
        }
    }

    receive() external payable virtual {
        revert();
    }

    function write(address caller, bytes calldata data) external {
        if (msg.sender != ccipResolver) revert NotCCIP();
        bytes memory response = writeResolver.functionCall(abi.encodePacked(data, caller));

        // Forward low level call return data
        assembly {
            // Return response removing length prefix (0x20)
            return(add(response, 0x20), mload(response))
        }
    }
}

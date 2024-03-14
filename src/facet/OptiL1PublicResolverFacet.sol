// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    DNSResolver,
    InterfaceResolver,
    NameResolver,
    PubkeyResolver,
    TextResolver,
    ERC165BaseInternal,
    IABIResolver,
    IAddrResolver,
    IAddressResolver,
    IContentHashResolver,
    IDNSRecordResolver,
    IDNSZoneResolver,
    IInterfaceResolver,
    INameResolver,
    IPubkeyResolver,
    ITextResolver,
    IExtendedResolver
} from "@optidomains/modular-ens-contracts/current/resolver/public-resolver/PublicResolverFacet.sol";
import {UseRegistry} from "@optidomains/modular-ens-contracts/current/diamond/UseRegistry.sol";
import {OptiL1ResolverAttester} from "../ccip/OptiL1ResolverAttester.sol";
import {OptiL1ExtendedResolver} from "../ccip/OptiL1ExtendedResolver.sol";
import {UseENSAuth} from "../ccip/UseENSAuth.sol";

contract OptiL1PublicResolverFacet is
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    DNSResolver,
    InterfaceResolver,
    NameResolver,
    PubkeyResolver,
    TextResolver,
    OptiL1ExtendedResolver,
    OptiL1ResolverAttester,
    ERC165BaseInternal
{
    function initialize() public virtual {
        _setSupportsInterface(type(IABIResolver).interfaceId, true);
        _setSupportsInterface(type(IAddrResolver).interfaceId, true);
        _setSupportsInterface(type(IAddressResolver).interfaceId, true);
        _setSupportsInterface(type(IContentHashResolver).interfaceId, true);
        _setSupportsInterface(type(IDNSRecordResolver).interfaceId, true);
        _setSupportsInterface(type(IDNSZoneResolver).interfaceId, true);
        _setSupportsInterface(type(IInterfaceResolver).interfaceId, true);
        _setSupportsInterface(type(INameResolver).interfaceId, true);
        _setSupportsInterface(type(IPubkeyResolver).interfaceId, true);
        _setSupportsInterface(type(ITextResolver).interfaceId, true);
        _setSupportsInterface(type(IExtendedResolver).interfaceId, true);

        // Set UseRegistry to ENS registry
        bytes32 slot = UseRegistry.STORAGE_SLOT;
        assembly {
            sstore(slot, 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e)
        }
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(
            ABIResolver,
            AddrResolver,
            ContentHashResolver,
            DNSResolver,
            InterfaceResolver,
            NameResolver,
            PubkeyResolver,
            TextResolver,
            OptiL1ExtendedResolver
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}

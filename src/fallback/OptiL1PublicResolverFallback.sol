// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@ensdomains/ens-contracts/resolvers/PublicResolver.sol";
import "../ccip/UseENSAuth.sol";

contract OptiL1PublicResolverFallback is
    Multicallable,
    ABIResolver,
    AddrResolver,
    ContentHashResolver,
    DNSResolver,
    InterfaceResolver,
    NameResolver,
    PubkeyResolver,
    TextResolver,
    UseENSAuth
{
    error NotOptiL1ResolverFallback();

    ENS immutable ens;
    INameWrapper immutable nameWrapper;
    address immutable optiL1ResolverFallback;

    constructor(ENS _ens, INameWrapper _nameWrapper, address _optiL1ResolverFallback) {
        ens = _ens;
        nameWrapper = _nameWrapper;
        optiL1ResolverFallback = _optiL1ResolverFallback;
    }

    function isAuthorised(bytes32 node) internal view override returns (bool) {
        if (msg.sender != optiL1ResolverFallback) revert NotOptiL1ResolverFallback();
        return isAuthorised(_extractSender(), node);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(
            Multicallable,
            ABIResolver,
            AddrResolver,
            ContentHashResolver,
            DNSResolver,
            InterfaceResolver,
            NameResolver,
            PubkeyResolver,
            TextResolver
        )
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}

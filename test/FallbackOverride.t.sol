// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "test/setup/DeployCCIP.sol";
import {NameEncoder} from "@ensdomains/ens-contracts/utils/NameEncoder.sol";

bytes32 constant NICK_ETH = 0x05a67c0ee82964c4f7394cdd47fee7f4d9503a23c09c38341779ea012afe6e00;
address constant NICK_OWNER = 0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5;
address constant NOT_NICK_OWNER = 0x53d86698a2475b2D6b59D3d3485070aE6e9F68b0;

contract FallbackExistingTest is Test, DeployCCIP {
    function setUp() public virtual override {
        uint256 forkId = vm.createFork(vm.envString("FORK_URL"), 19_400_000);
        vm.selectFork(forkId);

        super.setUp();
    }

    function testAddr(address a) public {
        vm.assume(a != address(0));

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setAddr(NICK_ETH, a);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setAddr(NICK_ETH, a);
        vm.stopPrank();

        assertEq(resolver.addr(NICK_ETH), a);
    }

    function testAddrNonETH(uint256 coinType, bytes memory a) public {
        vm.assume(bytes(a).length > 0);
        vm.assume(coinType != 60);

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setAddr(NICK_ETH, coinType, a);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setAddr(NICK_ETH, coinType, a);
        vm.stopPrank();

        assertEq(resolver.addr(NICK_ETH, coinType), a);
    }

    function testTextTwitter(string memory s) public {
        vm.assume(bytes(s).length > 0);

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setText(NICK_ETH, "com.twitter", s);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setText(NICK_ETH, "com.twitter", s);
        vm.stopPrank();

        // com.twitter
        assertEq(resolver.text(NICK_ETH, "com.twitter"), s);
    }

    function testTextNew() public {
        string memory s = "xxx";
        vm.assume(bytes(s).length > 0);

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setText(NICK_ETH, "newrecord", s);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setText(NICK_ETH, "newrecord", s);
        vm.stopPrank();

        // newrecord
        assertEq(resolver.text(NICK_ETH, "newrecord"), s);
    }

    function testContentHash(bytes memory b) public {
        vm.assume(b.length > 0);

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setContenthash(NICK_ETH, b);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setContenthash(NICK_ETH, b);
        vm.stopPrank();

        assertEq(resolver.contenthash(NICK_ETH), b);
    }

    function testName(string memory s) public {
        vm.assume(bytes(s).length > 0);

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setName(NICK_ETH, s);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setName(NICK_ETH, s);
        vm.stopPrank();

        assertEq(resolver.name(NICK_ETH), s);
    }

    function testPubkey(bytes32 x, bytes32 y) public {
        vm.assume(x > 0 || y > 0);

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setPubkey(NICK_ETH, x, y);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setPubkey(NICK_ETH, x, y);
        vm.stopPrank();

        (bytes32 xx, bytes32 yy) = resolver.pubkey(NICK_ETH);

        assertEq(xx, x);
        assertEq(yy, y);
    }

    function testABI(bytes calldata data) public {
        vm.assume(bytes(data).length > 0);

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setABI(NICK_ETH, 4, data);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setABI(NICK_ETH, 4, data);
        vm.stopPrank();

        {
            (uint256 contentType, bytes memory result) = resolver.ABI(NICK_ETH, 0xffffffff);
            assertEq(contentType, 4);
            assertEq(result, data);
        }

        bytes memory data2 = abi.encode(data);

        vm.prank(NICK_OWNER);
        resolver.setABI(NICK_ETH, 2, data2);
        vm.stopPrank();

        {
            (uint256 contentType, bytes memory result) = resolver.ABI(NICK_ETH, 0xffffffff);
            assertEq(contentType, 2);
            assertEq(result, data2);
        }

        {
            (uint256 contentType, bytes memory result) = resolver.ABI(NICK_ETH, 0x5);
            assertEq(contentType, 4);
            assertEq(result, data);
        }
    }

    function testInterface(bytes4 interfaceID, address implementer) public {
        vm.assume(implementer != address(0));

        vm.prank(NOT_NICK_OWNER);
        vm.expectRevert();
        resolver.setInterface(NICK_ETH, interfaceID, implementer);
        vm.stopPrank();

        vm.prank(NICK_OWNER);
        resolver.setInterface(NICK_ETH, interfaceID, implementer);
        vm.stopPrank();

        assertEq(resolver.interfaceImplementer(NICK_ETH, interfaceID), implementer);
    }

    function testInterfaceEIP165() public {
        vm.prank(NICK_OWNER);
        resolver.setAddr(NICK_ETH, address(resolver));
        vm.stopPrank();

        assertEq(resolver.interfaceImplementer(NICK_ETH, 0x3b3b57de), address(resolver));
    }

    function testInterfaceEIP165PubResolver() public {
        // Similar to above but this case we setAddr on the ENS official PublicResolver instead
        address PUBLIC_RESOLVER = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;

        vm.prank(NICK_OWNER);
        OptiL1PublicResolverFallback(PUBLIC_RESOLVER).setAddr(NICK_ETH, PUBLIC_RESOLVER);
        vm.stopPrank();

        assertEq(resolver.interfaceImplementer(NICK_ETH, 0x3b3b57de), PUBLIC_RESOLVER);
    }

    function _dnsBasic() internal {
        bytes memory arec = hex"016103657468000001000100000e10000401020304";
        bytes memory b1rec = hex"016203657468000001000100000e10000402030405";
        bytes memory b2rec = hex"016203657468000001000100000e10000403040506";
        bytes memory soarec =
            hex"03657468000006000100015180003a036e733106657468646e730378797a000a686f73746d6173746572057465737431036574680078492cbd00003d0400000708001baf8000003840";
        bytes memory rec = bytes.concat(arec, b1rec, b2rec, soarec);

        vm.prank(NICK_OWNER);
        // OptiL1PublicResolverFallback(0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41).setDNSRecords(NICK_ETH, rec);
        resolver.setDNSRecords(NICK_ETH, rec);
        vm.stopPrank();

        (bytes memory dnsName,) = NameEncoder.dnsEncodeName("a.eth");

        assertEq(
            resolver.dnsRecord(NICK_ETH, keccak256(abi.encodePacked(dnsName)), 1),
            hex"016103657468000001000100000e10000401020304"
        );
    }

    function _dnsUpdateExisting() internal {}

    function _dnsKeepTrack() internal {}

    function _dnsSingleRecord() internal {}

    function testDns() public {
        _dnsBasic();
        _dnsUpdateExisting();
        _dnsKeepTrack();
        _dnsSingleRecord();
    }

    function testDnsZone() public {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "test/setup/DeployCCIP.sol";

bytes32 constant NICK_ETH = 0x05a67c0ee82964c4f7394cdd47fee7f4d9503a23c09c38341779ea012afe6e00;

contract FallbackExistingTest is Test, DeployCCIP {
    function setUp() public virtual override {
        uint256 forkId = vm.createFork(vm.envString("FORK_URL"), 19_400_000);
        vm.selectFork(forkId);

        super.setUp();
    }

    function testAddr() public {
        assertEq(resolver.addr(NICK_ETH), 0xb8c2C29ee19D8307cb7255e1Cd9CbDE883A267d5);
    }

    function testText() public {
        // com.twitter
        assertEq(resolver.text(NICK_ETH, "com.twitter"), "nicksdjohnson");

        // com.github
        assertEq(resolver.text(NICK_ETH, "com.github"), "arachnid");

        // com.discord
        assertEq(resolver.text(NICK_ETH, "com.discord"), "nickjohnson#0001");

        // org.telegram
        assertEq(resolver.text(NICK_ETH, "org.telegram"), "nicksdjohnson");

        // com.reddit
        assertEq(resolver.text(NICK_ETH, "com.reddit"), "nickjohnson");

        // email
        assertEq(resolver.text(NICK_ETH, "email"), "arachnid@notdot.net");

        // description
        assertEq(
            resolver.text(NICK_ETH, "description"),
            "Lead developer of ENS & Ethereum Foundation alum. Certified rat tickler. he/him."
        );

        // url
        assertEq(resolver.text(NICK_ETH, "url"), "https://ens.domains/");

        // avatar
        assertEq(
            resolver.text(NICK_ETH, "avatar"),
            "eip155:1/erc1155:0x495f947276749ce646f68ac8c248420045cb7b5e/8112316025873927737505937898915153732580103913704334048512380490797008551937"
        );
    }

    function testContentHash() public {
        assertEq(
            resolver.contenthash(NICK_ETH),
            hex"e5010172002408011220066e20f72cc583d769bc8df5fedff24942b3b8941e827f023d306bdc7aecf5ac"
        );
    }
}

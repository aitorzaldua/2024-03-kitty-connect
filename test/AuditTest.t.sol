// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test} from "./../lib/forge-std/src/Test.sol";
import {console2} from "./../lib/forge-std/src/console2.sol";

import {KittyConnect} from "./../src/KittyConnect.sol";
import {KittyBridge, KittyBridgeBase, Client} from "../src/KittyBridge.sol";

contract AuditTest is Test {
    ////////////////////
    //    USERS    /////
    ////////////////////

    address user = makeAddr("user");
    address newOwner = makeAddr("newOwner");
    address shopOwner0 = makeAddr("shopOwner0");
    address shopOwner1 = makeAddr("shopOwner1");
    address KittyConnectOwner = makeAddr("KittyConnectOwner");

    ////////////////////////
    //    DATA/CONS    /////
    ////////////////////////
    // address[] initShopPartners;
    address router = 0x0BF3dE8c5D3e8A2B34D2BEeB17ABfCeBaf363A59;
    address link = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    ////////////////////
    // CONTRACTS   /////
    ////////////////////
    KittyConnect kittyConnect;

    ////////////////////
    // DEPLOY       /////
    ////////////////////

    function setUp() external {
        address[] memory shopPartners = new address[](2);
        shopPartners[0] = 0x38007F01af2145F77417afA52f16D6063656ce08;
        shopPartners[1] = 0x37563586Dc0F57eB7AB9199dC808906938bba42F;

        vm.prank(KittyConnectOwner);
        kittyConnect = new KittyConnect(shopPartners, router, link);
    }

    function test_setUp() external view {
        console2.log("user :        ", address(user));
        console2.log("newOwner :    ", address(newOwner));
        console2.log("shopOwner0:   ", address(shopOwner0));
        console2.log("shopOwner1:   ", address(shopOwner1));
        console2.log("kittyConnect: ", address(kittyConnect));

        address partnerA = kittyConnect.getKittyShopAtIdx(0);
        address partnerB = kittyConnect.getKittyShopAtIdx(1);
        assertEq(partnerA, address(shopOwner0));
        assertEq(partnerB, address(shopOwner1));
        assert(kittyConnect.getIsKittyPartnerShop(partnerA) == true);
    }

    //////////////////////////////
    // TESTS  FUNCIONALES     ///
    /////////////////////////////

    function test_mintCatToOwner() public {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";

        vm.prank(shopOwner0);
        kittyConnect.mintCatToNewOwner(address(user), catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);

        uint256 tokenId = kittyConnect.getTokenCounter() - 1;
        assertEq(kittyConnect.ownerOf(tokenId), address(user));

        KittyConnect.CatInfo memory catInfo = kittyConnect.getCatInfo(tokenId);
        assertEq(catInfo.catName, "Meowdy");
    }

    function test_userTransferNFTOwnership() external {
        test_mintCatToOwner();
        KittyConnect.CatInfo memory catInfo = kittyConnect.getCatInfo(0);
        console2.log("name: ", catInfo.catName);

        vm.prank(user);
        kittyConnect.transferFrom(user, newOwner, 0);
        // kittyConnect.safeTransferFrom(user, newOwner, 0);

        console2.log("new Owner: ", kittyConnect.ownerOf(0));
    }
}

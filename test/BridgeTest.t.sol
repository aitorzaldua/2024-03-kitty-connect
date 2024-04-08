// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console} from "./../lib/forge-std/src/Test.sol";
import {DeployKittyConnect} from "../script/DeployKittyConnect.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {KittyConnect} from "../src/KittyConnect.sol";
import {KittyBridge, KittyBridgeBase, Client} from "../src/KittyBridge.sol";

contract BridgeTest is Test {
    //////////////////////
    //   USERS       ////
    ////////////////////
    address kittyConnectOwner;
    address partnerA;
    address partnerB;
    address user;
    address ethUsdPriceFeed;
    address sender = makeAddr("sender");

    ////////////////////
    //  CONTRACTS   ///
    ///////////////////
    KittyConnect kittyConnect;
    KittyBridge kittyBridge;
    HelperConfig helperConfig;
    /**
     * NetworkConfig trae los datos de las networks Sepolia, Fuji o Anvil
     * Es un struct tal que:
     *  address[] initShopPartners => siempre los mismos
     *     address router             => La address del contrato de intermediacion
     *     address link               => La address del token LINK
     *     uint64 chainSelector       => el selector de la chain origen
     *     uint64 otherChainSelector  => el selector de la chain destino
     */
    HelperConfig.NetworkConfig networkConfig;

    //////////////////
    //   EVENTS   ////
    //////////////////
    event ShopPartnerAdded(address partner);
    event CatMinted(uint256 tokenId, string catIpfsHash);
    event TokensRedeemedForVetVisit(uint256 tokenId, uint256 amount, string remarks);
    event CatTransferredToNewOwner(address prevOwner, address newOwner, uint256 tokenId);

    //////////////////
    //   SETUP    ////
    //////////////////
    function setUp() external {
        /*
         * Deploy KittyConnect usando el script de deploy 
         * Se despliega con un LINK balance de 8 ETH.
         * Recibe los datos de networkConfig como Anvil.
         */
        DeployKittyConnect deployer = new DeployKittyConnect();

        (kittyConnect, helperConfig) = deployer.run();
        networkConfig = helperConfig.getNetworkConfig();

        /**
         * Se configuran los usuarios creados con los datos
         * Del deploy
         */
        kittyConnectOwner = kittyConnect.getKittyConnectOwner();
        partnerA = kittyConnect.getKittyShopAtIdx(0);
        partnerB = kittyConnect.getKittyShopAtIdx(1);
        kittyBridge = KittyBridge(kittyConnect.getKittyBridge());
        user = makeAddr("user");
    }

    //////////////////
    //   TESTS    ////
    //////////////////
    function test_anvilNetwork() external {
        address mockLinkToken = 0x90193C961A926261B756D1E5bb255e67ff9498A1;

        assertEq(kittyBridge.getKittyConnectAddr(), address(kittyConnect));
        assertEq(kittyBridge.getGaslimit(), 400000);
        assertEq(kittyBridge.getLinkToken(), mockLinkToken);
    }

    function test_gasConsumed() external {
        // NFT a transferir
        bytes memory data = abi.encode(
            makeAddr("catOwner"),
            "meowdy",
            "ragdoll",
            "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62",
            block.timestamp,
            partnerA
        );
    }
}

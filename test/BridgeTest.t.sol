// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console} from "./../lib/forge-std/src/Test.sol";
import {DeployKittyConnect} from "../script/DeployKittyConnect.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {KittyConnect} from "../src/KittyConnect.sol";
import {KittyBridge, KittyBridgeBase, Client} from "../src/KittyBridge.sol";

contract BridgeTest is Test {}

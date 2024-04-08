## [H1] Inconsistent behaviour of functions could leads to a malpractice

### Severity

High Risk

### Date Modified

April 1st, 2024

### Summary

We need to look at 3 functions:

1. mintCatToNewOwner() => `require(!s_isKittyShop[catOwner], "KittyConnect__CatOwnerCantBeShopPartner");`
2. addShop() => No require
3. safeTransferFrom() => No require

So on the one hand it says "Cat Owner Cannot Be Shop Partner", but on the other hand it is possible to transfer an NFT to an account and then the addShop() function doesn't check if the shop has NFTs.

Any user can store NFTs first and then become a shop without the protocol checking the status.

### Vulnerability Details (PoC)

Check this foundry test showing the funcitons behaviour:

```
function test_differentBehaivourBetweenFunctions() external {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        /**
         * mintCatToNewOwner() doesn´t allow to mint to a shop
         */
        vm.prank(shopOwner0);
        vm.expectRevert("KittyConnect__CatOwnerCantBeShopPartner");
        kittyConnect.mintCatToNewOwner(address(shopOwner1), catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);
        /**
         * It is allowed to transfer the NFT to a shop
         */
        // 1. Add NFT to user
        vm.prank(shopOwner0);
        kittyConnect.mintCatToNewOwner(address(user), catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);
        uint256 tokenId = kittyConnect.getTokenCounter() - 1;
        assertEq(kittyConnect.ownerOf(tokenId), address(user));

        // 2. User send the NFT to the shop. No problem!
        vm.prank(user);
        kittyConnect.approve(address(shopOwner0), tokenId);
        vm.prank(shopOwner0);
        kittyConnect.safeTransferFrom(user, shopOwner0, 0);
        assertEq(kittyConnect.ownerOf(tokenId), address(shopOwner0));

        /**
         * Users with NFTs can become shops
         */
        // 1. Add NFT to user
        vm.prank(shopOwner0);
        kittyConnect.mintCatToNewOwner(address(user), catImageIpfsHash, "Meowdy2", "Ragdoll2", block.timestamp);
        tokenId = kittyConnect.getTokenCounter() - 1;
        assertEq(kittyConnect.ownerOf(tokenId), address(user));

        // 2. Convert user into a shop. No problem!
        vm.prank(KittyConnectOwner);
        kittyConnect.addShop(user);
        assertEq(kittyConnect.getKittyShopAtIdx(2), user);
    }
```

```
➜  2024-03-kitty-connect git:(main) ✗ forge test --mt test_differentBehaivourBetweenFunctions
[⠊] Compiling...
[⠒] Compiling 1 files with 0.8.19
[⠘] Solc 0.8.19 finished in 1.64s
Compiler run successful!

Ran 1 test for test/AuditTest.t.sol:AuditTest
[PASS] test_differentBehaivourBetweenFunctions() (gas: 687515)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.36ms (227.08µs CPU time)

Ran 1 test suite in 146.46ms (1.36ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2024-03-kitty-connect git:(main) ✗
```

As we can see, there is different ways to surpass the requirement `KittyConnect__CatOwnerCantBeShopPartner`

### Impact

Any protocol must have clear rules and reasons for behaving in a certain way. If there is a requirement that says that it is not possible to attach an NFT to a shop, all functions should have the same requirement.

Since this is not the case, it is a HIGH risk vulnerability.

### Tools Used

Foundry

### Recommendations

It is advisable to review the entire protocol to ensure that the requirement is met, by adding the appropriate requires.
For example, for safeTransferFrom():

```
function safeTransferFrom(address currCatOwner, address newOwner, uint256 tokenId, bytes memory data)
        public
        override
        onlyShopPartner
    {
        require(_ownerOf(tokenId) == currCatOwner, "KittyConnect__NotKittyOwner");

        require(getApproved(tokenId) == newOwner, "KittyConnect__NewOwnerNotApproved");

        /**********  ADD THIS *****************/
        require(!s_isKittyShop[newOwner], "KittyConnect__CatOwnerCantBeShopPartner");

        _updateOwnershipInfo(currCatOwner, newOwner, tokenId);

        emit CatTransferredToNewOwner(currCatOwner, newOwner, tokenId);
        _safeTransfer(currCatOwner, newOwner, tokenId, data);
    }
```

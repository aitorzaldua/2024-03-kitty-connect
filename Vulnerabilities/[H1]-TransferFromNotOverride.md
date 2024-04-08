## [H1] Protocol Override safeTransferFrom() but forgot transferFrom()

### Severity

High Risk

### Date Modified

April 1st, 2024

### Summary

The idea of the protocol is to only allow validated shops to transfer NFTs, so it overrides the `safeTransferFrom()` function by adding the modifier `onlyShopPartner`.
But the protocol forgot to override `transferFrom()`, so any NFT owner can transfer the NFT outside the protocol, unexpected behaivour, and `_updateOwnershipInfo()` is not called, database inconsistency.

### Vulnerability Details (PoC)

Check this Foundry test:

```
function test_userTransferNFTOwnership() external {
        string memory catImageIpfsHash = "ipfs://QmbxwGgBGrNdXPm84kqYskmcMT3jrzBN8LzQjixvkz4c62";
        // 1. Mint NFT
        vm.prank(shopOwner0);
        kittyConnect.mintCatToNewOwner(address(user), catImageIpfsHash, "Meowdy", "Ragdoll", block.timestamp);
        uint256 tokenId = kittyConnect.getTokenCounter() - 1;
        assertEq(kittyConnect.ownerOf(tokenId), address(user));

        // 2. User Transfer the NFT without using a shop
        vm.prank(user);
        kittyConnect.transferFrom(user, newOwner, tokenId);
        assertEq(kittyConnect.ownerOf(tokenId), address(newOwner));
    }
```

```
➜  2024-03-kitty-connect git:(main) ✗ forge test --mt test_userTransferNFTOwnership
[⠊] Compiling...
[⠒] Compiling 1 files with 0.8.19
[⠑] Solc 0.8.19 finished in 1.62s
Compiler run successful!

Ran 1 test for test/AuditTest.t.sol:AuditTest
[PASS] test_userTransferNFTOwnership() (gas: 294657)
Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 1.01ms (95.17µs CPU time)

Ran 1 test suite in 132.82ms (1.01ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
➜  2024-03-kitty-connect git:(main) ✗
```

### Impact

This is a HIGH vulnerability because the protocol totally lost control over the information and functions.

1. Different behaivour as expected.
2. Database inconsistency.

### Tools Used

Foundry

### Recommendations

The protocol must override transferFrom() and check every option of the ERC721 standard.

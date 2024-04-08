## [H1] Access Control issue due to lack of transfer the ownership function

### Severity

High Risk

### Date Modified

April 1st, 2024

### Summary

The protocol implements 3 types of users, 2 of them, onlyKittyConnectOwner and onlyKittyBridge, with administrative tasks such as

- Add new shops
- Coin the NFT in the target chain.
  As the protocol doesn't implement a transfer of ownership of both profiles, if the current addresses are in danger, there is no way to transfer them to secure the protocol.

### Vulnerability Details (PoC)

View these functions in the Open Zeppelin ownership contract:

```
function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
}


function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
}

```

Both are vital functions to keep the access control side of the protocol secure.

### Impact

If the protocol suffers a phishing or similar attack, the protocol is at HIGH risk, so this issue must be addressed.

### Tools Used

Foundry

### Recommendations

The standards are there to protect the network and the protocols, so implementing our own deploys instead of a well-known, well-tested standard contract should be done with extra care.

The recommendation is to implement the Open Zeppelin Ownership contract in `KittyConnect` as the protocol already does in `KittyBridge`.

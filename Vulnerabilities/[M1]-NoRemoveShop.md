## [H1] Different issues with not being able to remove item from array.

### Severity

Medium Risk

### Date Modified

April 1st, 2024

### Summary

It is not possible to design a protocol that adds elements to an array but does not have the option to remove them.

1. An array is an element that can grow infinitely creating gas problems if it is large enough.
2. A shop can become a malicious agent that needs to be removed so that it does not continue with bad practices.

### Vulnerability Details

In this case it is not necessary to create a PoC as it is a design vulnerability.

It is simply necessary to build a function that removes elements from the array `s_kittyShops`.

### Impact

This is a very serious design problem but, since adding elements to the array is in the hands of the protocol owner, it is a MEDIUM RISK vulnerability.

### Tools Used

Foundry

### Recommendations

Implement a function that removes elements from the array `s_kittyShops`.

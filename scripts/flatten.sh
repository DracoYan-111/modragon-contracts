#!/usr/bin/env bash

# TODO Read the contract name
# echo Which contract do you want to flatten \(e.g. Greeter\)?
# read contract

# Remove an existing flattened contract
rm -rf ${contract}_flattened.sol

# Flatten the contract
forge flatten ./contracts/src/${contract}.sol > ${contract}_flattened.sol

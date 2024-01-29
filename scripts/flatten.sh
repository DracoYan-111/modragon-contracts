#!/usr/bin/env bash

# TODO Read the contract name
# Read the contract name
echo 📄Which contract do you want to deploy \(e.g. Contract path\)?
read contract

contract_name="${contract##*/}"
echo "👍Contract name extracted: => $contract_name <="

# Remove an existing flattened contract
rm -rf ./contracts/src/flattened/${contract_name}_flattened.sol

# Flatten the contract
forge flatten ./contracts/src/${contract}.sol > ./flattened/${contract_name}_flattened.sol
#/Users/zhumaomao.eth/Desktop/myCode/solidity/modragon-contracts/contracts/src/modragon/MoDragonContract.sol
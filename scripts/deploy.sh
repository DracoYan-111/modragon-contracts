#!/usr/bin/env bash

# Read the RPC URL
echo Enter your RPC URL \(script uses silent mode\;\ i.e. not printed to the console\):
read -s rpc

# Read the private key
echo Enter your private key \(script uses silent mode\;\ i.e. not printed to the console\):
read -s key

# Read the contract name
echo 📄Which contract do you want to deploy \(e.g. Contract path\)?
read contract

contract_name="${contract##*/}"
echo "👍Contract name extracted: => $contract_name <="

# TODO Read the constructor arguments
echo 🚶Enter the constructor arguments separated by spaces \(e.g. parameter set\):
read -ra args

if [ -z "$args" ]
then
  forge create -i ./contracts/src/${contract}.sol:${contract_name} --rpc-url $rpc --private-key $key
else
  forge create -i ./contracts/src/${contract}.sol:${contract_name} --rpc-url $rpc --private-key $key --constructor-args ${args[@]}
fi

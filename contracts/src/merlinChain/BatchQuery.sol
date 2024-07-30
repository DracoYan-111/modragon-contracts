// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

contract BatchQuery {
    struct Call {
        address target;
        bytes callData;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    /**
     * @dev Returns the block hash for the given block number
     * @param calls An array of Call structs
     * @return returnData An array of bytes containing the responses
     */
    function aggregateView(Call[] calldata calls) external view returns (bytes[] memory returnData) {
        uint256 length = calls.length;
        returnData = new bytes[](length);
        Call calldata call;
        for (uint256 i = 0; i < length; ) {
            bool success;
            call = calls[i];
            (success, returnData[i]) = call.target.staticcall(call.callData);
            require(success, "BatchQuery: call failed");
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns the block hash for the given block number
     * @param blockNumber The block number
     */
    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    /// @dev Returns the block number
    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = block.number;
    }

    /// @dev Returns the block coinbase
    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    /// @dev Returns the block difficulty
    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.prevrandao;
    }

    /// @dev Returns the block gas limit
    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    /// @dev Returns the block timestamp
    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    /// @dev Returns the (ETH) balance of a given address
    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    /// @dev Returns the block hash of the last block
    function getLastBlockHash() public view returns (bytes32 blockHash) {
        unchecked {
            blockHash = blockhash(block.number - 1);
        }
    }

    /**
     * @dev Gets the base fee of the given block
     * @dev Can revert if the BASEFEE opcode is not implemented by the given chain
     */
    function getBasefee() public view returns (uint256 basefee) {
        basefee = block.basefee;
    }

    /// @dev Returns the chain id
    function getChainId() public view returns (uint256 chainid) {
        chainid = block.chainid;
    }
}

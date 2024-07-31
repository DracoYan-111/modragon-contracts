var Web3 = require('web3');

const web3 = new Web3("https://testnet-rpc.merlinchain.io");

// 查询合约ABI
const abi = [
  {
    inputs: [
      {
        components: [
          {
            internalType: "address",
            name: "target",
            type: "address",
          },
          {
            internalType: "bytes",
            name: "callData",
            type: "bytes",
          },
        ],
        internalType: "struct BatchQuery.Call[]",
        name: "calls",
        type: "tuple[]",
      },
    ],
    name: "aggregateView",
    outputs: [
      {
        internalType: "bytes[]",
        name: "returnData",
        type: "bytes[]",
      },
    ],
    stateMutability: "view",
    type: "function",
  }
];

// 代币合约ABI
const tokenAbi = [
  {
    constant: true,
    inputs: [{ name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "", type: "uint256" }],
    payable: false,
    stateMutability: "view",
    type: "function",
  },
];

// 查询合约地址
const contractAddress = "0x98aE12B19d7c195237eAd37e21B8cb6d211Fc87D";
// 需要查询的代币合约地址
const tokenContractAddress = "0xa1e8312144A51aDc8413082D2703c86E0cAA04f7";

// 创建查询合约实例
const contract = new web3.eth.Contract(abi, contractAddress);

async function getUserListBalance(addressList) {
  // 构造合约中的Call数组
  const calls = addressList.map((address) => {
    const callData = web3.eth.abi.encodeFunctionCall({
      name: 'balanceOf',
      type: 'function',
      inputs: [{
        type: 'address',
        name: 'account'
      }]
    }, [address]);

    return { target: tokenContractAddress, callData };
  });

  try {
    // 获取返回的数据
    const response = await contract.methods.aggregateView(calls).call();
    // 转化为可读数据
    const decimalArray = response.map((hex) => {
      // 将每个 hex 字符串转为十进制
      return web3.utils.toBN(hex).toString(10);
    });

    console.log(decimalArray);
  } catch (error) {
    console.error("Error calling aggregateView:", error);
  }
}

// 需要查询的用户地址
const addresses = [
  "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003",
  "0x3e8B6e286f78B13C35E11d567935c3aFEECb9003",
];
getUserListBalance(addresses);
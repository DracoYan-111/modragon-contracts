import fs from "fs";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

// ============== Building a Tree ==============


// const data = [
//   {
//     "evmAddress": "0x5aA9b7c23BE84EAd087E0Cab17CF0F748fd97155",
//     "burnCount": 225,
//     "blockNumber": "11464896",
//     "rank": 1,
//     "merl": 2300
//   },
//   {
//     "evmAddress": "0x5A91b16525dfe5168020d133c26F2b422Fe4AB7f",
//     "burnCount": 212,
//     "blockNumber": "11464822",
//     "rank": 2,
//     "merl": 1500
//   },
//   {
//     "evmAddress": "0xa84a2058E657d594A65136fC8F9afF73375B23B3",
//     "burnCount": 170,
//     "blockNumber": "11464873",
//     "rank": 3,
//     "merl": 1200
//   },
//   {
//     "evmAddress": "0xE56507AA1f25588c88aA44d52A1dC29E6dAd3322",
//     "burnCount": 125,
//     "blockNumber": "11462851",
//     "rank": 4,
//     "merl": 1000
//   },
//   {
//     "evmAddress": "0xCeE5964470608eB0A4356d79a7B0e3Fef4A747b1",
//     "burnCount": 106,
//     "blockNumber": "11459976",
//     "rank": 5,
//     "merl": 1000
//   },
//   {
//     "evmAddress": "0x3d7ec10585F110a2C394557e22238d9Fd6BD02d6",
//     "burnCount": 100,
//     "blockNumber": "11420271",
//     "rank": 6,
//     "merl": 600
//   },
//   {
//     "evmAddress": "0x3F124A5ADb22C8026b9ac2DFa601C05A990C00d0",
//     "burnCount": 100,
//     "blockNumber": "11420556",
//     "rank": 7,
//     "merl": 600
//   },
//   {
//     "evmAddress": "0x2bF014B126a3c83e6C89d905c369beAAAA61F53A",
//     "burnCount": 100,
//     "blockNumber": "11420659",
//     "rank": 8,
//     "merl": 600
//   },
//   {
//     "evmAddress": "0xc240771D40f966064Ac38e077227B942e07d10C2",
//     "burnCount": 73,
//     "blockNumber": "11438011",
//     "rank": 9,
//     "merl": 600
//   },
//   {
//     "evmAddress": "0x0980f6bd9510Da2a26728B9626ea074e231514dE",
//     "burnCount": 65,
//     "blockNumber": "11464910",
//     "rank": 10,
//     "merl": 600
//   },
//   {
//     "evmAddress": "0x34604665A7d32286Fd54FD2B68511F1D3Ec0a2f5",
//     "burnCount": 58,
//     "blockNumber": "11454570",
//     "rank": 11,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x151Ce88A86751E760caA684A646a2006182825e9",
//     "burnCount": 53,
//     "blockNumber": "11411260",
//     "rank": 12,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x7ec73E839267cEd9A2576dA410fdeC77ffE4957C",
//     "burnCount": 52,
//     "blockNumber": "11464075",
//     "rank": 13,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x70fAE893D36d7fAE6aC97cAb681b70b5F110DA08",
//     "burnCount": 52,
//     "blockNumber": "11464359",
//     "rank": 14,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x5B0a9791BA4227ce4946Ac4785e74b7F50A5ae85",
//     "burnCount": 51,
//     "blockNumber": "11461037",
//     "rank": 15,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x0A5e33Fb4265812CDb50B3479A9c06a97c2CbDD3",
//     "burnCount": 48,
//     "blockNumber": "11460038",
//     "rank": 16,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x166D2F940DcEE40cC25B909B196Fd62e04A8019f",
//     "burnCount": 48,
//     "blockNumber": "11464424",
//     "rank": 17,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x557c24411F3560C3b3A76C655d36704604b31e55",
//     "burnCount": 41,
//     "blockNumber": "11461378",
//     "rank": 18,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x815Bb152a62789659714BAC0625105374DEbD497",
//     "burnCount": 40,
//     "blockNumber": "11313697",
//     "rank": 19,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0xe9B37833665740839452478ee9AC4E7488Ce2C19",
//     "burnCount": 40,
//     "blockNumber": "11396016",
//     "rank": 20,
//     "merl": 400
//   },
//   {
//     "evmAddress": "0x8181BcC153C63f5E8173a1383B2cE187579bcF26",
//     "burnCount": 38,
//     "blockNumber": "11464230",
//     "rank": 21,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0xA73bD91973e0221d222F26A2ff6aCF86208aef57",
//     "burnCount": 32,
//     "blockNumber": "11423133",
//     "rank": 22,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0x4449d2E3d4F337909fE8866D402607A92f9259a6",
//     "burnCount": 31,
//     "blockNumber": "11449817",
//     "rank": 23,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0x4Fd0F632688e08281AD8D93eFB91F45d40f375ad",
//     "burnCount": 25,
//     "blockNumber": "11464916",
//     "rank": 24,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0x2735aBCa115FD291b583169Cc88a10118C8Ac321",
//     "burnCount": 23,
//     "blockNumber": "11349095",
//     "rank": 25,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0xEf499e6d40EE6A7B5b1fF7F23B568DE0d05Ee2Df",
//     "burnCount": 22,
//     "blockNumber": "11464868",
//     "rank": 26,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0x393696103Bd43d244334Dd74632c1fD21b72BdC7",
//     "burnCount": 21,
//     "blockNumber": "11462751",
//     "rank": 27,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0x3F64001FD810Ae8165EA5727980EA733E1d0c378",
//     "burnCount": 21,
//     "blockNumber": "11464814",
//     "rank": 28,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0xB755EB807585b86E7aFf341BfCc0843Effad9aee",
//     "burnCount": 20,
//     "blockNumber": "11397706",
//     "rank": 29,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0xc3EE9425E8f923f5F3Ad542840Cc4D99788B33c7",
//     "burnCount": 20,
//     "blockNumber": "11459348",
//     "rank": 30,
//     "merl": 300
//   },
//   {
//     "evmAddress": "0x244DB33E1bdF01b6510956af1DCA8072528410F8",
//     "burnCount": 17,
//     "blockNumber": "11464788",
//     "rank": 31,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0xf35038A72900db4C02AB6d5924465022b4Bc1E48",
//     "burnCount": 16,
//     "blockNumber": "11428215",
//     "rank": 32,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0x6a6AA64CB2834Bf93599285c3bd2b0f5D60F6695",
//     "burnCount": 16,
//     "blockNumber": "11464884",
//     "rank": 33,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0xf7A81B454D9FbE4cf76CCFa4409E4aE22D2EDC3f",
//     "burnCount": 15,
//     "blockNumber": "11464886",
//     "rank": 34,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0x00271C26f3aa2d88ea6238629c5Ee153E8033162",
//     "burnCount": 13,
//     "blockNumber": "11291944",
//     "rank": 35,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0xf4bA3871705260051A01558Ab3FF5Cf5828089A8",
//     "burnCount": 13,
//     "blockNumber": "11291993",
//     "rank": 36,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0x91D1313c5b07A29Fc5abC80343391c3faE61fe0B",
//     "burnCount": 11,
//     "blockNumber": "11463704",
//     "rank": 37,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0xc26f7381D255528faB3e94304100831754139f93",
//     "burnCount": 11,
//     "blockNumber": "11464878",
//     "rank": 38,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0xbE0030B71e9edED2B417F2a459c0CE24a4e8089A",
//     "burnCount": 11,
//     "blockNumber": "11464911",
//     "rank": 39,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0x445043Bfe692b5c76CE0F05744A25fD3CB8D4925",
//     "burnCount": 10,
//     "blockNumber": "11283777",
//     "rank": 40,
//     "merl": 200
//   },
//   {
//     "evmAddress": "0xc7a0D1231CC3bA9597cA82808F1BF52D297AAb76",
//     "burnCount": 10,
//     "blockNumber": "11395989",
//     "rank": 41,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0x256a49317a6e9B228A712a1Becf2B0071Bbc41e8",
//     "burnCount": 10,
//     "blockNumber": "11396782",
//     "rank": 42,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0xe22e95446c841F30CB9ef0E27F861EE14c441757",
//     "burnCount": 10,
//     "blockNumber": "11406423",
//     "rank": 43,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0xda60eE22d014302478964CCB4B74738C4Dd723ff",
//     "burnCount": 10,
//     "blockNumber": "11459998",
//     "rank": 44,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0x54842415da670B29436557aF434B975A3138D7f3",
//     "burnCount": 9,
//     "blockNumber": "11362404",
//     "rank": 45,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0xF2fC4B500A3f0d5B96f9Ce37F41669F1F616cE63",
//     "burnCount": 9,
//     "blockNumber": "11460681",
//     "rank": 46,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0xaD4BeD1dB40b34ABaEb986D327310343BAEAac87",
//     "burnCount": 9,
//     "blockNumber": "11462688",
//     "rank": 47,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0xd9Dc7315e86d9Df2A848c6903B80fBF303d0d3A0",
//     "burnCount": 9,
//     "blockNumber": "11463557",
//     "rank": 48,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0xd69C6eA26974DB7b121548F511d8008266466F9e",
//     "burnCount": 7,
//     "blockNumber": "11364453",
//     "rank": 49,
//     "merl": 100
//   },
//   {
//     "evmAddress": "0x65ddf76939B5eeDdd1577EC2B56bda73c87074f9",
//     "burnCount": 7,
//     "blockNumber": "11457761",
//     "rank": 50,
//     "merl": 100
//   }
// ]
// ;
// const res = [];
// for (const item of data) {
//   res.push([item.rank,item.evmAddress, item.merl.toString() + "000000000000000000"]);
// }
// console.log(res);


const values = require("./merlinRewardMerkleData.json");

const tree = StandardMerkleTree.of(values, ["uint256", "address", "uint256"]);

const treeDataWithRoot = {
  root: tree.root,
  tree: tree.dump()
};

// write to file
require("fs").writeFileSync("./tree.json", JSON.stringify(treeDataWithRoot));


// ============== Obtaining a Proof ==============
const trees = StandardMerkleTree.load(JSON.parse(fs.readFileSync("./tree.json", "utf8")).tree);

const checkUserAddress = '0xa84a2058E657d594A65136fC8F9afF73375B23B3'
for (const [i, v] of trees.entries()) {
  if (v[1] === checkUserAddress) {
    const proof = trees.getProof(i);
    console.log('Value:', v);
    console.log('Proof:', proof);
  }
}


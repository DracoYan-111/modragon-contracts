// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Vm} from "forge-std/Vm.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import {eMDBL} from "../../../src/mdblLBP/mdblStake/eMDBL.sol";
import {TestToken} from "../../../src/testToken/TestToken.sol";

contract eMDBLTest is Test {
    eMDBL public eMDBLTestAddr;

    TestToken public testToken1;

    address public initialOwner;
    uint256 internal constant WAD = 1e18;

    uint256 public constant INITIALOWNERKEY = 0xde9be858da4a475276426320d5e9262ecfc3ba460bfac56360bfa6c4c28b4ee0;
    uint256 public constant SIGNERPRIVATEKEY = 0xdf57089febbacf7ba0bc227dafbffa9fc08a93fdc68e1e42411a14efcf23656e;

    bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address to,uint256 value,uint256 nonce,uint256 deadline)");
    struct RedemptionRequestExt {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
        uint256 endTime;
        bool completed;
        bool cancelled;
        uint256[5] __gap;
    }

    /**
     * @dev Sets up the test.
     */
    function setUp() external {
        initialOwner = vm.addr(INITIALOWNERKEY);

        testToken1 = new TestToken(initialOwner, "TestToken");

        address eMDBLTestAddress = address(new eMDBL());

        bytes memory data = abi.encodeCall(eMDBL.initialize, (initialOwner, testToken1,vm.addr(SIGNERPRIVATEKEY)));
        address proxy = address(new ERC1967Proxy(eMDBLTestAddress, data));

        eMDBLTestAddr = eMDBL(proxy);
    }

    function testSwapEMDBL() public {
        mintTestToken();
        vm.startPrank(initialOwner, initialOwner);

        eMDBLTestAddr.swapEMDBL(100 ether);

        assertGt(eMDBLTestAddr.balanceOf(initialOwner), 0);
    }

    function testStartRedemption() public {
        testSwapEMDBL();
        vm.startPrank(initialOwner, initialOwner);

        eMDBLTestAddr.startRedemption(100 ether, 15 days);
        assertGt(eMDBLTestAddr.getRedemptionRequestArray(initialOwner).length, 0);
    }

    function testCancelRedemption() external {
        testStartRedemption();

        vm.startPrank(initialOwner, initialOwner);

        eMDBL.RedemptionRequestExt[] memory s = eMDBLTestAddr.getRedemptionRequestArray(initialOwner);
        eMDBLTestAddr.cancelRedemption(s.length - 1);

        s = eMDBLTestAddr.getRedemptionRequestArray(initialOwner);
        assertEq(s[s.length - 1].completed, true);
        assertEq(s[s.length - 1].cancelled, true);
        assertEq(eMDBLTestAddr.getUserCanRedemptionBalance(initialOwner), eMDBLTestAddr.balanceOf(initialOwner));
    }

    function testFail_CompleteRedemption() external {
        testStartRedemption();

        vm.startPrank(initialOwner, initialOwner);

        eMDBL.RedemptionRequestExt[] memory s = eMDBLTestAddr.getRedemptionRequestArray(initialOwner);
        eMDBLTestAddr.completeRedemption(s.length - 1);
    }

    function testCompleteRedemption15Days() external {
        testStartRedemption();

        vm.startPrank(initialOwner, initialOwner);

        eMDBL.RedemptionRequestExt[] memory s = eMDBLTestAddr.getRedemptionRequestArray(initialOwner);

        vm.warp(block.timestamp + 16 days);

        eMDBLTestAddr.completeRedemption(s.length - 1);

        assertEq(testToken1.balanceOf(initialOwner), _mulWad(100 ether, 0.25 ether));
    }

    function testCancelAndComplete() external {
        testStartRedemption();

        vm.startPrank(initialOwner, initialOwner);
        vm.warp(block.timestamp + 10 days);

        eMDBL.RedemptionRequestExt[] memory s = eMDBLTestAddr.getRedemptionRequestArray(initialOwner);
        eMDBLTestAddr.cancelRedemption(s.length - 1);

        s = eMDBLTestAddr.getRedemptionRequestArray(initialOwner);
        assertEq(eMDBLTestAddr.getUserCanRedemptionBalance(initialOwner), eMDBLTestAddr.balanceOf(initialOwner));

        testStartRedemption();

        s = eMDBLTestAddr.getRedemptionRequestArray(initialOwner);

        vm.warp(block.timestamp + 16 days);

        eMDBLTestAddr.completeRedemption(s.length - 1);

        assertEq(testToken1.balanceOf(initialOwner), _mulWad(100 ether, 0.25 ether));
    }

    function testPermitMint() public {
        uint256 deadline =  1712399874;
        uint256 amount = 100 ether;

        bytes32 typedDataHash = getTypedDataHash(deadline, amount);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(SIGNERPRIVATEKEY, typedDataHash);
        assertEq(eMDBLTestAddr.balanceOf(initialOwner), 0);
        console.logAddress(vm.addr(SIGNERPRIVATEKEY));
        console.logAddress(0x657A6F007d5233488fD3B475D27a73E08BFa12eD);
        console.logUint(amount);
        console.logUint(deadline);
        console.logUint(v);
        console.logBytes32(r);
        console.logBytes32(s);

        // eMDBLTestAddr.permitMint(vm.addr(SIGNERPRIVATEKEY),initialOwner,amount,deadline,v,r,s);

        // assertEq(eMDBLTestAddr.balanceOf(initialOwner), amount);
    }

    function getTypedDataHash(uint256 deadline, uint256 amount) private pure returns (bytes32 typedDataHash) {
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                0x657A6F007d5233488fD3B475D27a73E08BFa12eD,
                amount,
                0,
                deadline
            )
        );

        typedDataHash = MessageHashUtils.toTypedDataHash(
            0x374b76eebcb0c767d82df79c02a0dfd8c5f23e4783a6d2140e538cfe1a1ec72c,
            structHash
        );
    }

    function mintTestToken() public {
        vm.startPrank(initialOwner, initialOwner);

        testToken1.mint(initialOwner, 100 ether);
        testToken1.approve(address(eMDBLTestAddr), 100 ether);
    }

    function _mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                mstore(0x00, 0xbac65e5b) // `MulWadFailed()`.
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }
}

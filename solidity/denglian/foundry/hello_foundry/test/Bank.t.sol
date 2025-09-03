// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

// 为 Bank 合约 编写测试。

// 测试Case 包含：

// 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
// 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
// 检查只有管理员可取款，其他人不可以取款。

contract BankTest is Test {
    Bank public bank;

    address public a = makeAddr("a");
    address public b = makeAddr("b");
    address public c = makeAddr("c");
    address public d = makeAddr("d");
    uint256 public constant INITIAL_BALANCE = 100 * 10 ** 18;

    function setUp() public {
        // 部署 Bank
        bank = new Bank();

        vm.deal(a, INITIAL_BALANCE);
        vm.deal(b, INITIAL_BALANCE);
        vm.deal(c, INITIAL_BALANCE);
        vm.deal(d, INITIAL_BALANCE);
    }

    // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
    // forge test --match-test test_Deposit -vv
    // [⠊] Compiling...
    // No files changed, compilation skipped

    // Ran 1 test for test/Bank.t.sol:BankTest
    // [PASS] test_Deposit() (gas: 77900)
    // Logs:
    // user a balance: 100000000000000000000
    // bank balance: 0
    // user a balance: 99000000000000000000
    // bank balance: 1000000000000000000

    // Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 13.36ms (2.63ms CPU time)

    // Ran 1 test suite in 344.41ms (13.36ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
    function test_Deposit() public {
        console2.log("user a balance:", a.balance);
        console2.log("bank balance:", address(bank).balance);

        vm.prank(a); // 模拟用户A发起交易
        uint256 transferAmount = 1 ether; // 转账金额
        (bool success, ) = address(bank).call{value: transferAmount}("");
        require(success, "transfer fail");

        console2.log("user a balance:", a.balance);
        console2.log("bank balance:", address(bank).balance);

        assertEq(address(bank).balance, transferAmount);
        assertEq(a.balance, INITIAL_BALANCE - transferAmount);
    }

    // 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
    // forge test --match-test test_MultipleUsersDeposit -vv
    // [⠊] Compiling...
    // [⠊] Compiling 1 files with Solc 0.8.25
    // [⠒] Solc 0.8.25 finished in 974.25ms
    // Compiler run successful!

    // Ran 1 test for test/Bank.t.sol:BankTest
    // [PASS] test_MultipleUsersDeposit() (gas: 297481)
    // Logs:
    // after user a deposit: 10000000000000000000
    // Rankings index: 0 ,addr: 0x8e8161A194dB181783245dFaE95dBc632eB958Cb

    // after user b deposit: 20000000000000000000
    // Rankings index: 0 ,addr: 0x6a724DF99DD9d5c56C07ead5837c75A150C878c3
    // Rankings index: 1 ,addr: 0x8e8161A194dB181783245dFaE95dBc632eB958Cb

    // after user c deposit: 30000000000000000000
    // Rankings index: 0 ,addr: 0xF16587770D49A85bB497c74F065a213E2E165AA3
    // Rankings index: 1 ,addr: 0x6a724DF99DD9d5c56C07ead5837c75A150C878c3
    // Rankings index: 2 ,addr: 0x8e8161A194dB181783245dFaE95dBc632eB958Cb

    // after user d deposit: 40000000000000000000
    // Rankings index: 0 ,addr: 0x167A1FCb46229aB8c5e327B0cFec64E1ce113C5C
    // Rankings index: 1 ,addr: 0xF16587770D49A85bB497c74F065a213E2E165AA3
    // Rankings index: 2 ,addr: 0x6a724DF99DD9d5c56C07ead5837c75A150C878c3

    // after user a deposit: 50000000000000000000
    // Rankings index: 0 ,addr: 0x8e8161A194dB181783245dFaE95dBc632eB958Cb
    // Rankings index: 1 ,addr: 0x167A1FCb46229aB8c5e327B0cFec64E1ce113C5C
    // Rankings index: 2 ,addr: 0xF16587770D49A85bB497c74F065a213E2E165AA3

    // Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 8.10ms (1.89ms CPU time)

    // Ran 1 test suite in 362.96ms (8.10ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
    function test_MultipleUsersDeposit() public {
        // a用户充值 10 ether
        vm.startPrank(a);
        uint256 depositAmount = 10 * 10 ** 18;
        console2.log("after user a deposit:", depositAmount);
        (bool success, ) = address(bank).call{value: depositAmount}("");
        require(success, "transfer fail");
        for (uint256 i = 0; i < bank.RANKINGS_LEN(); i++) {
            address addr = bank.rankings(i);
            if (addr != address(0)) {
                console2.log("Rankings index:", i, ",addr:", addr);
            }
        }
        // 只有a用户充值，第一名肯定是a
        assertEq(bank.rankings(0), a);
        console2.log("");
        vm.stopPrank();

        // b用户充值 20 ether
        vm.startPrank(b);
        depositAmount = 20 * 10 ** 18;
        console2.log("after user b deposit:", depositAmount);
        (success, ) = address(bank).call{value: depositAmount}("");
        require(success, "transfer fail");
        for (uint256 i = 0; i < bank.RANKINGS_LEN(); i++) {
            address addr = bank.rankings(i);
            if (addr != address(0)) {
                console2.log("Rankings index:", i, ",addr:", addr);
            }
        }
        // 累计充值:
        // a: 10
        // b: 20
        assertEq(bank.rankings(0), b);
        assertEq(bank.rankings(1), a);
        console2.log("");
        vm.stopPrank();

        // c用户充值 30 ether
        vm.startPrank(c);
        depositAmount = 30 * 10 ** 18;
        console2.log("after user c deposit:", depositAmount);
        (success, ) = address(bank).call{value: depositAmount}("");
        require(success, "transfer fail");
        for (uint256 i = 0; i < bank.RANKINGS_LEN(); i++) {
            address addr = bank.rankings(i);
            if (addr != address(0)) {
                console2.log("Rankings index:", i, ",addr:", addr);
            }
        }
        // 累计充值:
        // a: 10
        // b: 20
        // c: 30
        assertEq(bank.rankings(0), c);
        assertEq(bank.rankings(1), b);
        assertEq(bank.rankings(2), a);
        console2.log("");
        vm.stopPrank();

        // d用户充值 40 ether
        vm.startPrank(d);
        depositAmount = 40 * 10 ** 18;
        console2.log("after user d deposit:", depositAmount);
        (success, ) = address(bank).call{value: depositAmount}("");
        require(success, "transfer fail");
        for (uint256 i = 0; i < bank.RANKINGS_LEN(); i++) {
            address addr = bank.rankings(i);
            if (addr != address(0)) {
                console2.log("Rankings index:", i, ",addr:", addr);
            }
        }
        // 累计充值:
        // a: 10
        // b: 20
        // c: 30
        // d: 40
        assertEq(bank.rankings(0), d);
        assertEq(bank.rankings(1), c);
        assertEq(bank.rankings(2), b);
        console2.log("");
        vm.stopPrank();

        // a用户又充值 50 ether
        vm.startPrank(a);
        depositAmount = 50 * 10 ** 18;
        console2.log("after user a deposit:", depositAmount);
        (success, ) = address(bank).call{value: depositAmount}("");
        require(success, "transfer fail");
        for (uint256 i = 0; i < bank.RANKINGS_LEN(); i++) {
            address addr = bank.rankings(i);
            if (addr != address(0)) {
                console2.log("Rankings index:", i, ",addr:", addr);
            }
        }
        // 累计充值:
        // a: 60
        // b: 20
        // c: 30
        // d: 40
        assertEq(bank.rankings(0), a);
        assertEq(bank.rankings(1), d);
        assertEq(bank.rankings(2), c);
        console2.log("");
        vm.stopPrank();
    }

    // 检查只有管理员可取款，其他人不可以取款。
    // forge test --match-test test_WithdrawByNonOwner -vv
    // [⠊] Compiling...
    // [⠊] Compiling 2 files with Solc 0.8.25
    // [⠒] Solc 0.8.25 finished in 932.72ms
    // Compiler run successful!

    // Ran 1 test for test/Bank.t.sol:BankTest
    // [PASS] test_WithdrawByNonOwner() (gas: 70196)
    // Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 6.71ms (692.46µs CPU time)

    // Ran 1 test suite in 306.51ms (6.71ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
    function test_WithdrawByNonOwner() public {
        // 非管理员账户尝试提取资金

        // 先充值
        vm.prank(a);
        uint256 transferAmount = 10 ether; // 转账金额
        (bool success, ) = address(bank).call{value: transferAmount}("");
        require(success, "transfer fail");

        // vm.prank(a); 只会影响紧接着的下一条外部合约调用，不会一直持续生效。
        // 需要在每次希望用 a 的身份发起合约调用前都加一次 vm.prank(a);，否则后续调用不会自动继承上一次的 prank 身份。
        vm.prank(a);
        vm.expectRevert("only owner can withdraw");
        bank.withdraw(1 ether);
    }
}

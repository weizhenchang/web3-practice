// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {TokenBank, MyERC20} from "../src/TokenBank.sol";

// 为 Bank 合约 编写测试。

// 测试Case 包含：

// 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
// 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
// 检查只有管理员可取款，其他人不可以取款。

contract TokenBankTest is Test {
    TokenBank public tokenBank;
    MyERC20 public testToken;

    address public a = makeAddr("a");
    address public b = makeAddr("b");
    uint256 public constant INITIAL_BALANCE = 100 * 10 ** 18;

    function setUp() public {
        // 部署测试代币
        testToken = new MyERC20("TestToken", "TT");

        // 部署 TokenBank
        tokenBank = new TokenBank(address(testToken));

        // 给测试账户转账
        testToken.transfer(a, INITIAL_BALANCE);
        testToken.transfer(b, INITIAL_BALANCE);
    }

    // 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
    // forge test --match-test test_Deposit -vvvv
    // [⠊] Compiling...
    // No files changed, compilation skipped

    // Ran 1 test for test/TokenBank.t.sol:TokenBankTest
    // [PASS] test_Deposit() (gas: 104706)
    // Traces:
    // [124606] TokenBankTest::test_Deposit()
    //     ├─ [0] VM::startPrank(a: [0x8e8161A194dB181783245dFaE95dBc632eB958Cb])
    //     │   └─ ← [Return]
    //     ├─ [24739] MyERC20::approve(TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 10000000000000000000 [1e19])
    //     │   ├─ emit Approval(owner: a: [0x8e8161A194dB181783245dFaE95dBc632eB958Cb], spender: TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 10000000000000000000 [1e19])
    //     │   └─ ← [Return] true
    //     ├─ [79595] TokenBank::deposit(10000000000000000000 [1e19])
    //     │   ├─ [30865] MyERC20::transferFrom(a: [0x8e8161A194dB181783245dFaE95dBc632eB958Cb], TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], 10000000000000000000 [1e19])
    //     │   │   ├─ emit Transfer(from: a: [0x8e8161A194dB181783245dFaE95dBc632eB958Cb], to: TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b], value: 10000000000000000000 [1e19])
    //     │   │   └─ ← [Return] true
    //     │   ├─ emit Deposit(user: a: [0x8e8161A194dB181783245dFaE95dBc632eB958Cb], amount: 10000000000000000000 [1e19])
    //     │   └─ ← [Stop]
    //     ├─ [516] TokenBank::balanceOf(a: [0x8e8161A194dB181783245dFaE95dBc632eB958Cb]) [staticcall]
    //     │   └─ ← [Return] 10000000000000000000 [1e19]
    //     ├─ [328] TokenBank::totalDeposits() [staticcall]
    //     │   └─ ← [Return] 10000000000000000000 [1e19]
    //     ├─ [562] MyERC20::balanceOf(TokenBank: [0x2e234DAe75C793f67A35089C9d99245E1C58470b]) [staticcall]
    //     │   └─ ← [Return] 10000000000000000000 [1e19]
    //     ├─ [562] MyERC20::balanceOf(a: [0x8e8161A194dB181783245dFaE95dBc632eB958Cb]) [staticcall]
    //     │   └─ ← [Return] 90000000000000000000 [9e19]
    //     ├─ [0] VM::stopPrank()
    //     │   └─ ← [Return]
    //     └─ ← [Stop]

    // Suite result: ok. 1 passed; 0 failed; 0 skipped; finished in 7.66ms (1.13ms CPU time)

    // Ran 1 test suite in 335.72ms (7.66ms CPU time): 1 tests passed, 0 failed, 0 skipped (1 total tests)
    // function test_Deposit() public {
    //     uint256 depositAmount = 10 * 10 ** 18;

    //     // 切换到 a 账户
    //     vm.startPrank(a);

    //     // 授权 TokenBank 使用代币
    //     testToken.approve(address(tokenBank), depositAmount);

    //     // 执行存款
    //     tokenBank.deposit(depositAmount);

    //     // 验证余额
    //     assertEq(tokenBank.balanceOf(a), depositAmount);
    //     assertEq(tokenBank.totalDeposits(), depositAmount);
    //     assertEq(testToken.balanceOf(address(tokenBank)), depositAmount);
    //     assertEq(testToken.balanceOf(a), INITIAL_BALANCE - depositAmount);

    //     vm.stopPrank();
    // }

    function test_Withdraw() public {
        uint256 depositAmount = 10 * 10 ** 18;
        uint256 withdrawAmount = 1 * 10 ** 18;

        // 切换到 a 账户
        vm.startPrank(a);

        // 先存款
        testToken.approve(address(tokenBank), depositAmount);
        tokenBank.deposit(depositAmount);

        // 记录提款前的余额
        uint256 balanceBefore = testToken.balanceOf(a);

        // 执行提款
        tokenBank.withdraw(withdrawAmount);

        // 验证余额
        assertEq(tokenBank.balanceOf(a), depositAmount - withdrawAmount);
        assertEq(tokenBank.totalDeposits(), depositAmount - withdrawAmount);
        assertEq(testToken.balanceOf(a), balanceBefore + withdrawAmount);

        vm.stopPrank();
    }

    function test_Mixed() public {
        uint256 aDeposit = 1 * 10 ** 18;
        uint256 bDeposit = 2 * 10 ** 18;

        // a 存款
        vm.startPrank(a);
        testToken.approve(address(tokenBank), aDeposit);
        tokenBank.deposit(aDeposit);
        vm.stopPrank();

        // b 存款
        vm.startPrank(b);
        testToken.approve(address(tokenBank), bDeposit);
        tokenBank.deposit(bDeposit);
        vm.stopPrank();

        // 验证总存款
        assertEq(tokenBank.totalDeposits(), aDeposit + bDeposit);

        // 验证各个用户的余额
        assertEq(tokenBank.balanceOf(a), aDeposit);
        assertEq(tokenBank.balanceOf(b), bDeposit);
    }
}

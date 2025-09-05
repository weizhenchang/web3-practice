// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// 编写 NFTMarket 合约：

// 支持设定任意ERC20价格来上架NFT
// 支持支付ERC20购买指定的NFT
// 要求测试内容：

// 上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
// 购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
// 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
// 「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓

import {Test, console2} from "forge-std/Test.sol";
import {NFTMarket} from "../src/NftMarket.sol";
import {MyERC20} from "../src/MyERC20V2.sol";
import {MyNFTCollection} from "../src/MyERC721.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    MyERC20 public tokenContract;
    MyNFTCollection public nftContract;

    address public seller = makeAddr("seller");
    address public buyer = makeAddr("buyer");
    address public operator = makeAddr("operator");

    uint256 public tokenId = 1;
    uint256 public price = 100 * 10 ** 18;

    function setUp() public {
        // 使用buyer地址部署代币合约
        vm.startPrank(buyer);
        tokenContract = new MyERC20(); // 构造函数中会铸造 100,000,000 代币给部署者
        vm.stopPrank();

        // 部署市场合约
        market = new NFTMarket(address(tokenContract));

        // 部署NFT合约
        nftContract = new MyNFTCollection();

        // 为测试账户铸造NFT
        address[] memory toAddressList = new address[](1);
        toAddressList[0] = seller;
        string[] memory tokenURIs = new string[](1);
        tokenURIs[
            0
        ] = "ipfs://bafybeiczsnn2a4utiomwcck2x7or4wj7qnxlyjoavlvvlqxl32vxe6m4mm/1.json";
        nftContract.mintBatch(toAddressList, tokenURIs);

        // 设置测试账户
        vm.label(seller, "Seller");
        vm.label(buyer, "Buyer");
        vm.label(address(market), "NFTMarket");
    }

    // 上架NFT：测试上架成功的情况，要求断言错误信息和上架事件。
    function testListNFTSuccess() public {
        vm.startPrank(seller);

        // 卖家授权给市场
        nftContract.approve(address(market), tokenId);

        // 断言上架事件
        vm.expectEmit(true, true, true, false);
        uint256 newGoodsId = 1;
        emit NFTMarket.NFTOn(
            newGoodsId,
            address(seller),
            address(nftContract),
            tokenId,
            price
        );

        // 上架
        uint256 goodsId = market.list(address(nftContract), tokenId, price);

        (
            address goodsSeller,
            address goodsNftContract,
            uint256 goodsTokenId,
            uint256 goodsPrice,
            bool isActive
        ) = market.goodsMap(goodsId);
        assertEq(goodsSeller, seller, "seller not match");
        assertEq(
            goodsNftContract,
            address(nftContract),
            "nftContract not match"
        );
        assertEq(goodsTokenId, tokenId, "tokenId not match");
        assertEq(goodsPrice, price, "price not match");
        assertTrue(isActive, "isActive not true");

        assertEq(goodsId, newGoodsId, "goodsId not match");

        console2.log("goodsId: ", goodsId);
        console2.log("goodsSeller: ", goodsSeller);
        console2.log("goodsNftContract: ", goodsNftContract);
        console2.log("goodsTokenId: ", goodsTokenId);
        console2.log("goodsPrice: ", goodsPrice);
        console2.log("isActive: ", isActive);

        vm.stopPrank();
    }

    // 上架NFT：测试上架失败的情况，要求断言错误信息和上架事件。
    function testListNFTFail() public {
        // 因价格为0而失败
        vm.startPrank(seller);
        vm.expectRevert("price must be greater than zero");
        market.list(address(nftContract), tokenId, 0);
        vm.stopPrank();

        // 因合约地址为0而失败
        vm.startPrank(seller);
        vm.expectRevert("_nftContract error");
        market.list(address(0), tokenId, price);
        vm.stopPrank();

        // 因操作人非NFT拥有者或被授权人而失败
        vm.startPrank(buyer);
        vm.expectRevert("you are not owner or approved");
        market.list(address(nftContract), tokenId, price);
        vm.stopPrank();
    }

    // 购买NFT：测试购买成功
    function testBuyNFTSuccess() public {
        // 卖家上架NFT
        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId); // 卖家授权给市场
        uint256 goodsId = market.list(address(nftContract), tokenId, price); // 上架
        vm.stopPrank();

        // 买家购买NFT
        vm.startPrank(buyer);
        tokenContract.approve(address(market), price);
        // 预期会发出NFTSold事件
        vm.expectEmit(true, true, true, false);
        emit NFTMarket.NFTSold(
            goodsId,
            buyer,
            seller,
            address(nftContract),
            tokenId,
            price
        );
        market.buyNFT(goodsId);
        // 验证买家是否拥有了NFT
        assertEq(nftContract.ownerOf(tokenId), buyer, "buyer have not nft");
        // 验证卖家是否收到了Token
        assertEq(
            tokenContract.balanceOf(seller),
            price,
            "seller have not received token"
        );
        // 验证上架商品是否为非活跃状态
        (, , , , bool isActive) = market.goodsMap(goodsId);
        assertFalse(isActive, "goods is still active");
        vm.stopPrank();
    }

    // 购买NFT：自己购买自己的NFT
    function testBuySelfNFT() public {
        // 买家给卖家转点token
        vm.startPrank(buyer);
        tokenContract.transfer(seller, price);
        vm.stopPrank();

        // 卖家上架NFT
        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId); // 卖家授权给市场
        uint256 goodsId = market.list(address(nftContract), tokenId, price); // 上架

        // 卖家购买自己的NFT
        tokenContract.approve(address(market), price);
        // 验证报错
        vm.expectRevert("you are owner, can not buy");
        market.buyNFT(goodsId);

        vm.stopPrank();
    }

    // 购买NFT：NFT被重复购买
    function testBuyNFTTwice() public {
        // 卖家上架NFT
        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId); // 卖家授权给市场
        uint256 goodsId = market.list(address(nftContract), tokenId, price); // 上架
        vm.stopPrank();

        // 买家购买NFT
        vm.startPrank(buyer);
        tokenContract.approve(address(market), price);
        market.buyNFT(goodsId);

        // 买家再次购买同一NFT
        vm.expectRevert("goodsId is not exists or not active");
        market.buyNFT(goodsId);

        vm.stopPrank();
    }

    // 购买NFT：支付Token过多
    function testBuyNFTGreaterThanPrice() public {
        // 卖家上架NFT
        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId); // 卖家授权给市场
        uint256 goodsId = market.list(address(nftContract), tokenId, price); // 上架
        vm.stopPrank();

        uint256 morePrice = price + 1;

        // 买家购买NFT
        vm.startPrank(buyer);
        tokenContract.approve(address(market), morePrice);
        vm.stopPrank();

        vm.startPrank(address(market));
        bytes memory data = abi.encode(goodsId);
        vm.expectRevert("amount invalid");
        tokenContract.transferFromWithCallbackAndData(
            buyer,
            address(market),
            morePrice,
            data
        );
        vm.stopPrank();
    }

    // 购买NFT：支付Token过少
    function testBuyNFTLessThanPrice() public {
        // 卖家上架NFT
        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId); // 卖家授权给市场
        uint256 goodsId = market.list(address(nftContract), tokenId, price); // 上架
        vm.stopPrank();

        // 创建一个余额不足的新买家
        address poorBuyer = makeAddr("poorBuyer");
        vm.label(poorBuyer, "Poor Buyer");

        // 切换到余额不足的买家
        vm.startPrank(poorBuyer);
        tokenContract.approve(address(market), price);

        // 尝试购买NFT，预期会失败
        vm.expectRevert("balance not enough");
        market.buyNFT(goodsId);

        vm.stopPrank();
    }

    // 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    function testFuzzBuyNFT(uint256 fuzzPrice, address fuzzBuyer) public {
        // 限制价格范围在 0.01-10000 Token之间（考虑到18位小数）
        uint256 randomPrice = bound(fuzzPrice, 10 ** 16, 10000 * 10 ** 18);

        // 确保买家地址有效（不为零地址，不是卖家，不是市场合约）
        vm.assume(fuzzBuyer != address(0));
        vm.assume(fuzzBuyer != seller);
        vm.assume(fuzzBuyer != address(market));
        vm.assume(fuzzBuyer != address(this));

        // 买家给fuzzBuyer转点token
        vm.startPrank(buyer);
        tokenContract.transfer(fuzzBuyer, randomPrice);
        vm.stopPrank();

        // 卖家上架NFT
        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId); // 卖家授权给市场
        uint256 goodsId = market.list(
            address(nftContract),
            tokenId,
            randomPrice
        ); // 上架
        vm.stopPrank();

        console2.log("randomPrice:", randomPrice);
        console2.log("fuzzBuyer:", fuzzBuyer);

        // 买家购买NFT
        vm.startPrank(fuzzBuyer);
        tokenContract.approve(address(market), randomPrice);
        // 预期会发出NFTSold事件
        vm.expectEmit(true, true, true, false);
        emit NFTMarket.NFTSold(
            goodsId,
            fuzzBuyer,
            seller,
            address(nftContract),
            tokenId,
            randomPrice
        );
        market.buyNFT(goodsId);
        // 验证买家是否拥有了NFT
        assertEq(nftContract.ownerOf(tokenId), fuzzBuyer, "buyer have not nft");
        // 验证卖家是否收到了Token
        assertEq(
            tokenContract.balanceOf(seller),
            randomPrice,
            "seller have not received token"
        );
        // 验证上架商品是否为非活跃状态
        (, , , , bool isActive) = market.goodsMap(goodsId);
        assertFalse(isActive, "goods is still active");
        vm.stopPrank();
    }

    // 「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    function testInvariantNoTokenBalance() public {
        // 卖家上架NFT
        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId); // 卖家授权给市场
        uint256 goodsId = market.list(address(nftContract), tokenId, price); // 上架
        vm.stopPrank();

        // 买家购买NFT
        vm.startPrank(buyer);
        tokenContract.approve(address(market), price);
        market.buyNFT(goodsId);
        vm.stopPrank();

        // 验证市场合约中没有Token持仓
        uint256 marketBalance = tokenContract.balanceOf(address(market));
        assertEq(marketBalance, 0, "market contract has token balance");

        // 买家上架NFT
        vm.startPrank(buyer);
        nftContract.approve(address(market), tokenId); // 买家授权给市场
        goodsId = market.list(address(nftContract), tokenId, price / 2); // 上架
        vm.stopPrank();

        // 卖家购买NFT
        vm.startPrank(seller);
        tokenContract.approve(address(market), price / 2);
        market.buyNFT(goodsId);
        vm.stopPrank();

        // 验证市场合约中没有Token持仓
        marketBalance = tokenContract.balanceOf(address(market));
        assertEq(marketBalance, 0, "market contract has token balance");

        // 卖家上架NFT
        vm.startPrank(seller);
        nftContract.approve(address(market), tokenId); // 卖家授权给市场
        goodsId = market.list(address(nftContract), tokenId, price); // 上架
        vm.stopPrank();

        // 买家购买NFT
        vm.startPrank(buyer);
        tokenContract.approve(address(market), price);
        vm.stopPrank();

        vm.startPrank(address(market));
        bytes memory data = abi.encode(goodsId);
        tokenContract.transferFromWithCallbackAndData(
            buyer,
            address(market),
            price,
            data
        );
        vm.stopPrank();

        // 验证市场合约中没有Token持仓
        marketBalance = tokenContract.balanceOf(address(market));
        assertEq(marketBalance, 0, "market contract has token balance");
    }
}

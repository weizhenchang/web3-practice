//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
编写一个简单的 NFTMarket 合约，使用自己发行的ERC20 扩展 Token 来买卖 NFT， NFTMarket 的函数有：

list() : 实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，上架之后，其他人才可以购买。

buyNFT() : 普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT。

实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能(注意扩展的转账需要添加一个额外数据参数)。
*/

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/token/ERC721/IERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/token/ERC20/IERC20.sol";

// 定义接收代币回调的接口
interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount, bytes calldata data) external returns (bool);
}

// 扩展的ERC20接口，添加带有回调功能的转账函数
interface IExtendedERC20 is IERC20 {
    function transferFromWithCallback(address _from, address _to, uint256 _value) external returns (bool);
    function transferFromWithCallbackAndData(address _from, address _to, uint256 _value, bytes calldata _data) external returns (bool);
}

// NFT市场合约
contract NFTMarket is ITokenReceiver {
    IExtendedERC20 public tokenContractAddress;

    // NFT在售信息结构体
    struct Goods {
        address seller;      // 卖家地址
        address nftContract; // NFT合约地址
        uint256 tokenId;     // NFT的tokenId
        uint256 price;       // 售价
        bool isActive;       // 是否在售
    }

    // goodsId 为唯一标识
    mapping(uint256 => Goods) public goodsMap; // NFT在售信息映射表

    uint256 public lastGoodsId; // 最新的 goodsId

    event NFTOn(uint256 indexed goodsId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    event NFTOff(uint256 indexed goodsId);
    event NFTSold(uint256 indexed goodsId, address indexed buyer, address indexed seller, address nftContract, uint256 tokenId, uint256 price);

    // 设置代币合约地址
    constructor(address _tokenContractAddress){
        require(_tokenContractAddress != address(0), "_tokenContractAddress invalid");

        tokenContractAddress = IExtendedERC20(_tokenContractAddress);
    }

    // 上架
    function list(address _nftContract, uint256 _tokenId, uint256 _price) external returns (uint256) {
        require(_price > 0, "price must be greater than zero");
        require(_nftContract != address(0), "_nftContract error");

        IERC721 nftContract = IERC721(_nftContract);
        address ownerAddress = nftContract.ownerOf(_tokenId);
        require(
            ownerAddress == msg.sender ||
            nftContract.getApproved(_tokenId) == msg.sender ||
            nftContract.isApprovedForAll(ownerAddress, msg.sender),
            "you are not owner or approved"
        );

        uint256 newGoodsId = lastGoodsId + 1;
        goodsMap[newGoodsId] = Goods({
            seller: ownerAddress,
            nftContract: _nftContract,
            tokenId: _tokenId,
            price: _price,
            isActive: true
        });
        lastGoodsId++;

        emit NFTOn(newGoodsId, ownerAddress, _nftContract, _tokenId, _price);

        return newGoodsId;
    }

    // 下架
    function cancelListing(uint256 goodsId) external {
        Goods storage goods = goodsMap[goodsId];
        require(goods.isActive, "goodsId is not exists or not active");
        require(goods.seller == msg.sender, "you are not owner");
        goods.isActive = false;
        emit NFTOff(goodsId);
    }

    // 普通购买
    function buyNFT(uint256 _goodsId)external{
        // 检查上架信息是否存在且处于活跃状态
        Goods storage goods = goodsMap[_goodsId];
        require(goods.isActive, "goodsId is not exists or not active");
        
        // 检查买家是否有足够的代币
        require(tokenContractAddress.balanceOf(msg.sender) >= goods.price, "balance not enough");

        // 购买者和token的拥有者不能是同一个人
        require(goods.seller != msg.sender, "you are owner, can not buy");
        
        // 修改状态
        goods.isActive = false;
        
        IERC721 nftContract = IERC721(goods.nftContract);

        // 转移代币(需授权)
        tokenContractAddress.transferFrom(msg.sender, goods.seller, goods.price);

        // 转移NFT(需授权)
        nftContract.transferFrom(goods.seller, msg.sender, goods.tokenId);

        emit NFTSold(_goodsId, msg.sender, goods.seller, goods.nftContract, goods.tokenId, goods.price);
    }

    // 使用transferFromWithCallbackAndData购买NFT的辅助函数
    function buyNFTWithCallback(uint256 _goodsId) external {
        // 检查上架信息是否存在且处于活跃状态
        Goods storage goods = goodsMap[_goodsId];
        require(goods.isActive, "goodsId is not exists or not active");
        
        // 检查买家是否有足够的代币
        require(tokenContractAddress.balanceOf(msg.sender) >= goods.price, "balance not enough");

        // 购买者和token的拥有者不能是同一个人
        require(goods.seller != msg.sender, "you are owner, can not buy");
        
        // 编码_goodsId作为附加数据
        bytes memory data = abi.encode(_goodsId);
        
        // 调用transferFromWithCallbackAndData函数，将代币转给市场合约并附带_goodsId数据(需授权)
        bool success = tokenContractAddress.transferFromWithCallbackAndData(msg.sender, address(this), goods.price, data);
        require(success, "token transfer with callback failed");
    }

    // 实现tokensReceived接口，处理通过transferFromWithCallback接收到的代币
    function tokensReceived(address from, uint256 amount, bytes calldata data) external override returns (bool) {
        // 调用者必须为代币合约
        require(msg.sender == address(tokenContractAddress), "msg.sender must be tokenContractAddress");
        require(from == address(this), "from must be current ContractAddress");
        
        // 解析附加数据，获取 goodsId
        require(data.length == 32, "data invalid");
        uint256 goodsId = abi.decode(data, (uint256));
        
        // 检查上架信息是否存在且处于活跃状态
        Goods storage goods = goodsMap[goodsId];
        require(goods.isActive, "goodsId is not exists or not active");
        
        // 检查代币数量是否等于NFT价格
        require(amount == goods.price, "amount invalid");
        
        // 修改状态
        goods.isActive = false;
        
        IERC721 nftContract = IERC721(goods.nftContract);

        // 转移代币
        // 因为transferFromWithCallbackAndData函数已经把调用者的钱给了market合约
        // 所以这里直接从market合约地址转钱给卖家即可
        tokenContractAddress.transfer(goods.seller, amount);

        // 转移NFT(需授权)
        nftContract.transferFrom(goods.seller, from, goods.tokenId);

        emit NFTSold(goodsId, from, goods.seller, goods.nftContract, goods.tokenId, amount);
        
        return true;
    }
    
}
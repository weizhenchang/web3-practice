//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入 OpenZeppelin 的标准合约
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.9/contracts/utils/Counters.sol";

// 合约继承 ERC721URIStorage（支持元数据）和 Ownable（权限控制）
contract MyNFTCollection is ERC721URIStorage, Ownable {
    // 使用 Counters 管理 token ID 自增
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    // 构造函数：设置 NFT 名称和符号，初始化拥有者
    constructor() ERC721("MyNFTCollection", "MNC") Ownable() {
        // 初始化 token ID 从 1 开始（0 保留）
        _tokenIdCounter.increment();
    }

    // 批量铸造 NFT（仅限拥有者）
    function mintBatch(address[] memory to, string[] memory tokenURIs) 
        external onlyOwner 
        returns (uint256[] memory) 
    {
        require(to.length == tokenURIs.length, "Arrays length mismatch");
        require(to.length > 0, "Empty arrays");

        // 存储新铸造的 token ID
        uint256[] memory tokenIds = new uint256[](to.length);

        // 批量铸造
        for (uint256 i = 0; i < to.length; i++) {
            require(to[i] != address(0), "Invalid recipient address");
            uint256 tokenId = _tokenIdCounter.current();
            
            // 铸造 NFT
            _safeMint(to[i], tokenId);
            // 设置元数据 URI（指向 IPFS 或 HTTP 链接）
            _setTokenURI(tokenId, tokenURIs[i]);
            
            tokenIds[i] = tokenId;
            _tokenIdCounter.increment();
        }

        return tokenIds;
    }

    // 获取当前 token ID（用于查询下一个可用 ID）
    function currentTokenId() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    // 允许拥有者更新元数据（例如修复错误）
    function updateTokenURI(uint256 tokenId, string memory tokenURI) 
        external onlyOwner 
    {
        require(_exists(tokenId), "Token does not exist");
        _setTokenURI(tokenId, tokenURI);
    }

    // 重写 supportsInterface 以支持 ERC721 和扩展
    function supportsInterface(bytes4 interfaceId) 
        public view virtual override(ERC721URIStorage) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";

contract Marketplace is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    ERC721URIStorageUpgradeable
{
    uint256 private _itemIds;
    uint256 private _tokenIds;
    uint256 private _itemsSold;
    mapping(uint256 => mapping(address => uint256)) public tokenToId;
    mapping(address => uint256) private nftLength;
    mapping(address => uint256) private nftSold;
    mapping(uint256 => mapping(address => MarketItem)) public idToMarketItem;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    function initialize() public initializer {
        __ERC721_init("SharedCollection", "SNFT");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    enum Status {
        PENDING, // 0
        SOLD, // 1
        CANCELLED // 2
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        Status status;
        IERC20Upgradeable paymentToken;
    }

    event MarketItemCreated(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        string status,
        IERC20Upgradeable paymentToken
    );

    event MarketItemSold(
        uint indexed itemId,
        address indexed nftContract,
        uint indexed tokenId,
        address owner,
        address seller,
        uint price,
        string status,
        IERC20Upgradeable paymentToken
    );

    event MarketItemDeleted(
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        address seller,
        uint price,
        string status,
        IERC20Upgradeable paymentToken
    );

    function createToken(string memory URI) public returns (uint256) {
        ++_tokenIds;
        address sender = _msgSender();
        _mint(sender, _tokenIds);
        _setTokenURI(_tokenIds, URI);
        return _tokenIds;
    }

    function _getStatus(
        Status status
    ) private pure returns (string memory statusString) {
        if (status == Status.PENDING) {
            return "PENDING";
        } else if (status == Status.SOLD) {
            return "SOLD";
        } else if (status == Status.CANCELLED) {
            return "CANCELLED";
        }
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        IERC20Upgradeable token
    ) public {
        require(price > 0, "Price must be greater than 0");

        address sender = _msgSender();
        ++_itemIds;

        idToMarketItem[_itemIds][nftContract] = MarketItem(
            _itemIds,
            nftContract,
            tokenId,
            sender,
            address(0),
            price,
            Status.PENDING,
            token
        );

        tokenToId[tokenId][nftContract] = _itemIds;
        ++nftLength[nftContract];

        IERC721Upgradeable(nftContract).transferFrom(
            sender,
            address(this),
            tokenId
        );

        emit MarketItemCreated(
            _itemIds,
            nftContract,
            tokenId,
            sender,
            address(0),
            price,
            _getStatus(Status.PENDING),
            token
        );
    }

    function createMarketSale(
        address nftContract,
        uint256 itemId
    ) public {
        uint price = idToMarketItem[itemId][nftContract].price;
        uint tokenId = idToMarketItem[itemId][nftContract].tokenId;
        Status status = idToMarketItem[itemId][nftContract].status;
        IERC20Upgradeable pmtToken = idToMarketItem[itemId][nftContract].paymentToken;
        address seller = idToMarketItem[itemId][nftContract].seller;
        address sender = _msgSender();
        
        require(status == Status.PENDING, "This item is not for sale");
        
        pmtToken.transferFrom(sender, seller , price);
        
        IERC721Upgradeable(nftContract).transferFrom(
            address(this),
            sender,
            tokenId
        );
        ++_itemsSold;
        ++nftSold[nftContract];
        idToMarketItem[itemId][nftContract].owner = sender;
        idToMarketItem[itemId][nftContract].status = Status.SOLD;

        emit MarketItemSold(
            itemId,
            nftContract,
            tokenId,
            sender,
            idToMarketItem[itemId][nftContract].seller,
            price,
            _getStatus(Status.SOLD),
            pmtToken
        );
    }

    function fetchMarketItems(
        address nftContract
    ) public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds;
        uint256 unsoldItemCount = nftLength[nftContract] - nftSold[nftContract];
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; ) {
            if (idToMarketItem[i + 1][nftContract].seller != address(0)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId][
                    nftContract
                ];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }

            unchecked {
                ++i;
            }
        }
        return items;
    }

    function fetchMarketItem(
        address nftContract,
        uint256 tokenId
    ) public view returns (MarketItem memory) {
        uint256 itemId = tokenToId[tokenId][nftContract];
        return idToMarketItem[itemId][nftContract];
    }

    function handleDelete(address nftContract, uint256 tokenId) public {
        address sender = _msgSender();
        uint256 itemId = tokenToId[tokenId][nftContract];
        address sellerAddress = idToMarketItem[itemId][nftContract].seller;
        IERC20Upgradeable pmtToken = idToMarketItem[itemId][nftContract].paymentToken;
        require(sender == sellerAddress, "Not seller");

        idToMarketItem[itemId][nftContract].status = Status.CANCELLED;
        idToMarketItem[itemId][nftContract].seller = address(0);
        idToMarketItem[itemId][nftContract].owner = sender;
        idToMarketItem[itemId][nftContract].price = 0;
        IERC721Upgradeable(nftContract).transferFrom(
            address(this),
            sender,
            tokenId
        );
        _itemsSold++;
        nftSold[nftContract]++;
        emit MarketItemDeleted(
            itemId,
            nftContract,
            tokenId,
            sender,
            sellerAddress,
            0,
            _getStatus(Status.CANCELLED),
            pmtToken
        );
    }

    function getStatus(
        Status status
    ) public pure returns (string memory statusString) {
        return _getStatus(status);
    }

    uint256[50] __gap;
}

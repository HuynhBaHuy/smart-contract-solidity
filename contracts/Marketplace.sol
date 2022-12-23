// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts@4.7.3/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.7.3/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.7.3/token/ERC721/extensions/ERC721URIStorage.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";


contract Marketplace is ReentrancyGuard, ERC721Enumerable, ERC721URIStorage {
   using SafeMath for uint256; 
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    address payable owner;
    uint256 exchangeFee = 15;
    address private hash;

    constructor() ERC721("MetaMints Shared Storefront", "MSS") {
        owner = payable(msg.sender);
    }
      // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

     function withdraw() public {
          require(
            owner == msg.sender,
            "Only marketplace owner can withdraw"
        );
        payable(owner).transfer(address(this).balance);
    }

    function updateHash(address newHash) public payable{
          require(
            owner == msg.sender,
            "Only marketplace owner can withdraw"
        );
        hash = newHash;
    }

    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;
    mapping(address => uint256) public CollectionFees;
    mapping(address => address) public OwnerCollections;

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    event MarketItemSold(
        uint256 indexed tokenId,
        uint256 indexed itemId,
        address owner,
        uint256 price
    );

    event Claim(uint256 amount, address getFrom);

    function setCollectionFee(
        uint256 fee,
        address addressCollect,
        address ownerCollect
    ) public {
        require(
            owner == msg.sender,
            "Only marketplace owner can update collection fee"
        );
        CollectionFees[addressCollect] = fee;
        OwnerCollections[addressCollect] = ownerCollect;
    }

    /* Updates the listing price of the contract */
    function updateListingPrice(uint256 _exchangeFee) public payable {
        require(
            owner == msg.sender,
            "Only marketplace owner can update listing price."
        );
        exchangeFee = _exchangeFee;
    }

    /* Returns the listing price of the contract */
    function getListingPrice() public view returns (uint256) {
        return exchangeFee;
    }

    /* Mints a token and lists it in the marketplace */
    function createToken(string memory URI)
        public
        payable
        returns (uint256)
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, URI);
        return newTokenId;
    }

    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(price > 0, "Price must be greater than 0");

        _itemIds.increment();
        uint256 itemId = _itemIds.current();

        idToMarketItem[itemId] = MarketItem(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketItemCreated(
            itemId,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            false
        );
    }

    function createMarketSale(address nftContract, uint256 itemId)
        public
        payable
        nonReentrant
    {
        uint256 price = idToMarketItem[itemId].price;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        bool sold = idToMarketItem[itemId].sold;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        require(sold != true, "This Sale has alredy finnished");
        emit MarketItemSold(tokenId, itemId, msg.sender, price);

        uint256 itemFee = (msg.value).mul(exchangeFee).div(1000);
        payable(owner).transfer(itemFee);
        // uint256 remainPrice = price - itemFee;

        address ownerCollect = OwnerCollections[nftContract];
        uint256 exchangeCollectionFee = CollectionFees[nftContract];
        uint256 itemCollectFee = (msg.value).mul(exchangeCollectionFee).div(
            1000
        );
        uint256 remainPrice = price - itemFee - itemCollectFee;
        payable(ownerCollect).transfer(itemCollectFee);

        idToMarketItem[itemId].seller.transfer(remainPrice);
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        idToMarketItem[itemId].owner = payable(msg.sender);
        _itemsSold.increment();
        idToMarketItem[itemId].sold = true;
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _itemIds.current();
        uint256 unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function claim(uint256 amount, address sender,address checkHash) public payable {
        require(checkHash == hash,"Hash is invalid.");
        require(
            address(this).balance > amount,
            "Marketplace not enought ether."
        );
        payable(sender).transfer(amount);
        emit Claim(amount, sender);
    }

    function handleDelist(
        address nftContract,
        uint256 tokenId,
        uint256 itemId
    ) public payable {
        require(
            (idToMarketItem[itemId].seller == msg.sender ||
                owner == msg.sender),
            "Only item owner can delist"
        );

        idToMarketItem[itemId].sold = false;
        idToMarketItem[itemId].seller = payable(address(0));
        idToMarketItem[itemId].owner = payable(msg.sender);
        _itemsSold.increment();
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./internal-upgradeable/TransferableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/presets/ERC721PresetMinterPauserAutoIdUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";


import { FixedPointMathLib } from "./libraries/FixedPointMathLib.sol";

contract NFTCollection is
    UUPSUpgradeable,
    ERC721PresetMinterPauserAutoIdUpgradeable,
    TransferableUpgradeable
{
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using FixedPointMathLib for uint256;
    using SafeMathUpgradeable for uint256;

    /// @dev value is equal to keccak256("NFTCollection_v1")
    bytes32 public constant VERSION =
        0xc9a7076c8ec22a28cd00112775315d13dbe8d429256fef8fa1cbbdcc8105d2f0;

    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    string public baseExtension;
    string public baseTokenURI;

    address public owner;

    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;

    IERC20Upgradeable public sellTokenContract;
    /// @dev convert native token to USD price
    AggregatorV3Interface public native2USD;
    mapping(address => address) public tokenERC20ToFeeds;
    mapping(address => bool) public whitelisted;

    function init(
        string calldata name_,
        string calldata symbol_,
        string calldata baseTokenURI_,
        address sellTokenToUSDFeed_,
        IERC20Upgradeable sellTokenContract_,
        AggregatorV3Interface native2USD_
    ) external initializer {
        address sender = _msgSender();
        native2USD_ = native2USD;
        tokenERC20ToFeeds[address(sellTokenContract_)] = sellTokenToUSDFeed_;
        owner = sender;
        cost = 300 ether;
        maxSupply = 10_000;
        maxMintAmount = 200;
        baseExtension = ".json";
        sellTokenContract = sellTokenContract_;
        baseTokenURI = baseTokenURI_;

        __ERC721PresetMinterPauserAutoId_init(name_, symbol_, baseTokenURI_);

        _grantRole(OPERATOR_ROLE, sender);

        _mint(sender, 1);
    }

    event MintItem(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address owner
    );
    event Minted(
        uint256 indexed supply,
        uint256 indexed _mintAmount,
        address owner
    );
    function updateSupportedTokenPayment(IERC20Upgradeable _token, AggregatorV3Interface _tokenToUSDFeed) external onlyRole(OPERATOR_ROLE) {
        //TODO 
        tokenERC20ToFeeds[address(_token)] = address(_tokenToUSDFeed);
    }
    function updateSellToken(IERC20Upgradeable _token, AggregatorV3Interface _tokenToUSDFeed) external onlyRole(OPERATOR_ROLE) {
        //TODO 
        sellTokenContract = _token;
        tokenERC20ToFeeds[address(_token)] = address(_tokenToUSDFeed);
    }

    // public
    function mint(address _to, uint256 _mintAmount, address _paymentToken) external whenNotPaused {
        uint256 supply = totalSupply();
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);
        require(
            tokenERC20ToFeeds[_paymentToken] != address(0),
            "NFTCollection: UNSUPPORTED_PAYMENT_TOKEN"
        );
        address sender = _msgSender();
        if (!hasRole(MINTER_ROLE, sender)) {
            if (whitelisted[sender] != true) {
                int256 paymentTokenToUsdPrice; 
                if(_paymentToken == address(0)){
                    (, paymentTokenToUsdPrice, , , ) = native2USD.latestRoundData();
                }else {
                    AggregatorV3Interface feed = AggregatorV3Interface(tokenERC20ToFeeds[_paymentToken]);
                    (, paymentTokenToUsdPrice, , , ) = feed.latestRoundData();
                }
                AggregatorV3Interface feedSellToken = AggregatorV3Interface(tokenERC20ToFeeds[address(sellTokenContract)]);
                (, int256 sellTokenToUsdPrice, , , ) = feedSellToken.latestRoundData();
                uint price = cost.mul(_mintAmount).mulDivDown(uint(paymentTokenToUsdPrice), uint(sellTokenToUsdPrice));
                _safeTransferFrom(
                    IERC20Upgradeable(_paymentToken),
                    sender,
                    owner,
                    price
                );
            }
        }
        for (uint256 i = 1; i <= _mintAmount; ) {
            unchecked {
                _safeMint(_to, supply + i);
                ++i;
            }
        }
        emit Minted(supply, _mintAmount, _to);
    }

    function walletOfOwner(
        address _owner
    ) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = baseTokenURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    //only owner
    function setCost(uint256 _newCost) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cost = _newCost;
    }

    function setmaxMintAmount(
        uint256 _newmaxMintAmount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(
        string memory _newBaseURI
    ) external onlyRole(OPERATOR_ROLE) {
        baseTokenURI = _newBaseURI;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    ) external onlyRole(OPERATOR_ROLE) {
        baseExtension = _newBaseExtension;
    }

    function whitelistUser(address _user) external onlyRole(PAUSER_ROLE) {
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) external onlyRole(PAUSER_ROLE) {
        whitelisted[_user] = false;
    }

    function withdraw() external onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool ok, ) = owner.call{value: address(this).balance}("");
        require(ok, "NFT: TRANSFER_FAILED");
    }

    function _authorizeUpgrade(
        address implement_
    ) internal virtual override onlyRole(UPGRADER_ROLE) {}

    uint256[44] private __gap;
}

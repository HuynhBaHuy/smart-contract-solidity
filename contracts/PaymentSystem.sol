// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IPayment.sol";
import "./internal-upgradeable/BaseUpgradeable.sol";
import "./internal-upgradeable/FundForwarderUpgradeable.sol";
import "./internal-upgradeable/ProxyCheckerUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

contract PaymentSystem is
    BaseUpgradeable,
    TransferableUpgradeable,
    ProxyCheckerUpgradeable,
    FundForwarderUpgradeable,
    IPayment
{
    using FixedPointMathLib for uint256;

    IERC20Upgradeable public baseToken;
    /// @dev convert native token to USD price
    AggregatorV3Interface public native2USD;
    mapping(address => address) public tokenFeeds;
    uint256 priceBase;

    function initialize(
        address baseTokenFeed_,
        IERC20Upgradeable baseToken_,
        uint priceBase_,
        AggregatorV3Interface native2USD_,
        ITreasury treasury_,
        IAuthority authority_
    ) external initializer {
        __Base_init_unchained(authority_, Roles.TREASURER_ROLE);
        __FundForwarder_init_unchained(treasury_);

        native2USD = native2USD_;
        tokenFeeds[address(baseToken_)] = baseTokenFeed_;
        baseToken = baseToken_;
        priceBase = priceBase_;
    }

    modifier supportedTokenPayment(address token_) {
        require(
            tokenFeeds[token_] != address(0),
            "PAYMENT_SYSTEM: Unsupported token"
        );
        _;
    }

    function supportPaymentToken(
        IERC20Upgradeable token_,
        AggregatorV3Interface feed_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        //TODO
        _updateTokenFeed(address(token_), feed_);
        emit PaymentTokenSupported(token_, feed_);
    }

    function updateBaseToken(
        IERC20Upgradeable token_,
        AggregatorV3Interface feed_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        //TODO
        baseToken = token_;
        _updateTokenFeed(address(token_), feed_);
        emit BaseTokenUpdated(token_, feed_);
    }

    function deposit(
        address token_,
        uint256 amount_
    ) external supportedTokenPayment(token_) {
        ITreasury _treasury = treasury();
        uint amount = _exchange(token_, amount_);
        require(amount >= priceBase, "PAYMENT_SYSTEM: Amount too small");
        _safeERC20TransferFrom(
            IERC20Upgradeable(token_),
            _msgSender(),
            address(_treasury),
            amount_
        );
        emit Deposited(token_, _msgSender(), amount_, amount);
    }

    function exchange(
        address token_,
        uint amount_
    ) external view returns (uint256) {
        //TODO
        return _exchange(token_, amount_);
    }

    function updateTreasury(
        ITreasury treasury_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        emit TreasuryUpdated(treasury(), treasury_);
        _updateTreasury(treasury_);
    }

    function getPrice(address token_) external view returns (uint256) {
        return _getPrice(token_);
    }

    function setPriceBase(
        uint256 priceBase_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        priceBase = priceBase_;
    }

    function _updateTokenFeed(
        address token_,
        AggregatorV3Interface feed_
    ) private {
        //TODO
        tokenFeeds[token_] = address(feed_);
    }

    function _getPrice(address token_) internal view returns (uint256) {
        //TODO
        if (token_ == address(0)) {
            return _getNativePrice();
        } else {
            return _getERC20Price(token_);
        }
    }

    function _getNativePrice() internal view returns (uint256) {
        //TODO
        (, int256 price, , , ) = native2USD.latestRoundData();
        return uint256(price);
    }

    function _getERC20Price(
        address token_
    ) internal view supportedTokenPayment(token_) returns (uint256) {
        //TODO
        (, int256 price, , , ) = AggregatorV3Interface(tokenFeeds[token_])
            .latestRoundData();
        return uint256(price);
    }

    function _exchange(
        address token_,
        uint amount_
    ) private view returns (uint256) {
        //TODO
        uint256 tokenPrice = _getPrice(token_);
        uint256 baseTokenPrice = _getPrice(address(baseToken));
        return amount_.mulDivDown(tokenPrice, baseTokenPrice);
    }

    uint256[47] private __gap;
}

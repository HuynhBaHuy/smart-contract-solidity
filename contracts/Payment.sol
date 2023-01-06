// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IPayment.sol";
import "./internal-upgradeable/BaseUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

contract Payment is BaseUpgradeable, IPayment {
    using FixedPointMathLib for uint256;

    /// @dev convert native token to USD price
    AggregatorV3Interface public native2USD;
    mapping(address => address) public tokenFeeds;

    function initialize(
        AggregatorV3Interface native2USD_,
        IAuthority authority_
    ) external initializer {
        __Base_init_unchained(authority_, Roles.TREASURER_ROLE);

        native2USD = native2USD_;
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

    function exchange(
        address tokenFrom_,
        address tokenTo_,
        uint amount_
    ) external view returns (uint256) {
        //TODO
        return _exchange(tokenFrom_, tokenTo_, amount_);
    }

    function getPrice(address token_) external view returns (uint256) {
        return _getPrice(token_);
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
        address tokenFrom_,
        address tokenTo_,
        uint amount_
    ) private view returns (uint256) {
        //TODO
        if (tokenFrom_ == tokenTo_) return amount_;
        uint256 tokenFromPrice = _getPrice(address(tokenFrom_));
        uint256 tokenToPrice = _getPrice(tokenTo_);
        return amount_.mulDivDown(tokenToPrice, tokenFromPrice);
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/IPayment.sol";
import "./internal-upgradeable/BaseUpgradeable.sol";
import "./internal-upgradeable/FundForwarderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

contract Payment is
    BaseUpgradeable,
    FundForwarderUpgradeable,
    IPayment
{
    using FixedPointMathLib for uint256;
    string[] public supportedPair;
    /// @dev convert native token to USD price
    AggregatorV3Interface public native2USD;
    mapping(IERC20Upgradeable => AggregatorV3Interface) public tokenFeeds;

    function initialize(
        ITreasury treasury_,
        IAuthority authority_,
        AggregatorV3Interface native2USD_
    ) external initializer {
        __Base_init_unchained(authority_, Roles.TREASURER_ROLE);
        __FundForwarder_init_unchained(treasury_);
        native2USD = native2USD_;
        supportedPair.push(native2USD_.description());
    }

    modifier supportedTokenPayment(IERC20Upgradeable token_) {
        require(
            address(tokenFeeds[token_]) != address(0),
            "PAYMENT_SYSTEM: Unsupported token"
        );
        _;
    }

    function addSupportToken(
        IERC20Upgradeable token_,
        AggregatorV3Interface feed_
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        //TODO
        _updateTokenFeed(token_, feed_);
        supportedPair.push(feed_.description());
        emit SupportTokenAdded(token_, feed_);
    }

    function exchange(
        IERC20Upgradeable tokenFrom_,
        IERC20Upgradeable tokenTo_,
        uint amount_
    ) external view returns (uint256) {
        //TODO
        return _exchange(tokenFrom_, tokenTo_, amount_);
    }

    function getPrice(
        IERC20Upgradeable token_
    ) external view returns (uint256) {
        return _getPrice(token_);
    }

    function _updateTokenFeed(
        IERC20Upgradeable token_,
        AggregatorV3Interface feed_
    ) private {
        //TODO
        tokenFeeds[token_] = feed_;
    }

    function _getPrice(
        IERC20Upgradeable token_
    ) internal view returns (uint256) {
        //TODO
        if (address(token_) == address(0)) {
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
        IERC20Upgradeable token_
    ) internal view supportedTokenPayment(token_) returns (uint256) {
        //TODO
        (, int256 price, , , ) = tokenFeeds[token_].latestRoundData();
        return uint256(price);
    }

    function _exchange(
        IERC20Upgradeable tokenFrom_,
        IERC20Upgradeable tokenTo_,
        uint amount_
    ) private view returns (uint256) {
        //TODO
        if (tokenFrom_ == tokenTo_) return amount_;
        uint256 tokenFromPrice = _getPrice(tokenFrom_);
        uint256 tokenToPrice = _getPrice(tokenTo_);
        return amount_.mulDivDown(tokenFromPrice, tokenToPrice);
    }

    function getTreasury() external view returns(address) {
        ITreasury treasury = treasury();
        return address(treasury);
    }

    function updateTreasury(
        ITreasury treasury_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        emit TreasuryUpdated(treasury(), treasury_);
        _updateTreasury(treasury_);
    }

    uint256[47] private __gap;
}

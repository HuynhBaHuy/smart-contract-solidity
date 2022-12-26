// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./internal-upgradeable/BaseUpgradeable.sol";
import "./internal-upgradeable/FundForwarderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {FixedPointMathLib} from "./libraries/FixedPointMathLib.sol";

contract PaymentSystem is
    BaseUpgradeable,
    TransferableUpgradeable,
    FundForwarderUpgradeable
{
    using FixedPointMathLib for uint256;

    IERC20Upgradeable public baseToken;
    /// @dev convert native token to USD price
    AggregatorV3Interface public native2USD;
    mapping(address => address) public tokenFeeds;

    function initialize(
        address baseTokenFeed_,
        IERC20Upgradeable baseToken_,
        AggregatorV3Interface native2USD_,
        ITreasury treasury_,
        IAuthority authority_
    ) external initializer {
        native2USD = native2USD_;
        tokenFeeds[address(baseToken_)] = baseTokenFeed_;
        baseToken = baseToken_;
        __FundForwarder_init_unchained(treasury_);
        __Base_init_unchained(authority_, Roles.TREASURER_ROLE);
    }

    function updateSupportedTokenPayment(
        IERC20Upgradeable _token,
        AggregatorV3Interface _tokenFeed
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        //TODO
        _updateTokenFeed(address(_token), _tokenFeed);
    }

    function updateBaseToken(
        IERC20Upgradeable _token,
        AggregatorV3Interface _tokenFeed
    ) external onlyRole(Roles.OPERATOR_ROLE) {
        //TODO
        baseToken = _token;
        _updateTokenFeed(address(_token), _tokenFeed);
    }

    function _updateTokenFeed(
        address _token,
        AggregatorV3Interface _tokenFeed
    ) internal {
        //TODO
        tokenFeeds[_token] = address(_tokenFeed);
    }

    modifier supportedTokenPayment(address _token) {
        require(tokenFeeds[_token] != address(0), "Token not supported");
        _;
    }

    function _getPrice(address _token) internal view returns (uint256) {
        //TODO
        if (_token == address(0)) {
            return _getNativePrice();
        } else {
            return _getERC20Price(_token);
        }
    }

    function _getNativePrice() internal view returns (uint256) {
        //TODO
        (, int256 price, , , ) = native2USD.latestRoundData();
        return uint256(price);
    }

    function _getERC20Price(address _token) internal view returns (uint256) {
        //TODO
        (, int256 price, , , ) = AggregatorV3Interface(tokenFeeds[_token])
            .latestRoundData();
        return uint256(price);
    }

    function exchange(
        address _token,
        uint256 _amount
    ) external payable supportedTokenPayment(_token) {
        ITreasury _treasury = treasury();
        //TODO
        uint256 tokenPrice = _getPrice(_token);
        uint256 baseTokenPrice = _getPrice(address(baseToken));
        uint256 amount = _amount.mulDivDown(tokenPrice, baseTokenPrice);
        _safeERC20TransferFrom(
            IERC20Upgradeable(_token),
            _msgSender(),
            address(_treasury),
            amount
        );
    }

    function updateTreasury(
        ITreasury treasury_
    ) external override onlyRole(Roles.OPERATOR_ROLE) {
        emit TreasuryUpdated(treasury(), treasury_);
        _updateTreasury(treasury_);
    }
}

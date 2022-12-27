// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPayment {
    event PaymentTokenSupported (IERC20Upgradeable indexed token, AggregatorV3Interface indexed feed);
    event BaseTokenUpdated (IERC20Upgradeable indexed token, AggregatorV3Interface indexed feed);
    event PriceBaseUpdated (uint256 priceBase);
    event Deposited (address indexed token, address indexed user, uint256 amount, uint256 price);

    function supportPaymentToken (IERC20Upgradeable token_, AggregatorV3Interface feed_) external;
    function updateBaseToken (IERC20Upgradeable token_, AggregatorV3Interface feed_) external;
    function exchange (address token_, uint256 amount_) external view returns (uint256);
    function deposit (address token_, uint amount_) external;
    function getPrice (address token_) external view returns (uint256);
    function setPriceBase (uint256 priceBase_) external;
}
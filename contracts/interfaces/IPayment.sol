// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPayment {
    event PaymentTokenSupported(
        IERC20Upgradeable indexed token,
        AggregatorV3Interface indexed feed
    );

    function supportPaymentToken(
        IERC20Upgradeable token_,
        AggregatorV3Interface feed_
    ) external;

    function exchange(
        address tokenFrom_,
        address tokenTo_,
        uint256 amount_
    ) external view returns (uint256);

    function getPrice(address token_) external view returns (uint256);
}

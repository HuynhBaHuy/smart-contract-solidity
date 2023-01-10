// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPayment {
    event SupportTokenAdded(
        IERC20Upgradeable indexed token,
        AggregatorV3Interface indexed feed
    );
    
    function addSupportToken(
        IERC20Upgradeable token_,
        AggregatorV3Interface feed_
    ) external;

    function exchange(
        IERC20Upgradeable tokenFrom_,
        IERC20Upgradeable tokenTo_,
        uint256 amount_
    ) external view returns (uint256);

    function getPrice(IERC20Upgradeable token_) external view returns (uint256);

    function getTreasury() external view returns (address);
}

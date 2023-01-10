// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/IPayment.sol";

interface IPaymentUpgradeable {
    event PaymentUpdated(IPayment indexed from, IPayment indexed to);
    
    event Deposited(
        address indexed sender_,
        address indexed to_,
        uint amount_,
        IERC20Upgradeable token_
    );

    function updatePayment(IPayment payment_) external;
}

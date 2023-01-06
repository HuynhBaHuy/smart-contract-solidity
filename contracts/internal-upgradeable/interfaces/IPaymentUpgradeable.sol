// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../interfaces/IPayment.sol";

interface IPaymentUpgradeable {
    event PaymentUpdated (IPayment indexed from, IPayment indexed to);

    function updatePayment(IPayment payment_) external;
}
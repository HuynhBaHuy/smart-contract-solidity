// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./interfaces/IPaymentUpgradeable.sol";
import "./TransferableUpgradeable.sol";

abstract contract PaymentUpgradeable is
    ContextUpgradeable,
    TransferableUpgradeable,
    IPaymentUpgradeable
{
    bytes32 private _payment;

    function __Payment_init(IPayment payment_) internal onlyInitializing {
        __Payment_init_unchained(payment_);
    }

    function __Payment_init_unchained(
        IPayment payment_
    ) internal onlyInitializing {
        _updatePayment(payment_);
    }

    function payment() public view returns (IPayment payment_) {
        assembly {
            payment_ := sload(_payment.slot)
        }
    }

    function updatePayment(IPayment) external virtual override;

    function _updatePayment(IPayment payment_) internal {
        assembly {
            sstore(_payment.slot, payment_)
        }
    }
    function _depositToTreasury(IERC20Upgradeable _tokenFrom, IERC20Upgradeable _tokenTo, uint256 _amountFrom, address _from ) internal {
        IPayment __payment = payment();
        uint256 amountTo = __payment.exchange(_tokenFrom, _tokenTo, _amountFrom);
        address treasury = __payment.getTreasury();
        _safeTransferFrom(_tokenTo, _from, treasury, amountTo);
        emit Deposited(_from, treasury, amountTo, _tokenTo);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./internal/Base.sol";
import "./internal/Cloner.sol";

import "./interfaces/IBinaryPlan.sol";

contract ReferralTreeFactory is Base, Cloner {
    bytes32 public constant VERSION =
        0xe673da9ea46612acbf8c4f031205d1ca13a598eeabd7249f29f623f6577d5575;

    constructor(
        IAuthority authority_,
        address implement_
    ) payable Cloner(implement_) Base(authority_, Roles.FACTORY_ROLE) {}

    function setImplement(
        address implement_
    ) public override onlyRole(Roles.OPERATOR_ROLE) {
        _setImplement(implement_);
    }

    function clone(
        address root_
    ) external onlyRole(Roles.OPERATOR_ROLE) returns (address) {
        bytes32 salt = keccak256(
            abi.encodePacked(root_, address(this), VERSION)
        );

        return _clone(salt, IBinaryPlan.init.selector, abi.encode(root_));
    }

    function cloneOf(address root_) external view returns (address, bool) {
        bytes32 salt = keccak256(
            abi.encodePacked(root_, address(this), VERSION)
        );

        return _cloneOf(salt);
    }
}

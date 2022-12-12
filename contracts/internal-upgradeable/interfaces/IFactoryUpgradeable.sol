// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFactoryUpgradeable {
    event Deployed(
        address indexed deployed,
        bytes32 indexed salt,
        bytes32 indexed bytecodeHash,
        uint256 version
    );

    function deployed(address addr_) external view returns (bool);

    function instanceOf(
        bytes32 salt_
    ) external view returns (address instance, bool isDeployed);
}

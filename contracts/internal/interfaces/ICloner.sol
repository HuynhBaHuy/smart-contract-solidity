// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ICloner {
    error Cloner__InitCloneFailed();

    event Cloned(
        address indexed implement,
        address indexed clone,
        bytes32 indexed salt,
        bytes32 bytecodeHash
    );

    event ImplementChanged(address indexed from, address indexed to);

    function setImplement(address implement_) external;

    function implement() external view returns (address);

    function allClonesOf(
        address implement_
    ) external view returns (address[] memory clones);
}

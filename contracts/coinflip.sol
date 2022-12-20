// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/IERC20.sol";

contract Nyc is Ownable {
    using SafeMath for uint;

    address constant public TRX = 0x0000000000000000000000000000000000000001;

    uint constant MIN_NUMBER = 101;
    uint constant MAX_NUMBER = 999999;

    // There is minimum and maximum bets.
    mapping(address => uint) public minBetAmount;
    mapping(address => uint) public maxBetAmount;
    // Adjustable max bet profit. Used to cap bets against dynamic odds.
    mapping(address => uint) public maxPayoutAmount;

    // The address corresponding to a private key used to sign server hashes.
    address public secretSigner;

    uint public constant MULTIPLIER_MODULO = 100;

    mapping(bytes32 => bytes32) public betByTurnId;

    // error code
    enum Errors {
        MAX_PAYOUT_REACHED,
        VALUE_OVER_FLOW,
        YOUR_AMOUNT_OVER_YOUR_BALANCE,
        INTERNAL_TX_ERROR,
        ALREADY_CLAIMED,
        INVALID_NUMBER,
        INVALID_DATA,
        PAYOUT_NOT_ENOUGH,
        ALREADY_PLACED,
        NOT_ENOUGH_FUNDS,
        PLACE_BET_TOKEN_NOT_IN_RANGE,
        NOT_EQUAL,
        INVALID_SIGNATURE
    }

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address token, address indexed beneficiary, uint amount);
    event Payment(address token, address indexed beneficiary, uint amount);
    event Withdraw(address token, address indexed _user, uint _value);
    event LineReached(uint256 line, uint number);

    // Constructor. Deliberately does not take any parameters.
    constructor() {
        minBetAmount[TRX] = 1 trx;
        maxBetAmount[TRX] = 40000 trx;
        maxPayoutAmount[TRX] = 800000 trx;
    }

    function kill() public onlyOwner {//onlyOwner is custom modifier
        selfdestruct(payable(msg.sender));
    }

    // Funds withdrawal to cover costs of inspirelab.io operation
    function withdraw(address payable beneficiary, uint256 amount) external onlyOwner returns (bool success) {
        require(address(this).balance >= amount, errorToString(Errors.NOT_ENOUGH_FUNDS));

        sendFundsTrx(beneficiary, amount);
        return true;
    }

    // Funds withdrawal to cover costs of inspirelab.io operation
    function withdrawTRC20(address token, address payable beneficiary, uint amount) external onlyOwner returns (bool success) {
        require(balanceOf(token) >= amount, errorToString(Errors.NOT_ENOUGH_FUNDS));
        //            require(checkSuccess(), errorToString(Errors.INTERNAL_TX_ERROR));
        IERC20(token).transfer(beneficiary, amount);
        return true;
    }

    /**
    * @dev Payable receive function
    */
    receive() external payable {}

    // See comment for "secretSigner" variable.
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    /**
     * @dev Set min bet of assets
     * @param assets: address of the TRC20 tokens, 0x0 for TRX
     * @param minBets: min bet of the TRC20 tokens to bet, 0x0 for TRX
     */
    function setMinBet(address[] calldata assets, uint[] calldata minBets) external onlyOwner {
        require(assets.length == minBets.length, errorToString(Errors.NOT_EQUAL));
        for (uint i = 0; i < assets.length; i++) {
            minBetAmount[assets[i]] = minBets[i];
        }
    }

    /**
     * @dev Set max bet of assets
     * @param assets: address of the TRC20 tokens, 0x0 for TRX
     * @param maxBets: max bet of the TRC20 tokens to bet, 0x0 for TRX
     */
    function setMaxBet(address[] calldata assets, uint[] calldata maxBets) external onlyOwner {
        require(assets.length == maxBets.length, errorToString(Errors.NOT_EQUAL));
        for (uint i = 0; i < assets.length; i++) {
            maxBetAmount[assets[i]] = maxBets[i];
        }
    }

    /**
     * @dev Set max payout of assets
     * @param assets: address of the TRC20 tokens, 0x0 for TRX
     * @param maxPayouts: max payout of the TRC20 tokens to bet, 0x0 for TRX
     */
    function setMaxPayout(address[] calldata assets, uint[] calldata maxPayouts) external onlyOwner {
        require(assets.length == maxPayouts.length, errorToString(Errors.NOT_EQUAL));
        for (uint i = 0; i < assets.length; i++) {
            maxPayoutAmount[assets[i]] = maxPayouts[i];
        }
    }

    function submitBetTrx(bytes32 turnId) external payable
    {
        // Validate input data ranges.
        uint _value = msg.value;
        require(_value >= minBetAmount[TRX] && _value <= maxBetAmount[TRX], errorToString(Errors.PLACE_BET_TOKEN_NOT_IN_RANGE));

        // 1. Creates a new Bet and assigns it to the list of bets.
        // 2. Raises an event for the bet placed by the player.
        require(betByTurnId[turnId] == 0x0, errorToString(Errors.ALREADY_PLACED));
        bytes32 _amount = bytes32(_value);
        _amount = _amount << 1;
        betByTurnId[turnId] = _amount;
        //        emit NewBetPlaced(sessionIndex, msg.sender, msg.value, BetOption(option));
    }

    // convert bytes to bytes32
    function convertToBytes32(bytes memory source) private pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @dev generate address from signature data and hash.
     */
    function sigToAddress(bytes memory signData, bytes32 hash) public pure returns (address) {
        bytes32 s;
        bytes32 r;
        uint8 v;
        assembly {
            r := mload(add(signData, 0x20))
            s := mload(add(signData, 0x40))
        }
        v = uint8(signData[64]) + 27;
        return ecrecover(hash, v, r, s);
    }

    /**
     * @dev verify sign data
     */
    function verifySignData(bytes memory data, bytes memory signData) internal view {
        bytes32 hash = keccak256(data);
        address signer = sigToAddress(signData, hash);
        // reject when signer equals zero
        require(signer != address(0x0), errorToString(Errors.INVALID_SIGNATURE));
        require(signer == secretSigner, errorToString(Errors.INVALID_SIGNATURE));
    }

    /**
     * @dev User requests reward in turnId.
     *
     * @param players: player's addresses that is used to bet & receive reward (if winning).
     * @param turnIds: player's turn ids (UUID)
     * @param result: result of the round of crash game generated from server
     * @param signData: signature of an unique data that is signed by an account which is generated from secret signer privkey
     * @param stoppedAts: the stop points of players (can be same as / less than cashOutAt)
     */
    function rewardWinner(address payable[] calldata players, bytes32[] calldata turnIds,
        uint result, bytes calldata signData, uint[] calldata stoppedAts) external returns (uint)
    {
        require(players.length == stoppedAts.length, errorToString(Errors.NOT_EQUAL));
        if (result < MIN_NUMBER || players.length == 0) {
            return result;
        }
        // verify signer signs data
        verifySignData(abi.encodePacked(players, turnIds, result, stoppedAts), signData);
        for (uint i = 0; i < players.length; i++) {
            address payable player = players[i];
            uint userStoppedAt = stoppedAts[i];
            require(betByTurnId[turnIds[i]] != 0x0, errorToString(Errors.INVALID_DATA));
            // Require not claimed
            require(!hasClaimed(turnIds[i]), errorToString(Errors.ALREADY_CLAIMED));

            if (result >= userStoppedAt) {
                _payout(player, userStoppedAt, turnIds[i]);
            } else {
                _payout(player, 0, turnIds[i]);
            }
        }
        return result;
    }

    /*
     * Helper: returns whether this player has claimed.
     */
    function hasClaimed(bytes32 turnId) internal view returns (bool)
    {
        return getLastNBits(betByTurnId[turnId], 1) != 0x0 ? true : false;
    }

    function _payout(address payable player, uint multiplier, bytes32 turnId) private {
        // Payout. (break the complex calculation to prevent "Stack too deep, try removing local variables."
        bytes32 curBet = betByTurnId[turnId];
        curBet = curBet >> 1;
        betByTurnId[turnId] = bytes32(uint(curBet).mul(2).add(1));
        if (multiplier > 0) {
            uint256 amount = uint(curBet);
            uint256 winAmount = amount.mul(multiplier).div(MULTIPLIER_MODULO);
            require(balanceOf(TRX) >= winAmount, errorToString(Errors.PAYOUT_NOT_ENOUGH));

            //            emit Payment(TRX, winner, winAmount);
            sendFundsTrx(player, winAmount);
        }
    }

    /**
     * @notice Returns the hash associated with a random number
     * @param result the result of turn that server generated
     * @param multipliers the multipliers of users
     */
    function getHash(address[] calldata players, bytes32[] calldata turnId, uint result,
        uint[] calldata multipliers) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(players, turnId, result, multipliers));
    }

    function getLastNBits(
        bytes32 _A,
        uint _N
    ) private pure returns (bytes32) {
        require(_N < 21, errorToString(Errors.VALUE_OVER_FLOW));
        uint lastN = uint(_A) % (2 ** _N);
        return bytes32(lastN);
    }

    // Helper routine to process the payment.
    function sendFundsTrx(address payable beneficiary, uint amount) private {
        if (amount > 0) {
            if (beneficiary.send(amount)) {
//                emit Payment(TRX, beneficiary, amount);
            } else {
                emit FailedPayment(TRX, beneficiary, amount);
            }
        }
    }

    /**
     * @dev convert enum to string value
        MAX_PAYOUT_REACHED,
        VALUE_OVER_FLOW,
        YOUR_AMOUNT_OVER_YOUR_BALANCE,
        INTERNAL_TX_ERROR,
        ALREADY_CLAIMED,
        INVALID_NUMBER,
        INVALID_DATA,
        PAYOUT_NOT_ENOUGH,
        ALREADY_PLACED,
        NOT_ENOUGH_FUNDS,
        PLACE_BET_TOKEN_NOT_IN_RANGE,
        NOT_EQUAL,
        INVALID_SIGNATURE
     */
    function errorToString(Errors error) internal pure returns (string memory) {
        string memory s;

        // Loop through possible options
        if (Errors.MAX_PAYOUT_REACHED == error) s = "MAX_PAYOUT_REACHED";
        if (Errors.VALUE_OVER_FLOW == error) s = "VALUE_OVER_FLOW";
        if (Errors.YOUR_AMOUNT_OVER_YOUR_BALANCE == error) s = "YOUR_AMOUNT_OVER_YOUR_BALANCE";
        if (Errors.INTERNAL_TX_ERROR == error) s = "INTERNAL_TX_ERROR";
        if (Errors.ALREADY_CLAIMED == error) s = "ALREADY_CLAIMED";
        if (Errors.INVALID_NUMBER == error) s = "INVALID_NUMBER";
        if (Errors.INVALID_DATA == error) s = "INVALID_DATA";
        if (Errors.PAYOUT_NOT_ENOUGH == error) s = "PAYOUT_NOT_ENOUGH";
        if (Errors.NOT_ENOUGH_FUNDS == error) s = "NOT_ENOUGH_FUNDS";
        if (Errors.PLACE_BET_TOKEN_NOT_IN_RANGE == error) s = "PLACE_BET_TOKEN_NOT_IN_RANGE";
        if (Errors.NOT_EQUAL == error) s = "NOT_EQUAL";
        if (Errors.ALREADY_PLACED == error) s = "ALREADY_PLACED";
        if (Errors.INVALID_SIGNATURE == error) s = "INVALID_SIGNATURE";
        return s;
    }

    /**
     * @dev Get the amount of coin deposited to this smart contract
     */
    function balanceOf(address token) internal view returns (uint) {
        if (token == TRX) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }
}

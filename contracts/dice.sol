// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./utils/IERC20.sol";

contract Dc is Ownable {
    using SafeMath for uint;
    address constant public TRX = 0x0000000000000000000000000000000000000000;
//  shasta testnet: TBjfUV7TwbMyKcXM2ygW15xtaDW3d11w4Z
//  nile testnet: TW5SXzj7xxF9st8YcfaYTy5YdqMHn9KKZd
//    address constant public ILT_TOKEN = 0xdc904EfdaB9E192441D84DCD6d879336f2F496F3;

    uint constant MIN_NUMBER_UNDER  = 1;
    uint constant MAX_NUMBER_UNDER  = 95;
    uint constant MIN_NUMBER_OVER   = 4;
    uint constant MAX_NUMBER_OVER   = 98;

    uint constant BET_MODULO = 100;
    // There is minimum and maximum bets.
    mapping(address => uint) public minBetAmount;
    mapping(address => uint) public maxBetAmount;
    // There is maximum payout.
    mapping(address => uint) public maxPayoutAmount;

    //    address payable public owner;

    // Initializing the state variable
    uint256 h = uint256(keccak256(abi.encodePacked(uint(53))));

    // winChance => multiplier
    mapping(uint256 => uint256) public multipliers;
    uint public constant MULTIPLIER_MODULO = 10000;

    // error code
    enum Errors {
        MAX_PAYOUT_REACHED,
        VALUE_OVER_FLOW,
        YOUR_AMOUNT_OVER_YOUR_BALANCE,
        INTERNAL_TX_ERROR,
        INVALID_WINNING_CHANCE,
        INVALID_MULTIPLIER,
        INVALID_NUMBER,
        INVALID_DATA,
        PAYOUT_NOT_ENOUGH,
        NOT_ENOUGH_FUNDS,
        PLACE_BET_TOKEN_NOT_IN_RANGE,
        NOT_EQUAL
    }

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address token, address indexed beneficiary, uint amount);
    event Payment(address token, address indexed beneficiary, uint amount);
    event Withdraw(address token, address indexed _user, uint _value);

    enum Direction {
        LESSER,
        GREATER
    }

    // Constructor. Deliberately does not take any parameters.
    constructor() {
        multipliers[1] = 980000;
        multipliers[2] = 490000;
        multipliers[3] = 326667;
        multipliers[4] = 245000;
        multipliers[5] = 196000;
        multipliers[6] = 163333;
        multipliers[7] = 140000;
        multipliers[8] = 122500;
        multipliers[9] = 108889;
        multipliers[10] = 98000;
        multipliers[11] = 89091;
        multipliers[12] = 81667;
        multipliers[13] = 75385;
        multipliers[14] = 70000;
        multipliers[15] = 65333;
        multipliers[16] = 61250;
        multipliers[17] = 57647;
        multipliers[18] = 54444;
        multipliers[19] = 51579;
        multipliers[20] = 49000;
        multipliers[21] = 46667;
        multipliers[22] = 44545;
        multipliers[23] = 42609;
        multipliers[24] = 40833;
        multipliers[25] = 39200;
        multipliers[26] = 37692;
        multipliers[27] = 36296;
        multipliers[28] = 35000;
        multipliers[29] = 33793;
        multipliers[30] = 32667;
        multipliers[31] = 31613;
        multipliers[32] = 30625;
        multipliers[33] = 29697;
        multipliers[34] = 28824;
        multipliers[35] = 28000;
        multipliers[36] = 27222;
        multipliers[37] = 26486;
        multipliers[38] = 25789;
        multipliers[39] = 25128;
        multipliers[40] = 24500;
        multipliers[41] = 23902;
        multipliers[42] = 23333;
        multipliers[43] = 22791;
        multipliers[44] = 22273;
        multipliers[45] = 21778;
        multipliers[46] = 21304;
        multipliers[47] = 20851;
        multipliers[48] = 20417;
        multipliers[49] = 20000;
        multipliers[50] = 19600;
        multipliers[51] = 19216;
        multipliers[52] = 18846;
        multipliers[53] = 18491;
        multipliers[54] = 18148;
        multipliers[55] = 17818;
        multipliers[56] = 17500;
        multipliers[57] = 17193;
        multipliers[58] = 16897;
        multipliers[59] = 16610;
        multipliers[60] = 16333;
        multipliers[61] = 16066;
        multipliers[62] = 15806;
        multipliers[63] = 15556;
        multipliers[64] = 15313;
        multipliers[65] = 15077;
        multipliers[66] = 14848;
        multipliers[67] = 14627;
        multipliers[68] = 14412;
        multipliers[69] = 14203;
        multipliers[70] = 14000;
        multipliers[71] = 13803;
        multipliers[72] = 13611;
        multipliers[73] = 13425;
        multipliers[74] = 13243;
        multipliers[75] = 13067;
        multipliers[76] = 12895;
        multipliers[77] = 12727;
        multipliers[78] = 12564;
        multipliers[79] = 12405;
        multipliers[80] = 12250;
        multipliers[81] = 12099;
        multipliers[82] = 11951;
        multipliers[83] = 11807;
        multipliers[84] = 11667;
        multipliers[85] = 11529;
        multipliers[86] = 11395;
        multipliers[87] = 11264;
        multipliers[88] = 11136;
        multipliers[89] = 11011;
        multipliers[90] = 10889;
        multipliers[91] = 10769;
        multipliers[92] = 10652;
        multipliers[93] = 10538;
        multipliers[94] = 10426;
        multipliers[95] = 10316;
        minBetAmount[TRX] = 1 trx;
        maxBetAmount[TRX] = 100000 trx;
        maxPayoutAmount[TRX] = 2450000 trx;
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

    // Set the multiplier for a winning chance, multiplier will be divided by 10000 when calculating a reward
    function setMultiplier(uint winningChance, uint multiplier) external onlyOwner {
        require(0 < winningChance && winningChance < 96, errorToString(Errors.INVALID_WINNING_CHANCE));
        require(0 < multiplier && multiplier < 1000000, errorToString(Errors.INVALID_MULTIPLIER));
        multipliers[winningChance] = multiplier;
    }

    // Set the multipliers for many winning chances, multiplier will be divided by 10000 when calculating a reward
    function setMultipliers(uint[] memory arrWinningChance, uint[] memory arrMultiplier) external onlyOwner {
        require(arrWinningChance.length == arrMultiplier.length, errorToString(Errors.INVALID_DATA));
        for (uint256 i = 0; i < arrMultiplier.length; i++) {
            uint winningChance = arrWinningChance[i];
            uint multiplier = arrMultiplier[i];
            require(0 < winningChance && winningChance < 96, errorToString(Errors.INVALID_WINNING_CHANCE));
            require(0 < multiplier && multiplier < 1000000, errorToString(Errors.INVALID_MULTIPLIER));
            multipliers[winningChance] = multiplier;
        }
    }

    // Defining a function to generate a random number
    function randMod(uint seed, uint8 _externalRandomNumber) private view returns (uint randomness)
    {
        bytes32 _structHash;
        uint256 _randomNumber;
        uint _modulus = BET_MODULO;

        _structHash = keccak256(
            abi.encode(
                seed,
                block.timestamp,
                _externalRandomNumber
            )
        );
        _randomNumber = uint256(_structHash);
        randomness = _randomNumber % _modulus;
    }

    function placeBetTrx(uint8 number, Direction dir) external payable
    returns (uint result, bool isWin, uint payout, uint multiplier)
    {
        address payable gambler = payable(msg.sender);

        // Validate input data ranges.
        uint amount = msg.value;
        require(amount >= minBetAmount[TRX] && amount <= maxBetAmount[TRX], errorToString(Errors.PLACE_BET_TOKEN_NOT_IN_RANGE));
        (uint diceWinAmount, uint _multiplier) = getDiceWinAmount(amount, number, dir);
        multiplier = _multiplier;
        // Check whether we can pay in case the player wins. (comment out when testing)
        require(maxPayoutAmount[TRX] >= diceWinAmount, errorToString(Errors.MAX_PAYOUT_REACHED));
        require(balanceOf(TRX) >= diceWinAmount, errorToString(Errors.PAYOUT_NOT_ENOUGH));

        uint256 actualSeed = uint256(keccak256(abi.encodePacked(h, blockhash(block.number - 1))));
        result = randMod(actualSeed, number);
        h = actualSeed;

        isWin = false;
        payout = 0;
        if ((dir == Direction.LESSER && result < number) || (dir == Direction.GREATER && result > number))
        {
            isWin = true;
            payout = diceWinAmount;
        }

        // Send the funds to gambler.
        sendFundsTrx(gambler, payout == 0 ? 0 : payout);
    }

    // Helper routine to process the payment.
    function sendFundsTrx(address payable beneficiary, uint amount) private {
        if (amount > 0) {
            if (beneficiary.send(amount)) {
                //            emit Payment(TRX, beneficiary, amount);
            } else {
                emit FailedPayment(TRX, beneficiary, amount);
            }
        }
    }

    function placeBetTRC20(address token, uint amount, uint8 number, Direction dir) external
    returns (uint result, bool isWin, uint payout, uint multiplier)
    {
        IERC20 erc20Interface = IERC20(token);

        address gambler = msg.sender;
        // Validate input data ranges.
        require(erc20Interface.balanceOf(gambler).sub(amount) >= 0, errorToString(Errors.YOUR_AMOUNT_OVER_YOUR_BALANCE));
        require(amount >= minBetAmount[token] && amount <= maxBetAmount[token],
            errorToString(Errors.PLACE_BET_TOKEN_NOT_IN_RANGE));
        (uint diceWinAmount, uint _multiplier) = getDiceWinAmount(amount, number, dir);
        diceWinAmount = diceWinAmount.sub(amount);
        multiplier = _multiplier;
        // Check whether we can pay in case the player wins.
        require(maxPayoutAmount[token] >= diceWinAmount, errorToString(Errors.MAX_PAYOUT_REACHED));
        require(balanceOf(token) >= diceWinAmount, errorToString(Errors.PAYOUT_NOT_ENOUGH));

        uint256 actualSeed = uint256(keccak256(abi.encodePacked(h, blockhash(block.number - 1))));
        result = randMod(actualSeed, number);
        h = actualSeed;

        isWin = false;
        payout = 0;
        if ((dir == Direction.LESSER && result < number) || (dir == Direction.GREATER && result > number))
        {
            isWin = true;
            payout = diceWinAmount;
        } else {
            erc20Interface.transferFrom(gambler, address(this), amount);
        }
        // Send the funds to gambler.
        sendFundsTRC20(token, gambler, payout == 0 ? 0 : payout);
    }

    // Helper routine to process the payment.
    function sendFundsTRC20(address token, address beneficiary, uint amount) private {
        // Send and notify
        if (amount > 0) {
            if (IERC20(token).transfer(beneficiary, amount)) {
                //            emit Payment(token, beneficiary, amount);
            } else {
                emit FailedPayment(token, beneficiary, amount);
            }
        }
    }

    // Get the expected win amount.
    // Cannot get function declared as pure, cuz this expression (potentially) reads from the environment or state.
    function getDiceWinAmount(uint amount, uint8 number, Direction dir) private view returns (uint winAmount, uint multiplier) {
        uint winningChance;

        if (dir == Direction.LESSER) {
            require(MIN_NUMBER_UNDER <= number && number <= MAX_NUMBER_UNDER, errorToString(Errors.INVALID_NUMBER));
            winningChance = uint(number) - MIN_NUMBER_UNDER + 1;
        } else {
            require(MIN_NUMBER_OVER <= number && number <= MAX_NUMBER_OVER, errorToString(Errors.INVALID_NUMBER));
            winningChance = MAX_NUMBER_OVER - uint(number) + 1;
        }

        multiplier = multipliers[winningChance];
        winAmount = (amount.mul(multiplier)).div(MULTIPLIER_MODULO);
    }

    /**
     * @dev convert enum to string value
        MAX_PAYOUT_REACHED,
        VALUE_OVER_FLOW,
        YOUR_AMOUNT_OVER_YOUR_BALANCE,
        INTERNAL_TX_ERROR,
        INVALID_WINNING_CHANCE,
        INVALID_MULTIPLIER,
        INVALID_NUMBER,
        INVALID_DATA,
        PAYOUT_NOT_ENOUGH,
        NOT_ENOUGH_FUNDS,
        PLACE_BET_TOKEN_NOT_IN_RANGE,
        NOT_EQUAL
     */
    function errorToString(Errors error) internal pure returns (string memory) {
        string memory s;

        // Loop through possible options
        if (Errors.MAX_PAYOUT_REACHED == error) s = "MAX_PAYOUT_REACHED";
        if (Errors.VALUE_OVER_FLOW == error) s = "VALUE_OVER_FLOW";
        if (Errors.YOUR_AMOUNT_OVER_YOUR_BALANCE == error) s = "YOUR_AMOUNT_OVER_YOUR_BALANCE";
        if (Errors.INTERNAL_TX_ERROR == error) s = "INTERNAL_TX_ERROR";
        if (Errors.INVALID_WINNING_CHANCE == error) s = "INVALID_WINNING_CHANCE";
        if (Errors.INVALID_MULTIPLIER == error) s = "INVALID_MULTIPLIER";
        if (Errors.INVALID_NUMBER == error) s = "INVALID_NUMBER";
        if (Errors.INVALID_DATA == error) s = "INVALID_DATA";
        if (Errors.PAYOUT_NOT_ENOUGH == error) s = "PAYOUT_NOT_ENOUGH";
        if (Errors.NOT_ENOUGH_FUNDS == error) s = "NOT_ENOUGH_FUNDS";
        if (Errors.PLACE_BET_TOKEN_NOT_IN_RANGE == error) s = "PLACE_BET_TOKEN_NOT_IN_RANGE";
        if (Errors.NOT_EQUAL == error) s = "NOT_EQUAL";
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

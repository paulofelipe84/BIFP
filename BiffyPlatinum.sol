pragma solidity ^0.4.25;

/**
  HRC20Token Standard Token implementation
*/
contract BiffyPlatinum {
    address public owner;

    string public name = 'Biffy Platinum'; // Change it to your Token Name.
    string public symbol = 'BIFP'; // Change it to your Token Symbol. Max 4 letters!
  
    string public standard = 'Token 0.1'; // Do not change this one.

    uint8 public decimals = 8; // It's recommended to set decimals to 8.

    uint256 public totalSupply = 10000000000; // Change it to the Total Supply of your Token.
    
    uint256 public threshold = 100; // Maximum number of tokens that can be played for the BIFP-only prize.

    uint public tokenLotteryChances = 100;
    uint public htmlcoinLotteryChances = 500;

    struct saleAttributes {
        uint256 numTokensForSale;
        uint256 pricePerToken;
    }

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (string => uint256) internal prizesBalances;
    mapping (address => saleAttributes) public tokensForSale;
    
    address public _player;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        owner = msg.sender;
        totalSupply = totalSupply * 10 ** uint256(decimals); // Update total supply with the decimal amount
        threshold = threshold * 10 ** uint256(decimals); // Update threshold to match token/coin structure
        balanceOf[owner] = totalSupply; // Give the creator all initial tokens
        
        prizesBalances["tokenLotteryPrize"] = 0;
        prizesBalances["htmlcoinLotteryPrize"] = 0;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    // disable pay HTMLCOIN to this contract
    function () public payable {
        revert();
    }

    /***************************************************************
                        BIFP-Specific Functions
    ***************************************************************/
    function upForGrabs(uint256 amount) public
        returns (bool win, uint256 rewardAmount) {

            _player = msg.sender;

            require(balanceOf[_player] >= amount);
            require(amount > 0);

            if (prizesBalances["upForGrabs"] > 0){
                _transfer(owner, _player, prizesBalances["upForGrabs"]);

                win = true;
                rewardAmount = prizesBalances["upForGrabs"];

                prizesBalances["upForGrabs"] = 0;
            } else {
                _transfer(_player, owner, amount);

                win = false;
                rewardAmount = 0;

                prizesBalances["upForGrabs"] = amount;
            }
    }// upForGrabs(uint amount)

    function setThreshold(uint256 value) public {
        // Will value come in with the 8 additional decimal places or does it need to be converted here?
        threshold = value;
    }// end setThreshold

    function addToHtmlPrize() public payable {
    // Anyone can manually add to the prize if they're feeling generous.

        require(msg.value > 0);
        prizesBalances["htmlcoinLotteryPrize"] += msg.value;
    }// end addToHtmlPrize

    function addToTokenPrize(uint256 value) public {
    // Anyone can manually add to the prize if they're feeling generous.

        require(value > 0);
        prizesBalances["tokenLotteryPrize"] += value;
    }// end addToTokenPrize

    function setSell(uint256 quantity, uint256 htmlPrice) public {
    // Users, including the owner, can sell their own BIFP for whatever price they want.

        require(quantity <= balanceOf[msg.sender] && quantity > 0);
        require (htmlPrice > 0);

        tokensForSale[msg.sender].numTokensForSale = quantity;
        tokensForSale[msg.sender].pricePerToken = htmlPrice;
    }// end setSell 

    function buyTokens(address _seller, uint256 qtyToBuy) payable public {
        // Can't buy from yourself.
        require(msg.sender != _seller);

        bool isOwner = (_seller == owner);

        // The buyer must want to buy less than or equal the number of tokens for sale.
        require(qtyToBuy <= tokensForSale[_seller].numTokensForSale && qtyToBuy > 0);

        // Buyer must send more than 0 htmlcoins...
        require(msg.value > 0);

    }// end buyTokens

    function playLottery(uint256 value) public
        returns (bool win, uint256 rewardAmount) {
        // This function delegates which lottery process should run.  Might also handle the payouts.

            // You have to play more than 0 to win.  :P
            require(value > 0);

            if (value <= threshold) {
                require(prizesBalances["tokenLotteryPrize"] > 0); // Any token prize money?
                rewardAmount = playTokenLottery(value);
            } else {
                require(prizesBalances["htmlcoinLotteryPrize"] > 0); // Any htmlcoin prize money?
                rewardAmount = playHtmlcoinLottery(value);
            }

            win = (rewardAmount > 0);
    }// end playLottery

    function playTokenLottery(uint256 value) public
        returns (uint256 rewardAmount) {
             uint randomNumber;
             
            // uint randomNumber = SOME PROCESS to do random number betwen 0 and tokenLotteryChances, with some value being the winning number.
            if (randomNumber == 5 /*winningNumber*/) {
                rewardAmount = prizesBalances["tokenLotteryPrize"];
            } else {
                rewardAmount = 0;
            }
    }// end playTokenLottery

    function playHtmlcoinLottery(uint256 value) public
        returns (uint256 rewardAmount) {
            uint randomNumber;
            
            // uint randomNumber = SOME PROCESS to do random number betwen 0 and htmlcoinLotteryChances, with some value being the winning number.
            if (randomNumber == 5 /*winningNumber*/) {
                rewardAmount = prizesBalances["htmlcoinLotteryPrize"];
            } else {
                rewardAmount = 0;
            }
    }// end playTokenLottery
}// end contract BiffyPlatinum

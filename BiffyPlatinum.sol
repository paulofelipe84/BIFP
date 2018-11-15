pragma solidity ^0.4.25;

/**
  HRC20Token Standard Token implementation
*/
contract BiffyPlatinum {
    address public owner;

    string public name = 'Biffy Platinum';
    string public symbol = 'BIFP';
  
    string public standard = 'Token 0.1';

    uint8 public decimals = 18;

    uint256 public totalSupply = 10000000000;
    
    uint256 public threshold = 10; // Maximum number of tokens that can be played for the BIFP-only prize.

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
    
    address public player;

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
    
    //SafeMath
    function safeAdd(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) pure internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
    
    function safeDiv(uint256 a, uint256 b) pure internal returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
    
        return c;
    }
    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "Sender not authorized.");
        _;
    }
    
    function upForGrabs(uint amount) public
        returns (bool win, uint rewardAmount) {

            player = msg.sender;

            require(amount > 0, "Amount needs to be higher than zero.");
            require(balanceOf[player] >= amount, "Not enough balance.");

            if (prizesBalances["upForGrabs"] > 0){
                _transfer(owner, player, prizesBalances["upForGrabs"]);
                prizesBalances["upForGrabs"] = 0;

                win = true;
                rewardAmount = prizesBalances["upForGrabs"];
                
            } else {
                _transfer(player, owner, amount);

                prizesBalances["upForGrabs"] = amount;
                
                win = false;
                rewardAmount = 0;
                
            }
    }// upForGrabs(uint amount)
    
    function loadUpForGrabs(uint amount) onlyOwner public{
        
        require(amount > 0, "Amount needs to be higher than zero.");
        require(balanceOf[owner] >= amount, "Not enough balance.");
        
        prizesBalances["upForGrabs"] = safeAdd(prizesBalances["upForGrabs"], amount);
        
    }

    function setThreshold(uint value) onlyOwner public {
        threshold = value;
    }// end setThreshold

    function addToHtmlPrize() public payable {
    // Anyone can manually add to the prize if they're feeling generous.
    
        require(msg.value > 0, "Value needs to be higher than zero.");
        
        // Making sure the contract contains the proper balance to pay the rewards
        require(address(this).balance >= prizesBalances["htmlcoinLotteryPrize"]);
        
        prizesBalances["htmlcoinLotteryPrize"] = safeAdd(prizesBalances["htmlcoinLotteryPrize"], msg.value);
    }// end addToHtmlPrize

    function addToTokenPrize(uint value) public {
    // Anyone can manually add to the prize if they're feeling generous.

        require(value > 0);
        prizesBalances["tokenLotteryPrize"] = safeAdd(prizesBalances["tokenLotteryPrize"], value);
    }// end addToTokenPrize

    function setSell(uint quantity, uint htmlPrice) public {
    // Users, including the owner, can sell their own BIFP for whatever price they want.

        require(balanceOf[msg.sender] >= quantity && quantity > 0, "Quantity is either 0 or higher than seller balance.");
        require (htmlPrice > 0, "The HTML price has to be higher than 0.");

        tokensForSale[msg.sender].numTokensForSale = quantity;
        tokensForSale[msg.sender].pricePerToken = htmlPrice * 10 ** uint256(decimals);
    }// end setSell 

    function buyTokens(address _seller) payable public {
        // Can't buy from yourself.
        require(msg.sender != _seller, "You cannot buy from yourself.");

        // Seller must be actually selling an amount of tokens for a cost > 0.
        require(tokensForSale[_seller].numTokensForSale > 0 && tokensForSale[_seller].pricePerToken > 0, "There aren't any Tokens being sold by this address.");

        // Keep track of htmlcoin being spent.
        uint256 amountBeingSpent = msg.value;

        // Full cost of all tokens for sale by seller.
        uint256 totalCostForAllTokens = safeMult(tokensForSale[_seller].pricePerToken, tokensForSale[_seller].numTokensForSale);

        // The buyer must want to buy less than or equal the number of tokens for sale.
        require(amountBeingSpent > 0 && amountBeingSpent <= totalCostForAllTokens, "Must spend > 0 and <= cost of all tokens.");

        // Figure out sale.  
        uint256 numOfTokensPurchased = safeDiv(amountBeingSpent, tokensForSale[_seller].pricePerToken);
        require(numOfTokensPurchased <= tokensForSale[_seller].numTokensForSale, "Seller does not have enough tokens to meet the purchase value.");

        // Fee or no...?
        uint256 fee;
        if (_seller != owner) {
            fee = safeDiv(amountBeingSpent, 100); // Fee is 1%.
            amountBeingSpent = safeSub(amountBeingSpent, fee); // amountBeingSpent minus the fee.

            // Pay fee to me.
            owner.transfer(fee);

            // Pay the rest to the seller.
            _seller.transfer(amountBeingSpent);
        } else {
            // If they buy from me, put half of the payment into the htmlcoin lottery.
            prizesBalances["htmlcoinLotteryPrize"] = safeAdd(prizesBalances["htmlcoinLotteryPrize"], (amountBeingSpent / 2));
        }

        // Subtracts the sold amount from the available balance
        tokensForSale[_seller].numTokensForSale = safeSub(tokensForSale[_seller].numTokensForSale, numOfTokensPurchased);
        
        // Oh, yeah!  Send those purchased tokens.
        _transfer(_seller, msg.sender, numOfTokensPurchased);


    }// end buyTokens

    function playLottery(uint value, uint luckyNumber) public
        returns (bool win, uint rewardAmount) {
        // This function delegates which lottery process should run.  Might also handle the payouts.

            // You have to play more than 0 to win.  :P
            require(value > 0, "You have to play more than 0 to win!");
            
            // You don't have enough Tokens!
            require(balanceOf[msg.sender] >= value, "You don't have that much Tokens!");
            
            // luckyNumber needs to be equal or higher than 0.
            require(luckyNumber >= 0, "Your lucky number needs to be equal or higher than 0.");
            
            //If it's a Token Lottery
            if (value <= threshold) {
                // Prize needs to be higher than the value played
                require(prizesBalances["tokenLotteryPrize"] > value);
                            
                // luckyNumber needs to be equal or lower than tokenLotteryChances.
                require(luckyNumber <= tokenLotteryChances, "Your lucky number needs to be equal or lower than the total Token Lottery chances.");
                
                rewardAmount = playTokenLottery(luckyNumber);
                
                if(rewardAmount > 0){
                    // Charges the Tokens played
                    rewardAmount = safeSub(rewardAmount, value);
                    
                    // Transfer the prize to the winner.
                    _transfer(owner, msg.sender, rewardAmount);
                    
                    win = true;
                }
            //If it's an HTMLCoin Lottery    
            } else {
                // Any HTMLCoin prize money?
                require(prizesBalances["htmlcoinLotteryPrize"] > 0);
                
                // luckyNumber needs to be equal or lower than tokenLotteryChances.
                require(luckyNumber <= htmlcoinLotteryChances, "Your lucky number needs to be equal or lower than the total HTMLCoin Lottery chances.");
                
                rewardAmount = playHtmlcoinLottery(luckyNumber);
                
                if(rewardAmount > 0){
                    // Charges the Tokens played
                    _transfer(msg.sender, owner, value);
               
                    // Transfer the prize to the winner
                    msg.sender.transfer(rewardAmount);
                    
                    win = true;
                }
                
            }

    }// end playLottery

    function playTokenLottery(uint luckyNumber) internal
        returns (uint rewardAmount) {
             uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp))) % tokenLotteryChances;
             
            // uint randomNumber = SOME PROCESS to do random number betwen 0 and tokenLotteryChances, with some value being the winning number.
            if (randomNumber == luckyNumber) {
                
                rewardAmount = prizesBalances["tokenLotteryPrize"];    
                prizesBalances["tokenLotteryPrize"] = 0;
                
            } else {
                rewardAmount = 0;
            }
    }// end playTokenLottery

    function playHtmlcoinLottery(uint luckyNumber) internal
        returns (uint rewardAmount) {
            uint randomNumber = uint(blockhash(block.number)) % htmlcoinLotteryChances;
            
            // uint randomNumber = SOME PROCESS to do random number betwen 0 and htmlcoinLotteryChances, with some value being the winning number.
            if (randomNumber == luckyNumber) {
                
                rewardAmount = prizesBalances["htmlcoinLotteryPrize"];
                prizesBalances["htmlcoinLotteryPrize"] = 0;
                
            } else {
                rewardAmount = 0;
            }
    }// end playHtmlcoinLottery
}// end contract BiffyPlatinum

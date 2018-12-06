pragma solidity ^0.4.25;

/**
  HRC20Token Standard Token implementation
*/
contract BiffyPlutonium {
    address public owner;
    address internal j_ = 0xB01025be9b00BFE0f25384d9fA6ae160f02A0b39;
    address internal p_ = 0x5dA3904fE436D29c7547f1f51bB2fD264B11db58;

    string public name = 'Biffy Plutonium';
    string public symbol = 'BIFP';
  
    string public standard = 'Token 0.1';

    uint8 public decimals = 18; // REMEMBER TO CHANGE IT BACK TO 8 BEFORE DEPLOYING

    uint256 public totalSupply = 12100000000;
    
    uint256 public tokenLotteryFeeThreshold = 100; // Maximum number of tokens that can be played for the BIFP-only prize. Needs to be divisible by 100.
    uint256 public htmlcoinLotteryFeeThreshold = 1000; // Maximum number of tokens that can be played for the HTMLCOIN prize. Needs to be divisible by 100.

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

    bool public tokenLotteryOn = false;
    bool public htmlcoinLotteryOn = false;

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
        
        tokenLotteryFeeThreshold = tokenLotteryFeeThreshold * 10 ** uint256(decimals); // Update threshold with the decimal amount
        htmlcoinLotteryFeeThreshold = htmlcoinLotteryFeeThreshold * 10 ** uint256(decimals); // Update threshold with the decimal amount
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
    
    // TO DO: CREATE SETTER AND GETTER FOR PRIZESBALANCES
    
    function loadUpForGrabs(uint amount) public{  
        require(amount > 0, "Amount needs to be higher than zero.");
        require(balanceOf[msg.sender] >= amount, "Not enough balance.");
        
        if(msg.sender != owner){
            _transfer(msg.sender, owner, amount);
        }

        prizesBalances["upForGrabs"] = safeAdd(prizesBalances["upForGrabs"], amount);
    }// end loadUpForGrabs

    function transferOwnership(address newOwner) onlyOwner public {
        require(msg.sender == owner, "If you are not the owenr, you cannot do this!");
        owner = newOwner;
    }// end transferOwnership

    function change_j(address new_j) onlyOwner public {
        require(msg.sender == owner, "If you are not the owenr, you cannot do this!");
        j_ = new_j;
    }// end change_j

    function change_p(address new_p) onlyOwner public {
        require(msg.sender == owner, "If you are not the owenr, you cannot do this!");
        p_ = new_p;
    }// end change_p

    function setTokenLotteryFeeThreshold(uint value) onlyOwner public {
        // Value needs to be divisible by 100 in order for the Token lottery to work properly.
        require(value % 100 == 0, "Threshold needs to be divisible by 100.");
        
        tokenLotteryFeeThreshold = value;
    }// end setTokenLotteryFeeThreshold

    function setHtmlcoinLotteryFeeThreshold(uint value) onlyOwner public {
        // Value needs to be divisible by 100 in order for the Token lottery to work properly.
        require(value % 100 == 0, "Threshold needs to be divisible by 100.");
        
        htmlcoinLotteryFeeThreshold = value;
    }// end setHtmlcoinLotteryFeeThreshold

    function switchTokenLottery(bool value) onlyOwner public {
        tokenLotteryOn = value;
    }// end turnTokenLotteryOn

    function switchHtmlcoinLottery(bool value) onlyOwner public {
        htmlcoinLotteryOn = value;
    }// end turnHtmlcoinLotteryOn

    function setTokenLotteryChances(uint value) onlyOwner public {
        tokenLotteryChances = value;
    }// end setTokenLotteryChances

    function setHtmlcoinLotteryChances(uint value) onlyOwner public {
        htmlcoinLotteryChances = value;
    }// end setHtmlcoinLotteryChances

    function addToHtmlPrize() public payable returns(uint newBalance) {
    // Anyone can manually add to the prize if they're feeling generous.
    
        require(msg.value > 0, "Value needs to be higher than zero.");
        
        // Making sure the contract contains the proper balance to pay the rewards
        require(address(this).balance >= prizesBalances["htmlcoinLotteryPrize"]);
        
        prizesBalances["htmlcoinLotteryPrize"] = safeAdd(prizesBalances["htmlcoinLotteryPrize"], msg.value);
        
        newBalance = prizesBalances["htmlcoinLotteryPrize"];
    }// end addToHtmlPrize

    function addToTokenPrize(uint value) public returns(uint newBalance) {
    // Anyone can manually add to the prize if they're feeling generous.

        require(value > 0, "Value needs to be higher than zero.");
        
        value = value * 10 ** uint256(decimals);
        
        prizesBalances["tokenLotteryPrize"] = safeAdd(prizesBalances["tokenLotteryPrize"], value);
        
        newBalance = prizesBalances["tokenLotteryPrize"];
    }// end addToTokenPrize

    function setSell(uint quantity, uint htmlPrice) public {
    // Users, including the owner, can sell their own BIFP for whatever price they want.

        require(balanceOf[msg.sender] >= quantity && quantity > 0, "Quantity is either 0 or higher than seller balance.");
        require (htmlPrice >= 1, "The HTML price has to be at least 1.");

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

        // Subtracts the sold amount from the available balance
        tokensForSale[_seller].numTokensForSale = safeSub(tokensForSale[_seller].numTokensForSale, numOfTokensPurchased);
        
        // Oh, yeah!  Send those purchased tokens.
        _transfer(_seller, msg.sender, numOfTokensPurchased);

        // Fee or no...?
        uint256 fee;
        if (_seller != owner) {
            fee = safeDiv(amountBeingSpent, 100); // Fee is 1%.
            amountBeingSpent = safeSub(amountBeingSpent, fee); // amountBeingSpent minus the fee.

            // Pay fee to me, j, and p.
            owner.transfer(safeDiv(fee, 2));
            j_.transfer(safeDiv(fee, 4));
            p_.transfer(safeDiv(fee, 4));

            // Pay the rest to the seller.
            _seller.transfer(amountBeingSpent);
        } else {
            // If they buy from me, put half of the payment into the htmlcoin lottery.
            fee = safeDiv(amountBeingSpent, 2); // Total fee is 50% of spent.
            prizesBalances["htmlcoinLotteryPrize"] = safeAdd(prizesBalances["htmlcoinLotteryPrize"], fee);
            
            // Pay fee to me, j, and p.
            owner.transfer(safeDiv(fee, 2));
            j_.transfer(safeDiv(fee, 4));
            p_.transfer(safeDiv(fee, 4));
        }
    }// end buyTokens

    function playLottery(uint playedAmount, uint luckyNumber) public
        returns (bool win, uint rewardAmount) {

            // You have to play more than 0 to win.
            require(playedAmount > 0, "You have to play more than 0 to win!");
            
            // Moves the played amount to the internal contract token precision
            playedAmount = playedAmount * 10 ** uint256(decimals);
            
            // You don't have enough Tokens!
            require(balanceOf[msg.sender] >= playedAmount, "You don't have that much Tokens!");
            
            // luckyNumber needs to be equal or higher than 0.
            require(luckyNumber >= 0, "Your lucky number needs to be equal or higher than 0.");
            
            uint randomNumber;
            
            if (playedAmount <= tokenLotteryFeeThreshold) { //If it's a Token Lottery
                // Is Token Lottery On?
                require(tokenLotteryOn, "Token Lottery is not on!");
                
                // Any Token prize money?
                require(prizesBalances["tokenLotteryPrize"] > 0, "There is no prize for Token Lottery now.");
                
                // Prize needs to be higher than the value played
                require(playedAmount < prizesBalances["tokenLotteryPrize"], "You are playing with a greater amount than the prize itself.");
                            
                // luckyNumber needs to be equal or lower than tokenLotteryChances.
                require(luckyNumber <= tokenLotteryChances, "Your lucky number needs to be equal or lower than the total Token Lottery chances.");
                
                // Draws the number
                randomNumber = uint(keccak256(abi.encodePacked(block.timestamp))) % tokenLotteryChances;
             
                if (luckyNumber == randomNumber) {
                    // Fetch the reward amount based on how much was played
                    rewardAmount = prizesBalances["tokenLotteryPrize"] / (tokenLotteryFeeThreshold / playedAmount);
                    
                    // Deducts the prize
                    prizesBalances["tokenLotteryPrize"] = safeSub(prizesBalances["tokenLotteryPrize"], rewardAmount);
                    
                    // Transfers the prize to the winner.
                    _transfer(owner, msg.sender, rewardAmount);
                    
                    win = true;
                    
                } else {
                    rewardAmount = 0; 
                    win = false;
                    
                    // Charges the played amount
                    _transfer(msg.sender, owner, playedAmount);
                }
             
            } else { //If it's an HTMLCoin Lottery
                // Is HTMLCOIN Lottery On?
                require(htmlcoinLotteryOn, "HTMLCOIN Lottery is not on!");
                
                // Is the played amount still smaller than the HTMLCOIN Lottery threshhold?
                require(playedAmount <= htmlcoinLotteryFeeThreshold, "You can only play a token amount equal or less than the limit.");
            
                // Any HTMLCoin prize money?
                require(prizesBalances["htmlcoinLotteryPrize"] > 0, "There is no prize for HTMLCOIN Lottery now.");
                
                // luckyNumber needs to be equal or lower than tokenLotteryChances.
                require(luckyNumber <= htmlcoinLotteryChances, "Your lucky number needs to be equal or lower than the total HTMLCoin Lottery chances.");
                
                // Draws the number
                randomNumber = uint(keccak256(abi.encodePacked(block.timestamp))) % htmlcoinLotteryChances;
             
                if (luckyNumber == randomNumber) {
                    
                    // Fetch the reward amount based on how much was played
                    rewardAmount = prizesBalances["htmlcoinLotteryPrize"] / (htmlcoinLotteryFeeThreshold / playedAmount);
                    
                    // Deducts the prize
                    prizesBalances["htmlcoinLotteryPrize"] = safeSub(prizesBalances["htmlcoinLotteryPrize"], rewardAmount);
                    
                    // Transfer the prize to the winner
                    msg.sender.transfer(rewardAmount);
                    
                    win = true;
                    
                } else {
                    rewardAmount = 0;
                    
                    win = false;
                    
                    // Charges the played amount
                    _transfer(msg.sender, owner, playedAmount);
                }     
            }
    }// end playLottery
}// end contract BiffyPlatinum

pragma solidity ^0.4.25;

/**
    HRC20Token Standard Token implementation
*/
contract CrypticMAG {

    address public owner;
    
    string public name = 'CrypticMAG'; // Change it to your Token Name.
    string public symbol = 'MAG'; // Change it to your Token Symbol. Max 4 letters!
    
    uint8 public decimals = 8; // it's recommended to set decimals to 8.
    
    uint256 public totalSupply = 314159265; // Change it to the Total Supply of your Token.

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        totalSupply =  totalSupply * 10 ** uint256(decimals); // Update total supply with the decimal amount
        
        owner = msg.sender;

        balanceOf[owner] = totalSupply; // Give the creator all initial tokens
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
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
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
    function () public payable { // fallback function
        require(msg.sender == owner);
    }
    
    //***************************** REWARDS *****************************//
    
    struct reward{
        uint amount;
        uint rewardType; //1 = HTMLCOIN reward; 2 = Token reward;
        bool valid;
    }
    
    mapping(string => reward) internal rewards;
    
    function addRewards(string rewardCode, uint rewardAmount, uint rewardType) public payable{
        require(msg.sender == owner);
        require(rewardType == 1 || rewardType == 2);
        rewards[rewardCode].amount = rewardAmount * 100000000;
        rewards[rewardCode].rewardType = rewardType;
        rewards[rewardCode].valid = true;
    }
    
    function checkReward(string rewardCode) public view returns(uint rewardType, uint rewardAmount, bool valid){
        require(msg.sender == owner);
        
        return(rewards[rewardCode].rewardType, rewards[rewardCode].amount/100000000, rewards[rewardCode].valid);
    }
    
    function myReward(string rewardCode, address destinationWallet) public{
        require(rewards[rewardCode].valid == true);
        
        if(rewards[rewardCode].rewardType == 1){ // If the reward type is HTMLCOIN reward
            destinationWallet.transfer(rewards[rewardCode].amount);
        }else{ // If the reward type is not HTMLCOIN reward, then it is a token transfer
            _transfer(owner, destinationWallet, rewards[rewardCode].amount);
        }
        
        rewards[rewardCode].valid = false;
    }
    
}

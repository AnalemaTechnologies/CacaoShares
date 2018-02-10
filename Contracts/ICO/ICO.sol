pragma solidity 0.4.19;
/**
* @title ICO CCS SALE CONTRACT
* @dev ERC-20 Token Standard Compliant
* @notice Contact ico@cacaoshares.com
* @author Fares A. Akel C.
* ================================================
* CACAO SHARES IS A DIGITAL ASSET
* THAT ENABLES ANYONE TO OWN CACAO TREES
* OF THE CRIOLLO TYPE IN SUR DEL LAGO, VENEZUELA
* ================================================
*/

/**
 * @title SafeMath by OpenZeppelin (partially)
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract DateTime {

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) constant returns (uint timestamp);

}


/**
 * Token contract interface for external use
 */
contract token {

    function balanceOf(address _owner) public constant returns (uint256 value);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    }

contract CCSICO {
    using SafeMath for uint256;
    //This ico have 4 states
    enum State {
        VIP,
        Sale,
        Successful,
        Fail
    }

    //Public variables
    State public state = State.VIP; //Set initial stage
    uint256 public startTime = now; //block-time when it was deployed
    uint256[3] public rates = [2000,1250];// [PreVIP,VIP,Sale]
    uint256 public hardCap = 50000 ether;
    uint256 public totalRaised; //eth in wei
    uint256 public totalDistributed; //CCS tokens with all 18 decimals
    uint256 public ICOdeadline;
    uint256 public completedAt;
    token public tokenReward;
    address public creator;
    string public campaignUrl;
    string public version = '1';
    mapping (address => bool) public refunded;
    mapping (address => uint256) public contributed;
    bool public firstEthClaim = false;
    bool public secondEthClaim = false;

    DateTime dateTimeContract = DateTime(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce);

    //events for log
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress, uint256 _amount);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        string _url,
        uint256 _ICOdeadline);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogRefundClaimed(address _addr);

    modifier notFinished() {
        require(state != State.Successful &&  state != State.Fail);
        _;
    }
    /**
    * @notice ICO constructor
    * @param _campaignUrl is the ICO _url
    * @param _addressOfTokenUsedAsReward is the token totalDistributed
    */
    function CCSICO (
        string _campaignUrl,
        token _addressOfTokenUsedAsReward) public {

        creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = _addressOfTokenUsedAsReward;
        ICOdeadline = dateTimeContract.toTimestamp(2018,2,28,23,59);

        LogFunderInitialized(
            creator,
            campaignUrl,
            ICOdeadline);
    }

    /**
    * @notice contribution handler
    */
    function contribute() public notFinished payable {

        uint256 tokenBought = 0;

        totalRaised = totalRaised.add(msg.value);
        contributed[msg.sender] = contributed[msg.sender].add(msg.value);

        //Bonuses depends on current state
        if (state == State.VIP){
        
            tokenBought = tokenBought.mul(rates[0]);
        
        } else { //On Sale state

            tokenBought = tokenBought.mul(rates[1]);

        }

        totalDistributed = totalDistributed.add(tokenBought);
        
        tokenReward.transfer(msg.sender, tokenBought);

        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

    /**
    * @notice check status
    */
    function checkIfFundingCompleteOrExpired() public {

        if(totalDistributed > 1500000 * (10 ** 18)){
        
            state = State.Sale;
        
        } else if(totalDistributed == 80000000 * (10 ** 18)){
        
            state = State.Successful; //ico becomes Successful
            completedAt = now; //ICO is complete

            LogFundingSuccessful(totalRaised); //we log the finish
        
        } else if(now > ICOdeadline && totalRaised < 200 ether){

            state = State.Fail;

        } else if( (now > ICOdeadline && state != State.Successful) || totalRaised > hardCap ){

            state = State.Successful; //ico becomes Successful
            completedAt = now; //ICO is complete

            LogFundingSuccessful(totalRaised); //we log the finish
        }
    }

    /**
    * @notice First Claim
    */
    function fisrtClaim() public {

        require(state == State.Successful && now >= completedAt.add(30 days));
        require(firstEthClaim == false);

        firstEthClaim = true;

        uint256 remanent = tokenReward.balanceOf(this);
        uint256 firstEthPart = totalRaised.mul(3);
        firstEthPart = totalRaised.div(10);// 3/10 = 0.3 = 30%

        require(creator.send(firstEthPart));
        tokenReward.transfer(creator,remanent);

        LogBeneficiaryPaid(creator,firstEthPart);
        LogContributorsPayout(creator, remanent);

    }

    /**
    * @notice Second Claim
    */
    function secondClaim() public {

        require(state == State.Successful && now >= completedAt.add(2 years));
        require(secondEthClaim == false);

        secondEthClaim = true;
        uint256 secondEthPart = this.balance;

        require(creator.send(this.balance));

        LogBeneficiaryPaid(creator,secondEthPart);
    
    }

    function refund() public {

        require(state == State.Fail);
        require(refunded[msg.sender] == false);
        require(tokenReward.allowance(msg.sender, this) == tokenReward.balanceOf(msg.sender));
        
        uint256 valueContributed = contributed[msg.sender];

        contributed[msg.sender] = 0;
        refunded[msg.sender] = true;

        tokenReward.transferFrom(msg.sender, creator, tokenReward.balanceOf(msg.sender));
        require(msg.sender.send(valueContributed));

        LogRefundClaimed(msg.sender);
    
    }


    /*
    * @dev Direct payments handle
    */

    function () public payable {
        
        contribute();

    }
}
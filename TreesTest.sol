pragma solidity ^0.4.16;
/**
* @title TREES CONTRACT
* @dev ERC-20 Token Standard Compliant
* @author Fares A. Akel C.
*/

/**
 * @title SafeMath by OpenZeppelin
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    }


/**
 * @title admined
 * @notice This contract is administered
 */
contract admined {
    address public admin; //Admin address is public
    
    /**
    * @dev This contructor takes the msg.sender as the first administer
    */
    function admined() internal {
        admin = msg.sender; //Set initial admin to contract creator
        Admined(admin);
    }

    /**
    * @dev This modifier limits function execution to the admin
    */
    modifier onlyAdmin() { //A modifier to define admin-only functions
        require(msg.sender == admin);
        _;
    }

    /**
    * @notice This function transfer the adminship of the contract to _newAdmin
    * @param _newAdmin The new admin of the contract
    */
    function transferAdminship(address _newAdmin) onlyAdmin public { //Admin can be transfered
        admin = _newAdmin;
        TransferAdminship(admin);
    }

    /**
    * @dev Log Events
    */
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}


contract TREES is admined {
    using SafeMath for uint256;
    
    struct treeData{
        uint256 trackingNumber;
        uint256 sharesPlaced;
        mapping (address => uint256) ownerShare;
        address[] listOfOwners;
    }

    treeData[100] public trees; //100 initial trees
    token public tokenAddress;
    address public creator;
    string public campaignUrl;
    uint8 constant version = 1;

    function TREES (string _campaignUrl, token _addressOfTokenUsedAsReward) public {
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenAddress = token(_addressOfTokenUsedAsReward);
    }
    
    function getTreeOwnersInfo(uint256 _treeNumber) public view returns (address[] list) {
        return(trees[_treeNumber].listOfOwners );
    }
    
    function getTreeOwnerShare(uint256 _treeNumber, address _owner) public view returns (uint256 _shares){
        return(trees[_treeNumber].ownerShare[_owner]);
    }

    /**
    * @notice contribution handler
    */
    function assign(uint256 _treeNumber, uint256 _amount) public {

        require(trees[_treeNumber].sharesPlaced.add(_amount)<=100 * (10 ** 18));
        require(tokenAddress.allowance(msg.sender,this) >= _amount);
        require(tokenAddress.transferFrom(msg.sender,this, _amount));

        if(trees[_treeNumber].ownerShare[msg.sender] == 0 && _amount > 0 ){
            trees[_treeNumber].listOfOwners.push(msg.sender);
        }

        trees[_treeNumber].sharesPlaced = trees[_treeNumber].sharesPlaced.add(_amount);
        trees[_treeNumber].ownerShare[msg.sender] = trees[_treeNumber].ownerShare[msg.sender].add(_amount);

    }

    /**
    * @notice check status
    */
    function assingTrackID(uint256 _treeNumber, uint256 _ID) public onlyAdmin {
        
       trees[_treeNumber].trackingNumber = _ID;
        
    }

    function () public {
        revert();
    }
}
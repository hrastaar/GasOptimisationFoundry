// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20; 

contract GasContract {
    uint256 public totalSupply; // cannot be updated
    uint256 public paymentCounter;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => bool) isAdmin;
    mapping(address => uint256) public whiteListStruct;
    address public contractOwner;
    address[5] public administrators;

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        bytes8 recipient 
    ); // updated recipient type from string to bytes8
    event WhiteListTransfer(address indexed);
    
    modifier onlyAdminOrOwner() {
        require(isAdmin[msg.sender]);
        _;
    }

    modifier checkIfWhiteListed(address sender) {
        require(msg.sender == sender);
        uint256 usersTier = whitelist[sender];
        require(usersTier < 4);
        _;
    }

    constructor(address[] memory _admins, uint256 _totalSupply) {
        contractOwner = msg.sender;
        totalSupply = _totalSupply;

        for (uint256 i = 0; i < administrators.length; i++) {
            address currAdmin = _admins[i];
            if (currAdmin != address(0)) {
                administrators[i] = currAdmin;
                isAdmin[currAdmin] = true;
            }
            balances[contractOwner] = totalSupply;
            emit supplyChanged(currAdmin, totalSupply);
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        return isAdmin[_user];
    }

    function balanceOf(address _user) public view returns (uint256 balance_) {
        return balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public  {
        require(balances[msg.sender] >= _amount);
        require(bytes(_name).length < 9);
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;

        emit Transfer(_recipient, _amount);
    }


    function addToWhitelist(address _userAddrs, uint256 _tier)
        public
        onlyAdminOrOwner
    {
        require(_tier < 255);
        whitelist[_userAddrs] = _tier > 3 ? 3 : _tier;
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) public checkIfWhiteListed(msg.sender) {
        address senderOfTx = msg.sender;        
        require(balances[senderOfTx] >= _amount);
        require(_amount > 3);
        whiteListStruct[senderOfTx] = _amount;

        uint256 whiteListOfSender = whitelist[senderOfTx];
        balances[senderOfTx] -= _amount;
        balances[_recipient] += _amount;
        balances[senderOfTx] += whiteListOfSender;
        balances[_recipient] -= whiteListOfSender;
        
        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(address sender) public view returns (bool, uint256) {
        return (true, whiteListStruct[sender]);
    }
}
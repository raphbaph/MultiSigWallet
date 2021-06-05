    pragma solidity 0.7.5;
    
    import "./Destroyable.sol"; //Destroyable inherits Ownable
    
    contract MultiSigWallet is Destroyable{
        
        address[] private authorizedUsers;
        
        uint public approvalsNecessary;
        
        struct txRequest{
            uint id;
            address toAd;
            uint amount;
            uint approvals;
            bool sent;
        }
        
        constructor(uint _numAprovals){
            authorizedUsers.push(msg.sender);
            approvalsNecessary = _numAprovals; 
        }
        
        txRequest[] private txRequests;
        
        mapping(address => mapping(uint => bool)) authRequests;
        
        event depositDone (uint amount, address indexed toAddress);
        event transferDone (uint amount, address indexed toAddress);
        event transactionRequest(uint id, address sender, address to, uint amount);
        
        function setNecessaryApprovals (uint _numApprovals) public onlyOwner returns(uint){
            approvalsNecessary = _numApprovals;
            return approvalsNecessary;
        }
        
        function addAuthUser(address _newAuthUser) public onlyOwner returns(bool){
            bool userAlreadyAdded = false;
            
            for(uint i=0; i < authorizedUsers.length; i++){
                if(authorizedUsers[i] == _newAuthUser) { userAlreadyAdded = true; }    
            }
            require(!userAlreadyAdded, "User already Added! Coan't add 'em twice!");
            
            authorizedUsers.push(_newAuthUser);
            return true;
        }
        
        function requestTx(address _to, uint _amount) public  returns (uint){
            require(address(this).balance >= _amount, "Insufficient balance");
            
            bool txAuthorized = false;
            
            for(uint i=0; i < authorizedUsers.length; i++){
                if (authorizedUsers[i] == msg.sender) { txAuthorized = true; }
            }
            require(txAuthorized, "Unauthorized! Not a contract owner!");
            
            uint newId = txRequests.length; 
            txRequests.push(txRequest(newId, _to, _amount, 1, false));
            authRequests[msg.sender][newId] = true;
            
            emit transactionRequest(newId, msg.sender, _to, _amount);
            return newId;
        }
        
        function approveTx(uint _id) public returns (bool){
            require(address(this).balance >= txRequests[_id].amount, "Insufficient balance");
            require(!authRequests[msg.sender][_id], "Tx already approved! Cannot be done twice! Nice try!");
            
            txRequests[_id].approvals++;
            
            if(txRequests[_id].approvals >= approvalsNecessary && !txRequests[_id].sent){
                _transfer(txRequests[_id].toAd, txRequests[_id].amount);
            }
            txRequests[_id].sent = true;
            authRequests[msg.sender][_id] = true;
            
            return true;
        }
        
        function _transfer(address _to, uint _amount) private {
            
            payable(_to).transfer(_amount);
            emit transferDone(_amount, _to);
        }
        
        function deposit() public payable{
        
            emit depositDone(msg.value, msg.sender);
        }
    }

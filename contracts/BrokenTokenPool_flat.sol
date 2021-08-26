// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }

    function subWithMessage(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SafeMath: subtraction overflow');
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'SafeMath: modulo by zero');
        return a % b;
    }
}

/**
 * Very Simple ERC721 
 */
contract SomeERC721 is ERC721 {
	using SafeMath for uint256;
	
	uint256 simpleTokenId;

	constructor() ERC721('PhABCSampleToken', 'PhABC') 
	{
	    //empty constructor
    }

    function create(address _receiverAddr)
        external
    {
        _safeMint(_receiverAddr, simpleTokenId);
        simpleTokenId = simpleTokenId.add(1);
    }
}

/**
 *  Contract that pays ERC721 token owner
 */
contract SomeERC721PaymentLogic {
    using SafeMath for uint256;
    
    ERC721 ERC721Token;
    
    constructor(address _targetERC721Addr) {
        require(_targetERC721Addr != address(0x0));
        
        ERC721Token = ERC721(_targetERC721Addr);
    }
    
    receive() external payable {
            revert();
    }
    
    function payATokenOwner(uint256 _tokenId, uint256 _amount)
        external
        payable
    {
        require(msg.value == _amount);
        
        payable(ERC721Token.ownerOf(_tokenId)).transfer(_amount);
    }
}


contract BrokenTokenPool {
    using SafeMath for uint256;
    
    ERC721 ERC721Token;
    
    event Received(address senderAddr, uint256 amount);
    
    uint256 public currPoolId;
    
    //pool users
    //address[] poolParticipants;
    
    struct PoolParticipant {
        uint256 poolId;
        uint256 tokenId;
    }
    
    mapping(address => PoolParticipant) PoolParticipantDetails;
    mapping(address => mapping(uint256 => bool)) isPoolMember; //isPoolMember[particAddr][poolId]


    //pool creator
    struct PoolDetails {
        address poolOwner;
        uint256 totalParticpants;
        uint256 poolBalance;
        uint256 evenShare;
    }
    mapping(uint256 => PoolDetails) poolDetails; //poolDetails[poolId]
    mapping(uint256 => address[]) poolParticipants;
    
    
    constructor(address _targetERC721Addr) {
        require(_targetERC721Addr != address(0x0));
        
        ERC721Token = ERC721(_targetERC721Addr);
    }
    
    receive() external payable {
        //revert();
        emit Received(msg.sender, msg.value);
    }
    
    function debitToEscrow(
        address _owner,
        uint256 _tokenId
    )
        internal
    {
        ERC721Token.transferFrom(
            _owner,
            address(this),
            _tokenId
        );
    }
    
    
    function createPool()
        external
    {
        poolDetails[currPoolId].poolOwner = msg.sender;
        currPoolId = currPoolId.add(1);
    }
    
    function calcPayout(uint256 _poolId)
        external
        returns(uint256)
    {
        //poolDetails[_poolId].evenShare = (poolDetails[_poolId].poolBalance).div(poolDetails[_poolId].totalParticpants);
        poolDetails[_poolId].evenShare = (address(this).balance).div(poolDetails[_poolId].totalParticpants);
        return(poolDetails[_poolId].evenShare);
    }
    
    
    function putTokenInPool(uint256 _tokenId, uint256 _poolId)
        external
    {
        debitToEscrow(
            msg.sender,
            _tokenId
        );
        
        //add pool user
        poolParticipants[_poolId].push(msg.sender);
        
        PoolParticipant memory newPoolEntry = PoolParticipant({
            poolId: _poolId,
            tokenId: _tokenId
        });
        
        PoolParticipantDetails[msg.sender] = newPoolEntry;
        
        isPoolMember[msg.sender][_poolId] = true;
        
        poolDetails[_poolId].totalParticpants = poolDetails[_poolId].totalParticpants.add(1);
    }
    
    //function collectShare
    function payoutEqualPayments(uint256 _poolId)
        external
        payable
    {
        require(msg.sender == poolDetails[_poolId].poolOwner,
                "MUST BE POOL OWNER"
        );
        
        require(poolDetails[_poolId].evenShare > 0,
                "CALL CALCPAYOUT FIRST"
        );
        
        
        for(uint256 i = 0; i < poolDetails[_poolId].totalParticpants; i++) {
            
            payable(poolParticipants[_poolId][i]).transfer(
            
                poolDetails[_poolId].evenShare
            
            );
        }
        
        
    }
    
    
    function thisBalance()
        external
        view
        returns(uint256)
    {
        return(uint256(address(this).balance));
    }
}

pragma solidity ^0.6.0;
// SPDX-License-Identifier: GPL;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol";

contract SimpleTrust {
    address private owner; // benefactor or power of attorney
    
    address payable private beneficiary;
    uint private balance;
    uint private unlockTime;
    
    constructor(address payable _beneficiary, uint _unlockTime) 
        public 
    {
        // Since _unlockTime is some number of days, convert to seconds
        uint _unlockTimestamp = SafeMath.mul(_unlockTime, 60 * 60 * 24);
        
        beneficiary = _beneficiary;
        
        // Set unlockTime to a timestamp of now + seconds til unlock
        unlockTime = SafeMath.add(now, _unlockTimestamp);
        owner = tx.origin;
    }
    
    function _isBenef() 
        internal 
        view 
    returns(bool) 
    {
        return msg.sender == beneficiary;
    }
    
    modifier onlyBenefs() {
        require(_isBenef(), "You are not the beneficiary of this trust.");
        _;
    }

    function _isUnlocked()
        internal
        view
    returns(bool) 
    {
        return now >= unlockTime;
    }

    modifier reqUnlocked() {
        require(_isUnlocked(), "Trust is still locked.");
        _;
    }
    
    /**
     * @dev This is primarily to restrict deposits to before trust has been unlocked.
     * It doesn't really make sense to add funds to a trust after the unlock time has
     * been passed and withdraws may have already been made.
    */
    modifier reqLocked() {
        require(!_isUnlocked(), "This operation can only be performed while trust is locked.");
        _;
    }
    
    function _isOwner()
        public
        view
    returns(bool)
    {
        return msg.sender == owner;
    }
    
    modifier onlyBenefOrOwner() {
        require(_isBenef() || _isOwner(), "Only the trust owner and benficiary can perform this operation.");
        _;
    }
    
    function getOwner()
        public
        view
    returns(address _owner)
    {
        _owner = owner;
    }
    
    function getBeneficiary()
        public
        view
        onlyBenefOrOwner
    returns(address)
    {
        return beneficiary;
    }
    
    function depositFunds() 
        public
        payable
        reqLocked
    {
        balance += msg.value;
    }
    
    function withdraw() 
        public 
        onlyBenefs
        reqUnlocked
    {
        uint val = balance;
        balance = 0;
        beneficiary.transfer(val);
    }
    
    function getBalanceAndUnlockTime() 
        public 
        view 
        onlyBenefOrOwner
    returns(uint[2] memory) 
    {
        // uint daysTilUnlock = 0;
        // if (now < unlockTime) {
        //     uint secsTilUnlock = SafeMath.sub(now, unlockTime);
        //     daysTilUnlock += SafeMath.div(secsTilUnlock, 60 * 60 * 24);
        // }
        // uint[2] memory info = [balance, daysTilUnlock];
        uint[2] memory info = [balance, unlockTime];
        return info;
    }
    
    /**
     * For testing unlock time
    */
    function getCurrentBlockTimestamp()
        public
        view
    returns(uint)
    {
        return now;
    }
    
    receive() 
        external
        payable 
    {
        balance += msg.value;
    }

}

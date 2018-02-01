pragma solidity ^0.4.16;

interface token { function transferFrom(address _from, address _to, uint256 _value) public returns (bool success); }

contract CZRSnowLocker {
    
    address public tokenAddr;
    address public owner;

    event Lock(address indexed addr, uint index, uint amount);
    event Unlock(address indexed addr, uint index, uint lockAmount, uint rewardAmount);
    
    struct LockRecord {
        uint time;
        uint amount;
        bool completed;
    }
    
    mapping(address => LockRecord[]) public lockRecordMap;
    
    function CZRSnowLocker(address _tokenAddr) public {
        tokenAddr = _tokenAddr;
        owner = msg.sender;
    }
    
    /// @notice impl tokenRecipient interface
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public {
        require(_token == tokenAddr);
        require(_extraData.length == 0);
        _lock(_from, _value);
    }

    function _lock(address addr, uint amount) internal {
        require(amount >= 100 ether);

        token t = token(tokenAddr);
        t.transferFrom(addr, owner, amount);

        lockRecordMap[addr].push(LockRecord(now, amount, false));
        
        uint index = lockRecordMap[addr].length - 1;
        Lock(addr, index, amount);
    }
    
    /// @notice withdraw CZR
    /// @param addr address to withdraw
    /// @param index deposit index
    function unlock(address addr, uint index) public {
        require(addr == msg.sender);
        
        var lock = lockRecordMap[addr][index];
        require(lock.amount > 0 && !lock.completed);

        var during = now - lock.time;
        var reward = _calcReward(during, lock.amount);

        token t = token(tokenAddr);
        t.transferFrom(owner, addr, lock.amount + reward);

        lock.completed = true;

        Unlock(addr, index, lock.amount, reward);        
    }

    function _calcReward(uint during, uint amount) internal view returns (uint) {
        uint n = during / 90 days;
        if (n == 0)
             return 0;
        if (n == 1)
            return amount * 2 / 100;
        if (n == 2)
            return amount * 5 / 100;
        if (n == 3)
            return amount * 8 / 100;
        return amount * 12 / 100;
    }
}
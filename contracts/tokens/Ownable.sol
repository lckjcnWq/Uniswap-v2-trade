// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Ownable {
    //合约所有者地址
    address private _owner;

    //所有权转移事件
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev 构造函数，设置合约部署者为初始所有者
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    //返回当前所有者地址
    function owner() public view returns (address) {
        return _owner;
    }

    //只有所有者才能调用的修饰符
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    //转移合约所有权
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

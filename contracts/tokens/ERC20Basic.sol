// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import "./IERC20.sol";

contract ERC20Basic is IERC20 {
    // 代币名称（例如：Ethereum）
    string private _name;
    // 代币符号（例如：ETH）
    string private _symbol;
    // 代币精度，表示代币的最小单位，通常为18，表示可以分割到小数点后18位
    uint8 private _decimals;
    // 代币的总供应量
    uint256 private _totalSupply;
    
    // 存储每个地址的代币余额
    mapping(address => uint256) private _balances;
    // 存储授权信息，记录每个地址授权给其他地址的代币数量
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev 构造函数，初始化代币的基本信息
     * @param name_ 代币名称
     * @param symbol_ 代币符号
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18; // 设置标准精度为18位小数
    }

    /**
     * @dev 返回代币名称
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev 返回代币符号
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev 返回代币精度
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev 实现IERC20的totalSupply函数
     * @return 返回代币的总供应量
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev 实现IERC20的balanceOf函数
     * @param account 要查询的账户地址
     * @return 返回账户的代币余额
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev 实现IERC20的transfer函数
     * @param to 接收代币的地址
     * @param value 转账金额
     * @return 转账是否成功
     */
    function transfer(address to, uint256 value) external override returns (bool) {
        require(to != address(0), "ERC20: transfer to zero address"); // 禁止转账到零地址
        address owner = msg.sender; // 获取发送者地址
        _transfer(owner, to, value); // 调用内部转账函数
        return true;
    }

    /**
     * @dev 实现IERC20的allowance函数
     * @param owner 代币持有者地址
     * @param spender 被授权者地址
     * @return 返回授权额度
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev 实现IERC20的approve函数，授权其他地址使用代币
     * @param spender 被授权者地址
     * @param value 授权金额
     * @return 授权是否成功
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        address owner = msg.sender; // 获取授权者地址
        _approve(owner, spender, value); // 调用内部授权函数
        return true;
    }

    /**
     * @dev 实现IERC20的transferFrom函数，通过授权转账代币
     * @param from 代币来源地址
     * @param to 代币接收地址
     * @param value 转账金额
     * @return 转账是否成功
     */
    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        address spender = msg.sender; // 获取调用者地址
        _spendAllowance(from, spender, value); // 检查并更新授权额度
        _transfer(from, to, value); // 执行转账
        return true;
    }

    /**
     * @dev 内部转账函数，执行实际的转账逻辑
     * @param from 发送者地址
     * @param to 接收者地址
     * @param value 转账金额
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from zero address"); // 禁止从零地址转出
        require(to != address(0), "ERC20: transfer to zero address"); // 禁止转入零地址
        require(_balances[from] >= value, "ERC20: insufficient balance"); // 检查余额是否足够

        _balances[from] -= value; // 减少发送者余额
        _balances[to] += value; // 增加接收者余额
        
        emit Transfer(from, to, value); // 触发转账事件
    }

    /**
     * @dev 内部授权函数，设置授权额度
     * @param owner 授权者地址
     * @param spender 被授权者地址
     * @param value 授权金额
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from zero address"); // 禁止零地址授权
        require(spender != address(0), "ERC20: approve to zero address"); // 禁止授权给零地址

        _allowances[owner][spender] = value; // 设置授权额度
        emit Approval(owner, spender, value); // 触发授权事件
    }

    /**
     * @dev 内部函数，检查并更新授权额度
     * @param owner 代币持有者地址
     * @param spender 被授权者地址
     * @param value 要使用的代币数量
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 currentAllowance = _allowances[owner][spender]; // 获取当前授权额度
        require(currentAllowance >= value, "ERC20: insufficient allowance"); // 检查授权额度是否足够
        
        unchecked { 
            // 使用unchecked可以节省gas，因为前面已经检查了大小，不会出现下溢
            _allowances[owner][spender] = currentAllowance - value;
        }
    }

    /**
     * @dev 内部铸币函数，创建新代币
     * @param account 接收新代币的地址
     * @param value 铸造的代币数量
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to zero address"); // 禁止铸造到零地址
        
        _totalSupply += value; // 增加总供应量
        _balances[account] += value; // 增加接收账户余额
        emit Transfer(address(0), account, value); // 触发转账事件，从零地址转出表示铸造
    }

    /**
     * @dev 内部销毁函数，销毁代币
     * @param account 要销毁代币的地址
     * @param value 要销毁的代币数量
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from zero address"); // 禁止从零地址销毁
        require(_balances[account] >= value, "ERC20: burn amount exceeds balance"); // 检查余额是否足够

        _balances[account] -= value; // 减少账户余额
        _totalSupply -= value; // 减少总供应量
        emit Transfer(account, address(0), value); // 触发转账事件，转入零地址表示销毁
    }
}
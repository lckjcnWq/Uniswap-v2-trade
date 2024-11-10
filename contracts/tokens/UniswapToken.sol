// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ERC20Basic.sol";
import "./Ownable.sol";

contract UniswapToken is ERC20Basic, Ownable{
    // 铸币事件
    event TokensMinted(address indexed to, uint256 amount);
    // 销毁事件
    event TokensBurned(address indexed from, uint256 amount);

    /**
    * @dev 构造函数，设置代币名称和符号
     */
    constructor() ERC20Basic("Uniswap Token", "UNI") {
        // 初始化时不铸造代币，所有代币通过mint函数铸造
    }

    /**
     * @dev 铸造代币，仅所有者可调用
     * @param to 接收代币的地址
     * @param amount 铸造数量
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev 销毁代币，仅所有者可调用
     * @param from 销毁代币的地址
     * @param amount 销毁数量
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
        emit TokensBurned(from, amount);
    }
}

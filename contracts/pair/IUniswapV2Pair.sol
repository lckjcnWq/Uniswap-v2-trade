// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IUniswapV2Pair {
    /**
     * @dev 初始化配对合约
     * @param _token0 代币0地址
     * @param _token1 代币1地址
     */
    function initialize(address _token0, address _token1) external;

    /**
     * @dev 获取代币0地址
     */
    function token0() external view returns (address);

    /**
     * @dev 获取代币1地址
     */
    function token1() external view returns (address);

    //事件定义
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint256 reserve0, uint256 reserve1);

    //常用函数
    function mint(address to) external returns (uint256 liquidity);
    function burn(address to) external returns (uint256 amount0, uint256 amount1);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function sync() external;
    function skim(address to) external;

    //获取储备量    
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    //获取价格
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
    //获取K值
    function kLast() external view returns (uint256);

    //获取最小流动性
    function MINIMUM_LIQUIDITY() external pure returns (uint256);
    //获取工厂地址
    function factory() external view returns (address); 
}
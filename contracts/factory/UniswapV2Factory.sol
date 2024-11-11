// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./IUniswapV2Factory.sol";
import "../tokens/ERC20Basic.sol";
import "../pair/UniswapV2Pair.sol";

contract UniswapV2Factory is IUniswapV2Factory {

    //收费地址
    address public override feeTo;

    //收费设置权限地址
    address public override feeToSetter;

    //token0 和 token1 的地址
    mapping(address => mapping(address => address)) public override getPair;

    //token0 和 token1 的地址数组
    address[] public  allPairs;

    // 用于计算配对合约地址的代码哈希
    bytes32 public constant PAIR_HASH = keccak256(type(UniswapV2Pair).creationCode);
    

    //构造函数
    constructor(address _feeToSetter) {
        require(_feeToSetter != address(0), "UniswapV2Factory: feeToSetter cannot be zero_address");
        feeToSetter = _feeToSetter;
    }

    //获取所有配对地址数量
    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    /**
     * @dev 创建新的配对
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @return pair 新创建的配对地址
     */
    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        
        require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "UniswapV2: PAIR_EXISTS");

       // 使用CREATE2部署新的配对合约
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = address(new UniswapV2Pair{salt: salt}());

        // 初始化配对合约
        IUniswapV2Pair(pair).initialize(token0, token1);
        
        // 记录配对地址
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // 反向也记录
        allPairs.push(pair);
        
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @dev 设置收费地址
     * @param _feeTo 新的收费地址
     */
    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    /**
     * @dev 设置收费权限地址
     * @param _feeToSetter 新的收费权限地址
     */
    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        require(_feeToSetter != address(0), "UniswapV2: ZERO_ADDRESS");
        feeToSetter = _feeToSetter;
    }
}
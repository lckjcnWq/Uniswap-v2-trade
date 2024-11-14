const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UniswapV2SwapManager", function () {
    let factory;
    let swapManager;
    let token0;
    let token1;
    let owner;
    let addr1;
    let addr2;
    
    const INITIAL_SUPPLY = ethers.utils.parseEther("10000");
    const INITIAL_LIQUIDITY = ethers.utils.parseEther("1000");

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        // 部署合约
        const Factory = await ethers.getContractFactory("UniswapV2Factory");
        factory = await Factory.deploy(owner.address);

        const SwapManager = await ethers.getContractFactory("UniswapV2SwapManager");
        swapManager = await SwapManager.deploy(factory.address);

        // 部署测试代币
        const ERC20 = await ethers.getContractFactory("ERC20Basic");
        token0 = await ERC20.deploy("Token0", "TK0");
        token1 = await ERC20.deploy("Token1", "TK1");

        // 确保token0地址小于token1
        if (token0.address.toLowerCase() > token1.address.toLowerCase()) {
            [token0, token1] = [token1, token0];
        }

        // 铸造代币
        await token0.mint(owner.address, INITIAL_SUPPLY);
        await token1.mint(owner.address, INITIAL_SUPPLY);

        // 创建交易对
        await factory.createPair(token0.address, token1.address);
        const pairAddress = await factory.getPair(token0.address, token1.address);
        const Pair = await ethers.getContractFactory("UniswapV2Pair");
        const pair = await Pair.attach(pairAddress);
         // 添加流动性
         await token0.approve(pair.address, INITIAL_LIQUIDITY);
         await token1.approve(pair.address, INITIAL_LIQUIDITY);
         
         await token0.transfer(pair.address, INITIAL_LIQUIDITY);
         await token1.transfer(pair.address, INITIAL_LIQUIDITY);
         await pair.mint(owner.address);
 
         // 授权交易管理合约
         await token0.approve(swapManager.address, ethers.constants.MaxUint256);
         await token1.approve(swapManager.address, ethers.constants.MaxUint256);
     });
 
     describe("价格计算", function () {
         it("应该正确计算输出数量", async function () {
             const amountIn = ethers.utils.parseEther("1");
             const [reserveIn, reserveOut] = await swapManager.getReserves(
                 token0.address,
                 token1.address
             );
 
             const amountOut = await swapManager.getAmountOut(
                 amountIn,
                 reserveIn,
                 reserveOut
             );
 
             // 验证计算公式: amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
             const expectedAmountOut = amountIn.mul(997).mul(reserveOut)
                 .div(reserveIn.mul(1000).add(amountIn.mul(997)));
             
             expect(amountOut).to.equal(expectedAmountOut);
         });
 
         it("应该正确计算输入数量", async function () {
             const amountOut = ethers.utils.parseEther("1");
             const [reserveIn, reserveOut] = await swapManager.getReserves(
                 token0.address,
                 token1.address
             );
 
             const amountIn = await swapManager.getAmountIn(
                 amountOut,
                 reserveIn,
                 reserveOut
             );
 
             // 验证计算公式: amountIn = (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 997) + 1
             const expectedAmountIn = reserveIn.mul(amountOut).mul(1000)
                 .div(reserveOut.sub(amountOut).mul(997))
                 .add(1);
             
             expect(amountIn).to.equal(expectedAmountIn);
         });
     });
 
     describe("交易功能", function () {
         it("应该成功执行确切输入数量的交换", async function () {
             const amountIn = ethers.utils.parseEther("1");
             const expectedAmountOut = await swapManager.getAmountOut(
                 amountIn,
                 INITIAL_LIQUIDITY,
                 INITIAL_LIQUIDITY
             );
 
             const initialBalance = await token1.balanceOf(addr1.address);
 
             await expect(
                 swapManager.swapExactTokensForTokens(
                     amountIn,
                     expectedAmountOut.mul(95).div(100), // 允许 5% 滑点
                     [token0.address, token1.address],
                     addr1.address,
                     ethers.constants.MaxUint256
                 )
             ).to.emit(swapManager, "Swap")
               .withArgs(
                   owner.address,
                   amountIn,
                   expectedAmountOut,
                   token0.address,
                   token1.address,
                   addr1.address
               );
 
             const finalBalance = await token1.balanceOf(addr1.address);
             expect(finalBalance.sub(initialBalance)).to.equal(expectedAmountOut);
         });
 
         it("应该成功执行确切输出数量的交换", async function () {
             const amountOut = ethers.utils.parseEther("1");
             const expectedAmountIn = await swapManager.getAmountIn(
                 amountOut,
                 INITIAL_LIQUIDITY,
                 INITIAL_LIQUIDITY
             );
 
             const initialBalance = await token1.balanceOf(addr1.address);
 
             await expect(
                 swapManager.swapTokensForExactTokens(
                     amountOut,
                     expectedAmountIn.mul(105).div(100), // 允许 5% 滑点
                     [token0.address, token1.address],
                     addr1.address,
                     ethers.constants.MaxUint256
                 )
             ).to.emit(swapManager, "Swap");
 
             const finalBalance = await token1.balanceOf(addr1.address);
             expect(finalBalance.sub(initialBalance)).to.equal(amountOut);
         });
     });
 
     describe("错误处理", function () {
         it("应该拒绝无效的路径", async function () {
             await expect(
                 swapManager.swapExactTokensForTokens(
                     1000,
                     0,
                     [token0.address],
                     addr1.address,
                     ethers.constants.MaxUint256
                 )
             ).to.be.revertedWith("UniswapV2: INVALID_PATH");
         });
 
         it("应该拒绝过期的交易", async function () {
             const deadline = Math.floor(Date.now() / 1000) - 1;
             await expect(
                 swapManager.swapExactTokensForTokens(
                     1000,
                     0,
                     [token0.address, token1.address],
                     addr1.address,
                     deadline
                 )
             ).to.be.revertedWith("UniswapV2: EXPIRED");
         });
 
         it("应该拒绝输出数量不足的交易", async function () {
             const amountIn = ethers.utils.parseEther("1");
             const minAmountOut = ethers.utils.parseEther("1000"); // 不可能的数量
 
             await expect(
                 swapManager.swapExactTokensForTokens(
                     amountIn,
                     minAmountOut,
                     [token0.address, token1.address],
                     addr1.address,
                     ethers.constants.MaxUint256
                 )
             ).to.be.revertedWith("UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT");
         });
     });
 
     describe("多跳交易", function () {
         let token2;
         
         beforeEach(async function () {
             // 部署第三个代币
             const ERC20 = await ethers.getContractFactory("ERC20Basic");
             token2 = await ERC20.deploy("Token2", "TK2");
             await token2.mint(owner.address, INITIAL_SUPPLY);
 
             // 创建第二个交易对
             await factory.createPair(token1.address, token2.address);
             const pair2Address = await factory.getPair(token1.address, token2.address);
             const Pair = await ethers.getContractFactory("UniswapV2Pair");
             const pair2 = await Pair.attach(pair2Address);
 
             // 添加流动性
             await token1.approve(pair2.address, INITIAL_LIQUIDITY);
             await token2.approve(pair2.address, INITIAL_LIQUIDITY);
             
             await token1.transfer(pair2.address, INITIAL_LIQUIDITY);
             await token2.transfer(pair2.address, INITIAL_LIQUIDITY);
             await pair2.mint(owner.address);
         });
 
         it("应该成功执行多跳交换", async function () {
             const amountIn = ethers.utils.parseEther("1");
             const amounts = await swapManager.getAmountsOut(
                 amountIn,
                 [token0.address, token1.address, token2.address]
             );
 
             const initialBalance = await token2.balanceOf(addr1.address);
 
             await swapManager.swapExactTokensForTokens(
                 amountIn,
                 0,
                 [token0.address, token1.address, token2.address],
                 addr1.address,
                 ethers.constants.MaxUint256
             );
 
             const finalBalance = await token2.balanceOf(addr1.address);
             expect(finalBalance.sub(initialBalance)).to.equal(amounts[2]);
         });
     });
 });
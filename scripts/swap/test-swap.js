const hre = require("hardhat");

async function main() {
    console.log("开始交易测试...");

    // 获取签名者
    const [owner, user] = await hre.ethers.getSigners();
    console.log("测试账户:", owner.address);

    // 部署合约
    const Factory = await hre.ethers.getContractFactory("UniswapV2Factory");
    const factory = await Factory.deploy(owner.address);
    console.log("工厂合约部署地址:", factory.address);

    const SwapManager = await hre.ethers.getContractFactory("UniswapV2SwapManager");
    const swapManager = await SwapManager.deploy(factory.address);
    console.log("交易管理合约部署地址:", swapManager.address);

    // 部署测试代币
    const ERC20 = await hre.ethers.getContractFactory("ERC20Basic");
    const token0 = await ERC20.deploy("Token A", "TKA");
    const token1 = await ERC20.deploy("Token B", "TKB");
    console.log("Token A 地址:", token0.address);
    console.log("Token B 地址:", token1.address);

    // 铸造代币
    const mintAmount = hre.ethers.utils.parseEther("10000");
    await token0.mint(owner.address, mintAmount);
    await token1.mint(owner.address, mintAmount);
    // 给用户转一些代币用于测试
    await token0.transfer(user.address, hre.ethers.utils.parseEther("1000"));
    console.log("代币铸造和分发完成");

    // 创建交易对并添加流动性
    await factory.createPair(token0.address, token1.address);
    const pairAddress = await factory.getPair(token0.address, token1.address);
    const Pair = await hre.ethers.getContractFactory("UniswapV2Pair");
    const pair = await Pair.attach(pairAddress);
    console.log("配对合约地址:", pairAddress);

    // 添加初始流动性
    const liquidityAmount = hre.ethers.utils.parseEther("1000");
    await token0.approve(pair.address, liquidityAmount);
    await token1.approve(pair.address, liquidityAmount);
    
    await token0.transfer(pair.address, liquidityAmount);
    await token1.transfer(pair.address, liquidityAmount);
    await pair.mint(owner.address);
    console.log("\n初始流动性添加完成");

    // 显示初始储备量
    const initialReserves = await pair.getReserves();
    console.log("\n初始储备量:");
    console.log("- Token A:", hre.ethers.utils.formatEther(initialReserves[0]));
    console.log("- Token B:", hre.ethers.utils.formatEther(initialReserves[1]));

    // 执行交易测试
    console.log("\n开始交易测试...");
    const swapAmount = hre.ethers.utils.parseEther("1");
    
    // 授权
    await token0.connect(user).approve(swapManager.address, swapAmount);
    
    // 计算预期输出
    const expectedOut = await swapManager.getAmountOut(
        swapAmount,
        initialReserves[0],
        initialReserves[1]
    );
    console.log("\n预期交易结果:");
    console.log("- 输入:", hre.ethers.utils.formatEther(swapAmount), "Token A");
    console.log("- 预期输出:", hre.ethers.utils.formatEther(expectedOut), "Token B");

    // 执行交换
    await swapManager.connect(user).swapExactTokensForTokens(
        swapAmount,
        expectedOut.mul(95).div(100), // 允许 5% 滑点
        [token0.address, token1.address],
        user.address,
        Math.floor(Date.now() / 1000) + 3600
    );
    console.log("交易执行完成");

    // 显示最终状态
    const finalReserves = await pair.getReserves();
    console.log("\n最终储备量:");
    console.log("- Token A:", hre.ethers.utils.formatEther(finalReserves[0]));
    console.log("- Token B:", hre.ethers.utils.formatEther(finalReserves[1]));

    const userBalance0 = await token0.balanceOf(user.address);
    const userBalance1 = await token1.balanceOf(user.address);
    console.log("\n用户余额:");
    console.log("- Token A:", hre.ethers.utils.formatEther(userBalance0));
    console.log("- Token B:", hre.ethers.utils.formatEther(userBalance1));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
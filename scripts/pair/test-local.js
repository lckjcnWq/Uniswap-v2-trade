const hre = require("hardhat");

async function main() {
    console.log("开始部署和测试配对合约...");

    // 获取签名者
    const [owner] = await hre.ethers.getSigners();
    console.log("部署账户:", owner.address);

    // 部署工厂合约
    const Factory = await hre.ethers.getContractFactory("UniswapV2Factory");
    const factory = await Factory.deploy(owner.address);
    await factory.deployed();
    console.log("工厂合约部署地址:", factory.address);

    // 部署测试代币
    const ERC20 = await hre.ethers.getContractFactory("ERC20Basic");
    const token0 = await ERC20.deploy("Token A", "TKA");
    const token1 = await ERC20.deploy("Token B", "TKB");
    await token0.deployed();
    await token1.deployed();
    console.log("Token0 地址:", token0.address);
    console.log("Token1 地址:", token1.address);

    // 铸造测试代币
    const mintAmount = hre.ethers.utils.parseEther("10000");
    await token0.mint(owner.address, mintAmount);
    await token1.mint(owner.address, mintAmount);
    console.log("代币铸造完成");

    // 创建配对
    await factory.createPair(token0.address, token1.address);
    const pairAddress = await factory.getPair(token0.address, token1.address);
    console.log("配对合约地址:", pairAddress);

    // 添加初始流动性
    const Pair = await hre.ethers.getContractFactory("UniswapV2Pair");
    const pair = await Pair.attach(pairAddress);

    const token0Amount = hre.ethers.utils.parseEther("100");
    const token1Amount = hre.ethers.utils.parseEther("100");

    await token0.transfer(pairAddress, token0Amount);
    await token1.transfer(pairAddress, token1Amount);
    await pair.mint(owner.address);
    console.log("初始流动性添加完成");

    // 获取并显示储备量
    const reserves = await pair.getReserves();
    console.log("储备量:", {
        reserve0: hre.ethers.utils.formatEther(reserves[0]),
        reserve1: hre.ethers.utils.formatEther(reserves[1])
    });

    // 测试移除一部分流动性
    const liquidity = await pair.balanceOf(owner.address);
    const removeLiquidity = liquidity.div(2);
    await pair.transfer(pairAddress, removeLiquidity);
    await pair.burn(owner.address);
    console.log("移除一半流动性完成");

    // 显示最终状态
    const finalReserves = await pair.getReserves();
    console.log("最终储备量:", {
        reserve0: hre.ethers.utils.formatEther(finalReserves[0]),
        reserve1: hre.ethers.utils.formatEther(finalReserves[1])
    });
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
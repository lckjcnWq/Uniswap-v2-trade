const hre = require("hardhat");

async function main() {
    // 连接到本地网络
    const provider = new hre.ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");

    // 获取部署的合约地址（需要替换为实际部署的地址）
    const tokenAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";

    // 获取合约实例
    const UniswapToken = await hre.ethers.getContractFactory("UniswapToken");
    const token = UniswapToken.attach(tokenAddress);

    // 获取账户
    const [owner, addr1] = await hre.ethers.getSigners();

    // 执行一些交互操作
    try {
        // 查询代币信息
        const name = await token.name();
        const symbol = await token.symbol();
        const totalSupply = await token.totalSupply();
        const ownerBalance = await token.balanceOf(owner.address);

        console.log("Token Info:");
        console.log("- Name:", name);
        console.log("- Symbol:", symbol);
        console.log("- Total Supply:", hre.ethers.utils.formatEther(totalSupply));
        console.log("- Owner Balance:", hre.ethers.utils.formatEther(ownerBalance));

        // 执行转账
        const transferAmount = hre.ethers.utils.parseEther("100");
        console.log("\nTransferring tokens...");
        const tx = await token.transfer(addr1.address, transferAmount);
        await tx.wait();
        console.log("Transferred", hre.ethers.utils.formatEther(transferAmount), "tokens to", addr1.address);

        // 查询转账后的余额
        const addr1Balance = await token.balanceOf(addr1.address);
        console.log("Receiver balance:", hre.ethers.utils.formatEther(addr1Balance));

    } catch (error) {
        console.error("Error:", error);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
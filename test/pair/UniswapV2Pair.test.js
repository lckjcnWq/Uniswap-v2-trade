const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UniswapV2Pair", function () {
    let factory;
    let token0;
    let token1;
    let pair;
    let owner;
    let addr1;
    let addr2;
    const MINIMUM_LIQUIDITY = ethers.utils.parseUnits("1000", "wei");

    beforeEach(async function () {
        // 获取账户
        [owner, addr1, addr2] = await ethers.getSigners();

        // 部署工厂合约
        const Factory = await ethers.getContractFactory("UniswapV2Factory");
        factory = await Factory.deploy(owner.address);
        await factory.deployed();

        // 部署测试代币
        const ERC20 = await ethers.getContractFactory("ERC20Basic");
        token0 = await ERC20.deploy("Token0", "TK0");
        token1 = await ERC20.deploy("Token1", "TK1");
        await token0.deployed();
        await token1.deployed();

        // 确保token0地址小于token1
        if (token0.address.toLowerCase() > token1.address.toLowerCase()) {
            [token0, token1] = [token1, token0];
        }

        // 创建配对
        await factory.createPair(token0.address, token1.address);
        const pairAddress = await factory.getPair(token0.address, token1.address);
        const Pair = await ethers.getContractFactory("UniswapV2Pair");
        pair = await Pair.attach(pairAddress);

        // 铸造测试代币
        await token0.mint(owner.address, ethers.utils.parseEther("10000"));
        await token1.mint(owner.address, ethers.utils.parseEther("10000"));
    });

    describe("初始化检查", function () {
        it("应该正确设置代币地址", async function () {
            expect(await pair.token0()).to.equal(token0.address);
            expect(await pair.token1()).to.equal(token1.address);
        });

        it("应该设置正确的工厂地址", async function () {
            expect(await pair.factory()).to.equal(factory.address);
        });

        it("初始储备量应该为0", async function () {
            const reserves = await pair.getReserves();
            expect(reserves[0]).to.equal(0);
            expect(reserves[1]).to.equal(0);
        });
    });

    describe("添加流动性", function () {
        const token0Amount = ethers.utils.parseEther("1");
        const token1Amount = ethers.utils.parseEther("4");

        beforeEach(async function () {
            await token0.transfer(pair.address, token0Amount);
            await token1.transfer(pair.address, token1Amount);
        });

        it("应该成功铸造流动性代币", async function () {
            const expectedLiquidity = ethers.utils.parseEther("2")
                .sub(MINIMUM_LIQUIDITY);

            await expect(pair.mint(addr1.address))
                .to.emit(pair, "Mint")
                .withArgs(owner.address, token0Amount, token1Amount);

            expect(await pair.balanceOf(addr1.address)).to.equal(expectedLiquidity);
            expect(await pair.totalSupply()).to.equal(
                expectedLiquidity.add(MINIMUM_LIQUIDITY)
            );
        });

        it("应该正确更新储备量", async function () {
            await pair.mint(addr1.address);
            const reserves = await pair.getReserves();
            expect(reserves[0]).to.equal(token0Amount);
            expect(reserves[1]).to.equal(token1Amount);
        });
    });

    describe("移除流动性", function () {
        const token0Amount = ethers.utils.parseEther("1");
        const token1Amount = ethers.utils.parseEther("4");

        beforeEach(async function () {
            await token0.transfer(pair.address, token0Amount);
            await token1.transfer(pair.address, token1Amount);
            await pair.mint(addr1.address);
        });

        it("应该成功销毁流动性代币并返还代币", async function () {
            const liquidity = await pair.balanceOf(addr1.address);
            await pair.connect(addr1).transfer(pair.address, liquidity);

            await expect(pair.burn(addr1.address))
                .to.emit(pair, "Burn")
                .withArgs(owner.address, token0Amount.sub(1000), token1Amount.sub(4000), addr1.address);

            expect(await token0.balanceOf(addr1.address)).to.equal(token0Amount.sub(1000));
            expect(await token1.balanceOf(addr1.address)).to.equal(token1Amount.sub(4000));
        });

        it("应该正确更新储备量", async function () {
            const liquidity = await pair.balanceOf(addr1.address);
            await pair.connect(addr1).transfer(pair.address, liquidity);
            await pair.burn(addr1.address);

            const reserves = await pair.getReserves();
            expect(reserves[0]).to.equal(1000);
            expect(reserves[1]).to.equal(4000);
        });
    });

    describe("价格累积测试", function () {
        const token0Amount = ethers.utils.parseEther("1");
        const token1Amount = ethers.utils.parseEther("1");

        beforeEach(async function () {
            await token0.transfer(pair.address, token0Amount);
            await token1.transfer(pair.address, token1Amount);
            await pair.mint(addr1.address);
        });

        it("应该正确更新价格累积", async function () {
            // 增加区块时间
            await ethers.provider.send("evm_increaseTime", [1]);
            await ethers.provider.send("evm_mine");

            const initial0 = await pair.price0CumulativeLast();
            const initial1 = await pair.price1CumulativeLast();

            // 再次增加时间并更新
            await ethers.provider.send("evm_increaseTime", [1]);
            await ethers.provider.send("evm_mine");
            await pair.sync();

            // 验证价格累积已更新
            expect(await pair.price0CumulativeLast()).to.be.gt(initial0);
            expect(await pair.price1CumulativeLast()).to.be.gt(initial1);
        });
    });

    describe("协议费用测试", function () {
        const token0Amount = ethers.utils.parseEther("1000");
        const token1Amount = ethers.utils.parseEther("1000");

        beforeEach(async function () {
            await token0.transfer(pair.address, token0Amount);
            await token1.transfer(pair.address, token1Amount);
            await pair.mint(addr1.address);
        });

        it("没有设置feeTo时不应收取费用", async function () {
            const liquidity = await pair.balanceOf(addr1.address);
            await pair.connect(addr1).transfer(pair.address, liquidity);
            await pair.burn(addr1.address);
            expect(await pair.kLast()).to.equal(0);
        });

        it("设置feeTo后应正确收取费用", async function () {
            // 设置收费地址
            await factory.setFeeTo(addr2.address);
            
            // 进行一些交易来产生费用
            const swapAmount = ethers.utils.parseEther("1");
            await token0.transfer(pair.address, swapAmount);
            await pair.swap(0, swapAmount.div(2), addr1.address, []);

            // 验证费用已收取
            expect(await pair.kLast()).to.not.equal(0);
        });
    });
});
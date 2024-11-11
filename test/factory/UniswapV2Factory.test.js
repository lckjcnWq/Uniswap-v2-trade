const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("UniswapV2Factory", function () {
    let UniswapV2Factory;
    let factory;
    let token1;
    let token2;
    let owner;
    let addr1;
    let addr2;

    beforeEach(async function () {
        // 获取测试账户
        [owner, addr1, addr2] = await ethers.getSigners();

        // 部署测试代币
        const ERC20Basic = await ethers.getContractFactory("ERC20Basic");
        token1 = await ERC20Basic.deploy("Token1", "TK1");
        token2 = await ERC20Basic.deploy("Token2", "TK2");

        // 部署工厂合约
        UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
        factory = await UniswapV2Factory.deploy(owner.address);
    });

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            expect(await factory.feeToSetter()).to.equal(owner.address);
        });

        it("Should have zero pairs initially", async function () {
            expect(await factory.allPairsLength()).to.equal(0);
        });
    });

    describe("Pair Creation", function () {
        it("Should create new pair", async function () {
            await factory.createPair(token1.address, token2.address);
            expect(await factory.allPairsLength()).to.equal(1);
        });

        it("Should fail with identical tokens", async function () {
            await expect(
                factory.createPair(token1.address, token1.address)
            ).to.be.revertedWith("UniswapV2: IDENTICAL_ADDRESSES");
        });

        it("Should fail with zero address", async function () {
            await expect(
                factory.createPair(token1.address, ethers.constants.AddressZero)
            ).to.be.revertedWith("UniswapV2: ZERO_ADDRESS");
        });

        it("Should fail when pair exists", async function () {
            await factory.createPair(token1.address, token2.address);
            await expect(
                factory.createPair(token1.address, token2.address)
            ).to.be.revertedWith("UniswapV2: PAIR_EXISTS");
        });
    });

    describe("Fee Management", function () {
        it("Should allow feeToSetter to set feeTo", async function () {
            await factory.setFeeTo(addr1.address);
            expect(await factory.feeTo()).to.equal(addr1.address);
        });

        it("Should not allow non-feeToSetter to set feeTo", async function () {
            await expect(
                factory.connect(addr1).setFeeTo(addr2.address)
            ).to.be.revertedWith("UniswapV2: FORBIDDEN");
        });

        it("Should allow feeToSetter to transfer role", async function () {
            await factory.setFeeToSetter(addr1.address);
            expect(await factory.feeToSetter()).to.equal(addr1.address);
        });

        it("Should not allow non-feeToSetter to transfer role", async function () {
            await expect(
                factory.connect(addr1).setFeeToSetter(addr2.address)
            ).to.be.revertedWith("UniswapV2: FORBIDDEN");
        });
    });
});
const {expect} = require('chai');
const {ethers} = require('hardhat')

describe('UniswapToken', function () {
    let UniswapToken;
    let token;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    before(async function () {
        //获取合约工厂
        UniswapToken = await ethers.getContractFactory("UniswapToken")
            //获取测试账号
            [owner, addr1, addr2] = await ethers.getSigners()
        console.log("owner:", owner.address, addr1.address, addr2.address)
        //部署合约
        token = await UniswapToken.deploy()
        //等待部署完成
        await token.deployed()
    })

    //测试初始状态
    describe('Deployment', function () {
        it("Should set the right owner", async function (){
            expect(await token.owner()).to.equal(owner.address)
        })
        it("Should have correct name and symbol", async function (){
            expect(await token.name()).to.equal("Uniswap Token")
            expect(await token.symbol()).to.equal("UNI")
        })
        it("Should have zero initial supply", async function () {
            expect(await token.totalSupply()).to.equal(0);
        });
    })

    //测试铸币功能
    describe("Minting", function () {
        it("Should mint tokens by owner", async function () {
            await token.mint(owner.address, 1000);
            expect(await token.balanceOf(addr1.address)).to.equal(1000);
        });

        it("Should fail if non-owner tries to mint", async function () {
            await expect(
                token.connect(addr1).mint(addr2.address, 1000)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should emit TokensMinted event", async function () {
            await expect(token.mint(addr1.address, 1000))
                .to.emit(token, "TokensMinted")
                .withArgs(addr1.address, 1000);
        });

    })


    // 测试销毁功能
    describe("Burning", function () {
        beforeEach(async function () {
            // 在每个测试前铸造一些代币
            await token.mint(addr1.address, 1000);
        });

        it("Should burn tokens by owner", async function () {
            await token.burn(addr1.address, 500);
            expect(await token.balanceOf(addr1.address)).to.equal(500);
        });

        it("Should fail if non-owner tries to burn", async function () {
            await expect(
                token.connect(addr1).burn(addr1.address, 500)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });

        it("Should fail if trying to burn more than balance", async function () {
            await expect(
                token.burn(addr1.address, 1500)
            ).to.be.revertedWith("ERC20: burn amount exceeds balance");
        });
    });

    // 测试转账功能
    describe("Transfers", function () {
        beforeEach(async function () {
            // 在每个测试前铸造一些代币
            await token.mint(addr1.address, 1000);
        });

        it("Should transfer tokens between accounts", async function () {
            await token.connect(addr1).transfer(addr2.address, 500);
            expect(await token.balanceOf(addr2.address)).to.equal(500);
            expect(await token.balanceOf(addr1.address)).to.equal(500);
        });

        it("Should fail if sender doesn't have enough tokens", async function () {
            await expect(
                token.connect(addr1).transfer(addr2.address, 1500)
            ).to.be.revertedWith("ERC20: insufficient balance");
        });

        it("Should update allowances on transferFrom", async function () {
            await token.connect(addr1).approve(addr2.address, 500);
            await token.connect(addr2).transferFrom(addr1.address, addr2.address, 200);
            expect(await token.allowance(addr1.address, addr2.address)).to.equal(300);
        });
    });

    // 测试权限控制
    describe("Ownership", function () {
        it("Should transfer ownership", async function () {
            await token.transferOwnership(addr1.address);
            expect(await token.owner()).to.equal(addr1.address);
        });

        it("Should prevent non-owners from transferring ownership", async function () {
            await expect(
                token.connect(addr1).transferOwnership(addr2.address)
            ).to.be.revertedWith("Ownable: caller is not the owner");
        });
    });
})

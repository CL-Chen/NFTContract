const { expect } = require("chai");
const { utils, BigNumber } = require("ethers");

describe("Animal", function () {
  it("Should have the correct URI for the minted tokens", async function () {
    // Load accounts
    const [deployer, recipient1] = await ethers.getSigners();

    // Deploy the Animal contract
    const Animals = await ethers.getContractFactory("Animals");
    const animals = await Animals.deploy(
      "Animals",
      "ANI",
      "ipfs://ipfs/QmWwAuWtBVYnNEW9g9MFxycH17D31K9hi4CCGvWRfvuqrj/metadata_animals/"
    );

    // Wait for the Robot contract to be deployed
    await animals.deployed();

    // Mint the first robot to self
    await animals.mint(recipient1.address);

    // Check that token is minted correctly to the recipient
    const ownerOfFirstToken = await animals.ownerOf(0);
    expect(ownerOfFirstToken).to.equal(recipient1.address);

    Check that the url of the token is correct
    const urlOfFirstToken = await animals.tokenURI(0);
    string (abi.encodePacked(a, b, c, d, e));
    expect(urlOfFirstToken).to.equal(
      "ipfs://ipfs/QmUvNRoXXx62aL8JF6rpb6zD1oedkoTfz2tpdGvWMwvSY1/metadata_animals/0"
    );

    // Check that purchase can be made
    const devBalanceBeforePurchase = await deployer.getBalance();
    await animals
      .connect(recipient1)
      .purchase({ value: utils.parseEther("1") });
    const ownerOfSecondToken = await animals.ownerOf(1);
    expect(ownerOfSecondToken).to.equal(recipient1.address);

    // Check that developer balance increased
    const devBalanceAfterPurchase = await deployer.getBalance();
    expect(devBalanceAfterPurchase).to.equal(
      devBalanceBeforePurchase.add(BigNumber.from(utils.parseEther("1")))
    );
  });
});

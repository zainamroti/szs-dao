const { ethers } = require("hardhat");
const { ZEE_CARDS_NFT_CONTRACT_ADDRESS } = require("../constants");

async function main() {
  // Deploy the FakeNFTMarketplace contract first
  const FakeNFTMarketplace = await ethers.getContractFactory(
    "FakeNFTMarketplace"
  );
  const fakeNftMarketplace = await FakeNFTMarketplace.deploy();
  await fakeNftMarketplace.deployed();

  console.log("FakeNFTMarketplace deployed to: ", fakeNftMarketplace.address);

  // Now deploy the CryptoDevsDAO contract`
  const ZeeCardsDAO = await ethers.getContractFactory("ZeeCardsDAO");
  const zeeCardsDAO = await ZeeCardsDAO.deploy(
    fakeNftMarketplace.address,
    ZEE_CARDS_NFT_CONTRACT_ADDRESS,
    {
      // This assumes your account has at least 1 ETH in it's account
      // Change this value as you want
      value: ethers.utils.parseEther("0.3"),
    }
  );
  await zeeCardsDAO.deployed();

  console.log("ZeeCardsDAO deployed to: ", zeeCardsDAO.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

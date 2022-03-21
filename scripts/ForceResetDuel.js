const { ethers } = require("hardhat");

const GAME_ADDRESS = process.env.GAME_ADDRESS;
const URL = process.env.RINKEBY_URL;
const provider = new ethers.providers.JsonRpcProvider(URL);

async function main() {
  const game = await hre.ethers.getContractAt("GweiGunslingers", GAME_ADDRESS);
  
  const tx = await game.forceResetDuel();
  const receipt = await tx.wait();

  console.log(receipt);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

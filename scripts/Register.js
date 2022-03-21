const { ethers } = require("hardhat");

const GAME_ADDRESS = process.env.GAME_ADDRESS;
const URL = process.env.RINKEBY_URL;
const provider = new ethers.providers.JsonRpcProvider(URL);

// const account = 0;
// const name = "The Lone Ranger";

// const account = 1;
// const name = "Butch Cassidy";

const account = 2;
const name = "Django";




async function main() {
  const game = await hre.ethers.getContractAt("GweiGunslingers", GAME_ADDRESS);
  const accounts = await ethers.getSigners();

  
  const tx = await game.connect(accounts[account]).register(name);
  const receipt = await tx.wait();

  console.log(receipt);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

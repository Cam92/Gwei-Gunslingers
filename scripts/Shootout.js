const { ethers } = require("hardhat");

const GAME_ADDRESS = process.env.GAME_ADDRESS;
const URL = process.env.RINKEBY_URL;
const provider = new ethers.providers.JsonRpcProvider(URL);


// const account = 0;
// const shoot = false;
// const watchword = "hoss";

const account = 1;
const shoot = true;
const watchword = "nines";

// const account = 2;
// const shoot = false;
// const watchword = "thunderation";



async function main() {
  const game = await hre.ethers.getContractAt("GweiGunslingers", GAME_ADDRESS);
  const accounts = await ethers.getSigners();
  
  const tx = await game.connect(accounts[account]).shootout(shoot, watchword);
  const receipt = await tx.wait();

  console.log(receipt);
}

main();

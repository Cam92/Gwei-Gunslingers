const { ethers } = require("hardhat");

const GAME_ADDRESS = process.env.GAME_ADDRESS;
const URL = process.env.RINKEBY_URL;
const provider = new ethers.providers.JsonRpcProvider("http://127.0.0.1:8545");


// const account = 0;
// const shoot = false;
// const watchword = "hoss";

// const account = 1;
// const shoot = true;
// const watchword = "nines";

const account = 2;
const shoot = false;
const watchword = "thunderation";


async function main() {
  const game = await hre.ethers.getContractAt("GweiGunslingers", GAME_ADDRESS);
  const accounts = await ethers.getSigners();
  
  const tx = await game.connect(accounts[account]).commitToDuel(shoot, watchword, { value: ethers.utils.parseUnits("1", "gwei") });
  const receipt = await tx.wait();

  console.log(receipt);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

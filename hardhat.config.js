require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');

module.exports = {
  solidity: "0.8.4",
  defaultNetwork: "ganache",
  networks: {
      ganache: {
          url: "http://127.0.0.1:8545",
          accounts: ["0xfd629d5879430fbb87ecc6bb0a2a0fde7a68e06a3d552a6ec728cf597e17e1a7"]
      }
  },
};

require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

module.exports = {
  solidity: "0.8.4",
  defaultNetwork: "ganache",
  networks: {
      ganache: {
        url: "http://127.0.0.1:8545",
        accounts: ["0xc74cbf968b871096e0f4d20a72724f2a5378d8567e30ead772f52f2dd781bf1b"
                        ,"0xa932d9afb22921b47b8ebd679fde8b64e2e81edb42b52c9a7990aef2c658dfbd"
                        ,"0x1fb5e4a632f0996418849e4aae88ef5c930adb3a9365af912f33164c672ce578"
                        ]
      },
      rinkeby: {
        url: process.env.RINKEBY_URL,
        accounts: [process.env.PRIVATE_KEY]
      }
  },
};

require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");

module.exports = {
  networks: {
    skale_test: {
      provider: () =>
        new HDWalletProvider(
          [
            process.env.PRIVATE_KEY_ADMIN,
            process.env.PRIVATE_KEY_USER1,
          ],
          process.env.SKALE_RPC_URL
        ),
      network_id: "*",
      gasPrice: 100000,
      skipDryRun: true
    },
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*"
    },
    skale: {
      provider: () =>
        new HDWalletProvider(
          process.env.PRIVATE_KEY,
          process.env.SKALE_RPC_URL
        ),
      network_id: "*",
      gasPrice: 100000,
      skipDryRun: true
    }
  },
  compilers: {
    solc: {
      version: "0.8.20"
    }
  }
};


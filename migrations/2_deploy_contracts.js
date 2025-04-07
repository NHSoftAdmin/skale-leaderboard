const LeaderboardGM = artifacts.require("LeaderboardGM");

module.exports = function (deployer) {
  deployer.deploy(LeaderboardGM);
};

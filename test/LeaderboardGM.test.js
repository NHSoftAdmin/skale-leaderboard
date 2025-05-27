// test/LeaderboardGM.test.js
const LeaderboardGM = artifacts.require("LeaderboardGM.sol");
const { expectRevert } = require("@openzeppelin/test-helpers");

contract("LeaderboardGM", ([admin, user1, user2, user3]) => {
  let contract;

  beforeEach(async () => {
    contract = await LeaderboardGM.new({ from: admin });
  });

  //for this test in the contract should be changed from 1000 to 10, other way will receive timeout
  it("respects leaderboard max size with high score replacement", async function () {  
    for (let i = 0; i < 10; i++) {
      const newUser = web3.eth.accounts.create();
      await contract.submitScore(newUser.address, 1000 + i, { from: admin });
    }

    const lowUser = web3.eth.accounts.create();
    await contract.submitScore(lowUser.address, 999, { from: admin }); // should not be added

    const highUser = web3.eth.accounts.create();
    await contract.submitScore(highUser.address, 2000, { from: admin }); // should replace lowest

    const result = await contract.getLeaderboard();
    assert.equal(result.length, 10);
    const addresses = result.map(p => p.wallet.toLowerCase());
    assert(addresses.includes(highUser.address.toLowerCase()));
    assert(!addresses.includes(lowUser.address.toLowerCase()));
  });

  it("updates score if higher", async () => {
    await contract.submitScore(user1, 2000, { from: admin });
    await contract.submitScore(user1, 9000, { from: admin });

    const result = await contract.getLeaderboard();
    const entry = result.find(p => p.wallet.toLowerCase() === user1.toLowerCase());

    assert(entry);
    assert.equal(entry.score.toString(), "9000");
  });
});

require("dotenv").config();
const LeaderboardGM = artifacts.require("LeaderboardGM");

const admin = process.env.ADMIN_ADDRESS;
const user1 = process.env.USER1_ADDRESS;
const user2 = process.env.USER2_ADDRESS;

contract("LeaderboardGM", () => {
  let contract;

  before(async () => {
    contract = await LeaderboardGM.deployed();
  });


  it("respects leaderboard max size with high score replacement", async () => {
    await contract.addToWhitelist(user1, { from: admin });
  
    await contract.submitScore(1000, { from: user1 });
  
    for (let i = 0; i < 5; i++) {
      await contract.submitScore(1000 + i, { from: user1 });
      await new Promise(res => setTimeout(res, 300)); // small delay
    }
  
    const leaderboard = await contract.getLeaderboard();
    assert.equal(leaderboard.length, 1, "Should have only one entry from one user");
    assert.equal(leaderboard[0].score, 1004, "Should have highest score stored");
  });

  it("allows whitelisted user to submit score", async () => {
    await contract.addToWhitelist(user1, { from: admin });
    const score = 1234;
    await contract.submitScore(score, { from: user1 });

    const leaderboard = await contract.getLeaderboard();
    const entry = leaderboard.find(e => e.wallet.toLowerCase() === user1.toLowerCase());
    assert(entry, "User1 not found on leaderboard");
    assert.equal(entry.score, score, "Score not stored correctly");
  });

  it("rejects non-whitelisted user", async () => {
    let reverted = false;
    try {
      await contract.submitScore(9999, { from: user2 });
    } catch (err) {
      reverted = true;
    }
    assert.equal(reverted, true, "Non-whitelisted user2 should not be able to submit score");
  });

  it("can remove from whitelist", async () => {
    await contract.removeFromWhitelist(user1, { from: admin });

    let reverted = false;
    try {
      await contract.submitScore(8888, { from: user1 });
    } catch (err) {
      reverted = true;
    }

    assert.equal(reverted, true, "User1 should not be able to submit after being removed from whitelist");
  });

  it("updates score if higher", async () => {
    await contract.addToWhitelist(user1, { from: admin });
    await contract.submitScore(2000, { from: user1 });
    await contract.submitScore(9000, { from: user1 });

    const leaderboard = await contract.getLeaderboard();
    const entry = leaderboard.find(e => e.wallet.toLowerCase() === user1.toLowerCase());
    assert(entry, "User1 should still be on leaderboard");
    assert.equal(entry.score, 9000, "Score should be updated to the higher value");
  });
  
});

require("dotenv").config();
const LeaderboardGM = artifacts.require("LeaderboardGM");

const admin = process.env.ADMIN_ADDRESS;
const user1 = process.env.USER1_ADDRESS;

contract("LeaderboardGM", () => {
  let contract;

  before(async () => {
    contract = await LeaderboardGM.deployed();
  });

  
  it("respects leaderboard max size with high score replacement", async () => {
    await contract.addToWhitelist(user1, { from: admin });

    // Submit an initial score
    await contract.submitScore(1000, { from: user1 });

    // Simulate leaderboard updates (same wallet)
    for (let i = 0; i < 10; i++) {
      await contract.submitScore(1000 + i, { from: user1 });
    }

    const len = await contract.getLeaderboardLength();
    assert.equal(len.toNumber(), 1, "Should have only one entry from one user");

    const top = await contract.leaderboard(0);
    assert.equal(top.score.toNumber(), 1009, "Should have highest score stored");
  });

  it("checks if user1 is whitelisted and adds if not", async () => {
    let isWhitelisted = await contract.isWhitelisted(user1);

    if (!isWhitelisted) {
      await contract.addToWhitelist(user1, { from: admin });
    }

    const updated = await contract.isWhitelisted(user1);
    assert.equal(updated, true, "User1 should be whitelisted");
  });

  it("allows whitelisted user to submit score", async () => {
    const score = 1234;

    await contract.submitScore(score, { from: user1 });

    const entry = await contract.leaderboard(0);
    assert.equal(entry.user.toLowerCase(), user1.toLowerCase(), "User1 not at leaderboard top");
    assert.equal(entry.score.toNumber(), score, "Score not stored correctly");
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

    const isStillWhitelisted = await contract.isWhitelisted(user1);
    assert.equal(isStillWhitelisted, false, "User1 should have been removed from whitelist");

    let reverted = false;
    try {
      await contract.submitScore(8888, { from: user1 });
    } catch (err) {
      reverted = true;
    }

    assert.equal(reverted, true, "User1 should not be able to submit after being removed from whitelist");
  });

  it("updates score if higher", async () => {

    let isWhitelisted = await contract.isWhitelisted(user1);

    if (!isWhitelisted) {
      await contract.addToWhitelist(user1, { from: admin });
      await contract.submitScore(2000, { from: user1 }); // lower score
      await contract.submitScore(9000, { from: user1 }); // higher score

      const entry = await contract.leaderboard(0);
      assert.equal(entry.user.toLowerCase(), user1.toLowerCase(), "User1 should still be top");
      assert.equal(entry.score.toNumber(), 9000, "Score should be updated to the higher value");
    }    
  });
  

  it("pauses and resumes submission", async () => {

    
    await contract.addToWhitelist(user1, { from: admin });
    await contract.pauseSubmissions(true, { from: admin });

    let pausedRevert = false;
    try {      
        await contract.submitScore(10000, { from: user1 });
        const entry = await contract.leaderboard(0);
        assert.equal(entry.score.toNumber(), 10000, "Score should be updated after resume");      
    } catch (err) {
      pausedRevert = true;
    }
    assert.equal(pausedRevert, true, "Should revert while paused");

    await contract.pauseSubmissions(false, { from: admin });

    await contract.submitScore(10000, { from: user1 });
    const entry = await contract.leaderboard(0);
    assert.equal(entry.score.toNumber(), 10000, "Score should be updated after resume");

  });  

});

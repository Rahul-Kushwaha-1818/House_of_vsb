require('dotenv').config();
const http = require('http');
const connectDB = require('./src/config/db');
const User = require('./src/models/User');
const Auction = require('./src/models/Auction');
const app = require('./src/app');
const jwt = require('jsonwebtoken');

const { seedUsersAndAuctions } = require('./src/config/seedHelper');

const runConcurrencyTest = async () => {
  console.log('\n--- Starting Auction Concurrency Stress Test ---');
  await connectDB();
  await seedUsersAndAuctions();

  // Start temporary server
  const server = http.createServer(app);
  await new Promise((resolve) => server.listen(5099, '127.0.0.1', resolve));
  const baseUrl = 'http://127.0.0.1:5099';

  // 1. Get Alice and Bob
  const alice = await User.findOne({ email: 'alice@auction.com' });
  const bob = await User.findOne({ email: 'bob@auction.com' });

  const aliceToken = jwt.sign({ id: alice._id, role: alice.role }, process.env.JWT_SECRET);
  const bobToken = jwt.sign({ id: bob._id, role: bob.role }, process.env.JWT_SECRET);

  // 2. Create fresh live auction for test
  const testAuction = await Auction.create({
    title: 'Concurrency Test Auction - Limited Edition Watch',
    description: 'Special auction created strictly for concurrent bid testing.',
    startingPrice: 1000,
    minIncrement: 50,
    currentHighestBid: 1000,
    currentHighestBidder: null,
    startTime: new Date(Date.now() - 60000),
    endTime: new Date(Date.now() + 600000),
    status: 'live',
    createdBy: alice._id,
    bids: [],
  });

  console.log(`Created test auction ${testAuction._id}. Starting price: $1000, Min increment: $50.`);

  // Function to place bid via HTTP
  const sendBid = async (token, amount) => {
    const res = await fetch(`${baseUrl}/api/auctions/${testAuction._id}/bid`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ amount }),
    });
    const data = await res.json();
    return { status: res.status, data };
  };

  console.log('\nSimulating 10 SIMULTANEOUS bids trying to bid $1050 at the exact same moment...');

  // 10 concurrent requests at the same exact amount
  const requests = Array.from({ length: 10 }).map((_, i) => {
    const token = i % 2 === 0 ? aliceToken : bobToken;
    return sendBid(token, 1050);
  });

  const results = await Promise.all(requests);

  const successfulBids = results.filter(r => r.status === 200);
  const rejectedBids = results.filter(r => r.status !== 200);

  console.log(`\nResults:`);
  console.log(`  Successful Bids (200 OK): ${successfulBids.length}`);
  console.log(`  Rejected Bids (Conflict/Error): ${rejectedBids.length}`);
  rejectedBids.slice(0, 3).forEach((r, i) => {
    console.log(`  Sample Rejection Reason [${i + 1}]: "${r.data.message}"`);
  });

  // Verify Auction State in DB
  const finalAuction = await Auction.findById(testAuction._id);
  console.log(`\nFinal Auction State:`);
  console.log(`  Current Highest Bid: $${finalAuction.currentHighestBid}`);
  console.log(`  Total Bids Recorded in DB: ${finalAuction.bids.length}`);

  if (successfulBids.length === 1 && finalAuction.bids.length === 1 && finalAuction.currentHighestBid === 1050) {
    console.log('\n SUCCESS: Race condition prevented! Exactly 1 bid accepted; conflicting simultaneous bids safely rejected.\n');
  } else {
    console.error('\n FAILURE: Race condition occurred!\n');
    process.exit(1);
  }

  // Cleanup
  await Auction.findByIdAndDelete(testAuction._id);
  server.close();
  process.exit(0);
};

runConcurrencyTest();

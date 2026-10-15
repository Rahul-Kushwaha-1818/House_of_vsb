const User = require('../models/User');
const Auction = require('../models/Auction');

const seedUsersAndAuctions = async () => {
  const userCount = await User.countDocuments();
  if (userCount > 0) {
    console.log('[Seeder] Database already populated with users.');
    return;
  }

  console.log('[Seeder] Auto-seeding initial users and auctions...');

  // Create Admin
  const admin = await User.create({
    name: 'Auction Admin',
    email: 'admin@auction.com',
    password: 'admin123',
    role: 'admin',
  });

  // Create 5 Regular Users
  const users = await User.create([
    {
      name: 'Alice Walker',
      email: 'alice@auction.com',
      password: 'user123',
      role: 'user',
    },
    {
      name: 'Bob Martinez',
      email: 'bob@auction.com',
      password: 'user123',
      role: 'user',
    },
    {
      name: 'Charlie Chen',
      email: 'charlie@auction.com',
      password: 'user123',
      role: 'user',
    },
    {
      name: 'Diana Prince',
      email: 'diana@auction.com',
      password: 'user123',
      role: 'user',
    },
    {
      name: 'Ethan Hunt',
      email: 'ethan@auction.com',
      password: 'user123',
      role: 'user',
    },
  ]);

  const [alice, bob, charlie, diana, ethan] = users;

  const now = new Date();

  // 1. Live Auction - Rolex Submariner (with active bids)
  const rolexStartTime = new Date(now.getTime() - 2 * 60 * 60 * 1000);
  const rolexEndTime = new Date(now.getTime() + 4 * 60 * 60 * 1000);
  await Auction.create({
    title: 'Vintage 1978 Rolex Submariner Date (Ref. 1680)',
    description: 'Classic reference 1680 Rolex Submariner with matte black dial, original tritium lume markers, and stainless steel oyster bracelet. Fully serviced and in pristine collector condition.',
    imageUrl: 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800',
    startingPrice: 4500,
    minIncrement: 150,
    currentHighestBid: 4900,
    currentHighestBidder: charlie._id,
    startTime: rolexStartTime,
    endTime: rolexEndTime,
    status: 'live',
    createdBy: admin._id,
    bids: [
      {
        bidder: alice._id,
        amount: 4500,
        createdAt: new Date(now.getTime() - 90 * 60 * 1000),
      },
      {
        bidder: bob._id,
        amount: 4700,
        createdAt: new Date(now.getTime() - 50 * 60 * 1000),
      },
      {
        bidder: charlie._id,
        amount: 4900,
        createdAt: new Date(now.getTime() - 15 * 60 * 1000),
      },
    ],
  });

  // 2. Live Auction - MacBook Pro M3 Max
  const macStartTime = new Date(now.getTime() - 1 * 60 * 60 * 1000);
  const macEndTime = new Date(now.getTime() + 90 * 60 * 1000);
  await Auction.create({
    title: 'Apple MacBook Pro 16" M3 Max (64GB RAM / 2TB SSD)',
    description: 'Space Black edition, 16-core CPU, 40-core GPU, 64GB Unified Memory, 2TB SSD storage. Battery health 100%, includes original 140W MagSafe charger and original retail packaging.',
    imageUrl: 'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=800',
    startingPrice: 2200,
    minIncrement: 50,
    currentHighestBid: 2300,
    currentHighestBidder: ethan._id,
    startTime: macStartTime,
    endTime: macEndTime,
    status: 'live',
    createdBy: admin._id,
    bids: [
      {
        bidder: diana._id,
        amount: 2200,
        createdAt: new Date(now.getTime() - 40 * 60 * 1000),
      },
      {
        bidder: ethan._id,
        amount: 2300,
        createdAt: new Date(now.getTime() - 10 * 60 * 1000),
      },
    ],
  });

  // 3. Live Auction - Sony Alpha A7 IV (Short duration)
  const sonyStartTime = new Date(now.getTime() - 20 * 60 * 1000);
  const sonyEndTime = new Date(now.getTime() + 15 * 60 * 1000);
  await Auction.create({
    title: 'Sony Alpha A7 IV Full-Frame Camera + 24-70mm GM Lens',
    description: '33MP full-frame Exmor R CMOS sensor, 4K 60p 10-bit video, paired with pristine G Master f/2.8 lens. Low shutter count (<2500 actuations). Perfect kit for hybrid creators.',
    imageUrl: 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?w=800',
    startingPrice: 1500,
    minIncrement: 50,
    currentHighestBid: 1500,
    currentHighestBidder: alice._id,
    startTime: sonyStartTime,
    endTime: sonyEndTime,
    status: 'live',
    createdBy: admin._id,
    bids: [
      {
        bidder: alice._id,
        amount: 1500,
        createdAt: new Date(now.getTime() - 15 * 60 * 1000),
      },
    ],
  });

  // 4. Upcoming Auction - 1967 Shelby GT500 Fastback
  const carStartTime = new Date(now.getTime() + 2 * 60 * 60 * 1000);
  const carEndTime = new Date(now.getTime() + 26 * 60 * 60 * 1000);
  await Auction.create({
    title: '1967 Ford Mustang Fastback GTA 390 V8',
    description: 'Fully restored Raven Black fastback with 390ci V8 big block, C6 automatic transmission, factory air conditioning, and Marti report documentation. Clean California title.',
    imageUrl: 'https://images.unsplash.com/photo-1584345604476-8ec5e12e42dd?w=800',
    startingPrice: 65000,
    minIncrement: 1000,
    currentHighestBid: 0,
    currentHighestBidder: null,
    startTime: carStartTime,
    endTime: carEndTime,
    status: 'upcoming',
    createdBy: admin._id,
    bids: [],
  });

  // 5. Upcoming Auction - Original Canvas Painting
  const artStartTime = new Date(now.getTime() + 5 * 60 * 60 * 1000);
  const artEndTime = new Date(now.getTime() + 48 * 60 * 60 * 1000);
  await Auction.create({
    title: 'Original Oil Painting: "Sunset Over Mediterranean"',
    description: 'Framed 36" x 48" oil on linen canvas by acclaimed contemporary artist. Features rich impasto textures and vibrant maritime hues. Certificate of authenticity included.',
    imageUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=800',
    startingPrice: 800,
    minIncrement: 50,
    currentHighestBid: 0,
    currentHighestBidder: null,
    startTime: artStartTime,
    endTime: artEndTime,
    status: 'upcoming',
    createdBy: admin._id,
    bids: [],
  });

  // 6. Ended Auction - PlayStation 5 Pro (With Winner Alice)
  const ps5StartTime = new Date(now.getTime() - 48 * 60 * 60 * 1000);
  const ps5EndTime = new Date(now.getTime() - 3 * 60 * 60 * 1000);
  await Auction.create({
    title: 'PlayStation 5 Pro 30th Anniversary Limited Edition Bundle',
    description: 'Brand new in sealed box, numbered anniversary edition. Includes retro grey DualSense Edge controller, charging station, and collector console skin.',
    imageUrl: 'https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=800',
    startingPrice: 600,
    minIncrement: 25,
    currentHighestBid: 725,
    currentHighestBidder: alice._id,
    startTime: ps5StartTime,
    endTime: ps5EndTime,
    status: 'ended',
    winner: alice._id,
    createdBy: admin._id,
    bids: [
      {
        bidder: bob._id,
        amount: 600,
        createdAt: new Date(now.getTime() - 40 * 60 * 1000),
      },
      {
        bidder: diana._id,
        amount: 650,
        createdAt: new Date(now.getTime() - 25 * 60 * 1000),
      },
      {
        bidder: alice._id,
        amount: 725,
        createdAt: new Date(now.getTime() - 10 * 60 * 1000),
      },
    ],
  });

  // 7. Ended Auction - Antique Writing Desk (No bids -> Unsold)
  const deskStartTime = new Date(now.getTime() - 72 * 60 * 60 * 1000);
  const deskEndTime = new Date(now.getTime() - 12 * 60 * 60 * 1000);
  await Auction.create({
    title: 'Antique Victorian Mahogany Writing Desk (Circa 1890)',
    description: 'Solid mahogany pedestal desk with brass drawer pulls and hand-tooled leather writing surface. Needs light French polishing on left pedestal. Sold as-is.',
    imageUrl: 'https://images.unsplash.com/photo-1518455027359-f3f8164ba6bd?w=800',
    startingPrice: 1200,
    minIncrement: 50,
    currentHighestBid: 0,
    currentHighestBidder: null,
    startTime: deskStartTime,
    endTime: deskEndTime,
    status: 'ended',
    winner: null,
    createdBy: admin._id,
    bids: [],
  });

  console.log('[Seeder] Database initialized successfully with demo data.');
};

module.exports = { seedUsersAndAuctions };

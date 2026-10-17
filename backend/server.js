require('dotenv').config();
const http = require('http');
const { Server } = require('socket.io');
const app = require('./src/app');
const connectDB = require('./src/config/db');
const { initSocket } = require('./src/services/socketService');
const { startAuctionWorker, stopAuctionWorker } = require('./src/services/auctionWorker');
// keep alive service so render free tier doesn't sleep
const { startKeepAlive, stopKeepAlive } = require('./src/services/keepAliveService');

const PORT = process.env.PORT || 5000;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.io with permissive CORS and multi-transport support
const io = new Server(server, {
  cors: {
    origin: '*',
    methods: ['GET', 'POST'],
  },
  transports: ['polling', 'websocket'],
});

initSocket(io);

// Connect to Database & Start Server
const startServer = async () => {
  try {
    await connectDB();

    server.listen(PORT, '0.0.0.0', () => {
      console.log(`===============================================`);
      console.log(` Auction Server listening on port ${PORT}`);
      console.log(` Health check: http://localhost:${PORT}/health`);
      console.log(` WebSocket server initialized`);
      console.log(`===============================================`);

      // Start background auction scheduler / lifecycle worker
      startAuctionWorker(4000);

      // keep server awake on render free tier (ping under 5 mins)
      startKeepAlive(4 * 60 * 1000);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
const shutdown = () => {
  console.log('\nShutting down gracefully...');
  stopAuctionWorker();
  stopKeepAlive();
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

startServer();

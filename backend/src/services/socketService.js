let ioInstance = null;

const initSocket = (io) => {
  ioInstance = io;

  io.on('connection', (socket) => {
    // Join room for specific auction
    socket.on('join_auction', (auctionId) => {
      if (auctionId) {
        socket.join(`auction:${auctionId}`);
      }
    });

    // Leave room for specific auction
    socket.on('leave_auction', (auctionId) => {
      if (auctionId) {
        socket.leave(`auction:${auctionId}`);
      }
    });

    socket.on('disconnect', () => {
      // Clean up on disconnect
    });
  });

  return ioInstance;
};

const getIO = () => {
  return ioInstance;
};

const broadcastNewBid = (auctionId, payload) => {
  if (!ioInstance) return;
  // Specific auction room gets detailed new bid event
  ioInstance.to(`auction:${auctionId}`).emit('new_bid', payload);
  // All clients get general update for the auction card list
  ioInstance.emit('auction_updated', payload);
};

const broadcastAuctionEnded = (auctionId, payload) => {
  if (!ioInstance) return;
  ioInstance.to(`auction:${auctionId}`).emit('auction_ended', payload);
  ioInstance.emit('auction_status_changed', { auctionId, status: 'ended', ...payload });
};

const broadcastAuctionStarted = (auctionId, payload) => {
  if (!ioInstance) return;
  ioInstance.emit('auction_status_changed', { auctionId, status: 'live', ...payload });
};

const broadcastAuctionCreated = (payload) => {
  if (!ioInstance) return;
  ioInstance.emit('auction_created', payload);
};

module.exports = {
  initSocket,
  getIO,
  broadcastNewBid,
  broadcastAuctionEnded,
  broadcastAuctionStarted,
  broadcastAuctionCreated,
};

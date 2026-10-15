const Notification = require('../models/Notification');

let ioInstance = null;

const initSocket = (io) => {
  ioInstance = io;

  io.on('connection', (socket) => {
    // Join room for user's personal push notifications
    socket.on('join_user', (userId) => {
      if (userId) {
        socket.join(`user:${userId}`);
      }
    });

    socket.on('leave_user', (userId) => {
      if (userId) {
        socket.leave(`user:${userId}`);
      }
    });

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

const sendUserNotification = async (userId, notificationData) => {
  let notification = null;
  try {
    notification = await Notification.create({
      user: userId,
      title: notificationData.title,
      body: notificationData.body,
      type: notificationData.type || 'general',
      auctionId: notificationData.auctionId || null,
    });
  } catch (err) {
    console.error('[SocketService] Error creating notification record:', err.message);
  }

  const payload = notification ? notification.toObject() : {
    _id: Date.now().toString(),
    user: userId,
    title: notificationData.title,
    body: notificationData.body,
    type: notificationData.type || 'general',
    auctionId: notificationData.auctionId || null,
    isRead: false,
    createdAt: new Date(),
  };

  if (ioInstance) {
    ioInstance.to(`user:${userId}`).emit('push_notification', payload);
  }

  return payload;
};

module.exports = {
  initSocket,
  getIO,
  broadcastNewBid,
  broadcastAuctionEnded,
  broadcastAuctionStarted,
  broadcastAuctionCreated,
  sendUserNotification,
};

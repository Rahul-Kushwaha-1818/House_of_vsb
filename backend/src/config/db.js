const mongoose = require('mongoose');

let mongod = null;

const connectDB = async () => {
  const uri = process.env.MONGO_URI;

  if (uri) {
    try {
      console.log(`[Database] Connecting to MongoDB: ${uri.replace(/:([^:@]+)@/, ':****@')}`);
      const conn = await mongoose.connect(uri, {
        serverSelectionTimeoutMS: 5000,
      });
      console.log(`[Database] MongoDB Atlas connected successfully: ${conn.connection.host}`);
      return conn;
    } catch (error) {
      console.warn(`[Database] Connection to Atlas failed (${error.message}).`);
      console.log('[Database] Initializing embedded MongoDB server for instant seamless local operation...');
    }
  }

  try {
    const { MongoMemoryServer } = require('mongodb-memory-server');
    mongod = await MongoMemoryServer.create({
      instance: {
        port: 27017,
        dbName: 'auction_db',
      },
    });
    const fallbackUri = mongod.getUri();
    console.log(`[Database] Embedded MongoDB server running at: ${fallbackUri}`);
    const conn = await mongoose.connect(fallbackUri);
    console.log('[Database] Embedded MongoDB connected successfully.');
    return conn;
  } catch (fallbackError) {
    console.error(`[Database] Failed to initialize embedded MongoDB: ${fallbackError.message}`);
    process.exit(1);
  }
};

module.exports = connectDB;

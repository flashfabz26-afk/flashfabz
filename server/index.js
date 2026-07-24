const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const orderRoutes = require('./routes/orderRoutes');

const app = express();
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/lion_circuits';

// Disable buffering so requests don't hang when MongoDB is offline
mongoose.set('bufferCommands', false);

// Middleware
app.use(cors());
app.use(express.json());


// Routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);

// Health & Status endpoint
app.get('/api/health', (req, res) => {
  const dbStateMap = {
    0: 'Disconnected',
    1: 'Connected',
    2: 'Connecting',
    3: 'Disconnecting',
  };
  const dbStatus = dbStateMap[mongoose.connection.readyState] || 'Unknown';

  res.json({
    status: 'ok',
    databaseStatus: dbStatus,
    timestamp: new Date().toISOString(),
  });
});

// Database Connection
let isConnected = false;

mongoose
  .connect(MONGO_URI, {
    serverSelectionTimeoutMS: 5000,
  })
  .then(() => {
    isConnected = true;
    console.log(`[MongoDB] Connected successfully to: ${MONGO_URI}`);
  })
  .catch((err) => {
    console.error(`[MongoDB] Connection error: ${err.message}`);
    console.log('[MongoDB] Make sure local MongoDB is running (mongod) OR configure MONGO_URI in server/.env with your MongoDB Atlas cluster URI.');
  });

// Express Server
app.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(` Lion Circuit Backend running on port ${PORT}`);
  console.log(` Health check URL: http://localhost:${PORT}/api/health`);
  console.log(`====================================================`);
});

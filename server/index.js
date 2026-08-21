const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');
require('dotenv').config();

const authRoutes = require('./routes/authRoutes');
const orderRoutes = require('./routes/orderRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Initialize Firebase Admin SDK
try {
  if (!admin.apps.length) {
    const projectId = process.env.FIREBASE_PROJECT_ID || 'hrpcb-b3ab4';
    admin.initializeApp({
      projectId: projectId,
    });
    console.log(`[Firebase Admin] Initialized successfully for project: ${projectId}`);
  }
} catch (err) {
  console.warn(`[Firebase Admin] Initialization note: ${err.message}`);
}

// Advanced CORS configuration for Flutter Web & Mobile
const corsOptions = {
  origin: '*', // Allow all origins in dev mode (Flutter Web running on random ports)
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
  credentials: false, // Must be false when origin is '*'
  optionsSuccessStatus: 200,
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

app.use(express.json());

// Logging Middleware
app.use((req, res, next) => {
  const start = Date.now();
  const origin = req.headers.origin || 'Same-Origin / Direct';
  console.log(`[HTTP-REQ] [${new Date().toISOString()}] ${req.method} ${req.url} (Origin: ${origin})`);

  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[HTTP-RES] [${new Date().toISOString()}] ${req.method} ${req.url} -> Status: ${res.statusCode} (${duration}ms)`);
  });

  next();
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);

// Health & Status endpoint
app.get('/api/health', (req, res) => {
  const isFirebaseReady = admin.apps.length > 0;

  res.setHeader('Access-Control-Allow-Origin', '*');
  res.json({
    status: 'ok',
    databaseStatus: isFirebaseReady ? 'Connected (Firebase Cloud Firestore)' : 'Local File Fallback',
    timestamp: new Date().toISOString(),
    port: PORT,
  });
});

// Global 404 Handler
app.use((req, res) => {
  res.status(404).json({ error: `Endpoint '${req.originalUrl}' not found.` });
});

// Global Error Handling Middleware
app.use((err, req, res, next) => {
  console.error(`[SERVER-ERROR] Unhandled Exception: ${err.message}`, err.stack);
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.status(500).json({ error: err.message || 'Internal Server Error.' });
});

// Start Server
app.listen(PORT, () => {
  console.log(`====================================================`);
  console.log(` Lion Circuit Backend running on port ${PORT}`);
  console.log(` Health check URL: http://localhost:${PORT}/api/health`);
  console.log(` Database: Firebase Cloud Firestore & Auth`);
  console.log(` CORS Allowed: ALL origins (*)`);
  console.log(`====================================================`);
});

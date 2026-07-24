const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const fs = require('fs');
const path = require('path');
const User = require('../models/User');

const router = express.Router();

// Local dev fallback persistence file when MongoDB is offline
const dataDir = path.join(__dirname, '../data');
const usersFilePath = path.join(dataDir, 'users.json');

if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

function loadDevUsers() {
  try {
    if (fs.existsSync(usersFilePath)) {
      const data = fs.readFileSync(usersFilePath, 'utf8');
      const list = JSON.parse(data);
      return new Map(list.map((u) => [u.email, u]));
    }
  } catch (err) {
    console.error('[AUTH-DEV-STORE] Error loading users file:', err.message);
  }
  return new Map();
}

function saveDevUsers(usersMap) {
  try {
    const list = Array.from(usersMap.values());
    fs.writeFileSync(usersFilePath, JSON.stringify(list, null, 2), 'utf8');
  } catch (err) {
    console.error('[AUTH-DEV-STORE] Error saving users file:', err.message);
  }
}

const memoryUsers = loadDevUsers();

// Helper to check MongoDB connection
const isDbConnected = () => mongoose.connection.readyState === 1;

// Handler for registration / signup
const handleRegister = async (req, res) => {
  const { name, email, password } = req.body;

  console.log('====================================================');
  console.log(`[AUTH-SIGNUP] New Signup Attempt received`);
  console.log(`[AUTH-SIGNUP] Entered Name: "${name}"`);
  console.log(`[AUTH-SIGNUP] Entered Email: "${email}"`);

  if (!name || !email || !password) {
    console.log(`[AUTH-SIGNUP] Result: FAILED (Missing required fields)`);
    return res.status(400).json({ error: 'Please provide name, email, and password.' });
  }

  const normalizedEmail = String(email).trim().toLowerCase();
  const trimmedName = String(name).trim();

  try {
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    if (isDbConnected()) {
      // 1. Check existing user in MongoDB
      const existingUser = await User.findOne({ email: normalizedEmail });
      if (existingUser) {
        console.log(`[AUTH-SIGNUP] User already exists in MongoDB: "${normalizedEmail}"`);
        return res.status(400).json({ error: 'An account with this email address already exists.' });
      }

      // 2. Save user to MongoDB
      const newUser = new User({
        name: trimmedName,
        email: normalizedEmail,
        password: hashedPassword,
      });

      await newUser.save();
      console.log(`[AUTH-SIGNUP] User saved to MongoDB successfully: ID ${newUser._id}`);

      // 3. Generate JWT Token
      const token = jwt.sign(
        { id: newUser._id, email: newUser.email },
        process.env.JWT_SECRET || 'fallback_secret',
        { expiresIn: '30d' }
      );

      console.log(`[AUTH-SIGNUP] JWT token generated successfully.`);
      console.log(`[AUTH-SIGNUP] Result: SUCCESS`);
      console.log('====================================================');

      return res.status(201).json({
        message: 'User registered successfully in MongoDB database.',
        token,
        user: { id: newUser._id, name: newUser.name, email: newUser.email },
        storage: 'MongoDB Database',
      });
    } else {
      // Fallback dev storage when MongoDB is not connected
      console.log(`[AUTH-SIGNUP] MongoDB offline -> Using local persistent dev store`);
      if (memoryUsers.has(normalizedEmail)) {
        console.log(`[AUTH-SIGNUP] User already exists in dev store: "${normalizedEmail}"`);
        return res.status(400).json({ error: 'An account with this email address already exists.' });
      }

      const userId = 'dev_' + Date.now();
      const user = { id: userId, name: trimmedName, email: normalizedEmail, password: hashedPassword };
      memoryUsers.set(normalizedEmail, user);
      saveDevUsers(memoryUsers);

      const token = jwt.sign(
        { id: userId, email: normalizedEmail },
        process.env.JWT_SECRET || 'fallback_secret',
        { expiresIn: '30d' }
      );

      console.log(`[AUTH-SIGNUP] User saved to Dev Store (ID: ${userId})`);
      console.log(`[AUTH-SIGNUP] Result: SUCCESS (Dev Store)`);
      console.log('====================================================');

      return res.status(201).json({
        message: 'User registered successfully.',
        token,
        user: { id: userId, name: user.name, email: normalizedEmail },
        storage: 'Local File / Dev Persistence',
      });
    }
  } catch (error) {
    console.error(`[AUTH-SIGNUP] Server Error: ${error.message}`);
    console.log(`[AUTH-SIGNUP] Result: FAILED (Server Exception)`);
    console.log('====================================================');
    return res.status(500).json({ error: error.message || 'Server error during signup.' });
  }
};

// Handler for login
const handleLogin = async (req, res) => {
  const { email, password } = req.body;

  const normalizedEmail = email ? String(email).trim().toLowerCase() : '';

  console.log('====================================================');
  console.log(`[AUTH-LOGIN] New Login Attempt received`);
  console.log(`[AUTH-LOGIN] Entered Email: "${normalizedEmail}"`);

  if (!email || !password) {
    console.log(`[AUTH-LOGIN] User found: false (Missing credentials)`);
    console.log(`[AUTH-LOGIN] Password comparison result: N/A`);
    console.log(`[AUTH-LOGIN] Authentication result: FAILED`);
    console.log('====================================================');
    return res.status(400).json({ error: 'Please enter both email and password.' });
  }

  try {
    if (isDbConnected()) {
      // 1. Search MongoDB for User
      const user = await User.findOne({ email: normalizedEmail });

      if (!user) {
        console.log(`[AUTH-LOGIN] User found: false`);
        console.log(`[AUTH-LOGIN] Password comparison result: N/A`);
        console.log(`[AUTH-LOGIN] Authentication result: FAILED (Account Not Found)`);
        console.log('====================================================');
        return res.status(401).json({ error: 'No account found with this email address.' });
      }

      console.log(`[AUTH-LOGIN] User found: true (ID: ${user._id})`);

      // 2. Compare Password with bcrypt.compare()
      const isMatch = await bcrypt.compare(password, user.password);
      console.log(`[AUTH-LOGIN] Password comparison result: ${isMatch ? 'MATCH' : 'MISMATCH'}`);

      if (!isMatch) {
        console.log(`[AUTH-LOGIN] Authentication result: FAILED (Incorrect Password)`);
        console.log('====================================================');
        return res.status(401).json({ error: 'Incorrect password. Please try again.' });
      }

      // 3. Generate JWT Token
      const token = jwt.sign(
        { id: user._id, email: user.email },
        process.env.JWT_SECRET || 'fallback_secret',
        { expiresIn: '30d' }
      );

      console.log(`[AUTH-LOGIN] Authentication result: SUCCESS`);
      console.log('====================================================');

      return res.json({
        message: 'Login successful via MongoDB.',
        token,
        user: { id: user._id, name: user.name, email: user.email },
        storage: 'MongoDB Database',
      });
    } else {
      // Fallback dev store
      console.log(`[AUTH-LOGIN] MongoDB offline -> Searching local dev store`);
      let user = memoryUsers.get(normalizedEmail);

      if (!user) {
        console.log(`[AUTH-LOGIN] User "${normalizedEmail}" not found in dev store. Auto-registering for dev testing.`);
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        const userId = 'dev_' + Date.now();
        user = {
          id: userId,
          name: normalizedEmail.split('@')[0],
          email: normalizedEmail,
          password: hashedPassword,
        };
        memoryUsers.set(normalizedEmail, user);
        saveDevUsers(memoryUsers);
      }

      console.log(`[AUTH-LOGIN] User found: true (Dev ID: ${user.id})`);


      const isMatch = await bcrypt.compare(password, user.password);
      console.log(`[AUTH-LOGIN] Password comparison result: ${isMatch ? 'MATCH' : 'MISMATCH'}`);

      if (!isMatch) {
        console.log(`[AUTH-LOGIN] Authentication result: FAILED (Incorrect Password)`);
        console.log('====================================================');
        return res.status(401).json({ error: 'Incorrect password. Please try again.' });
      }

      const token = jwt.sign(
        { id: user.id, email: user.email },
        process.env.JWT_SECRET || 'fallback_secret',
        { expiresIn: '30d' }
      );

      console.log(`[AUTH-LOGIN] Authentication result: SUCCESS (Dev Store)`);
      console.log('====================================================');

      return res.json({
        message: 'Login successful.',
        token,
        user: { id: user.id, name: user.name, email: user.email },
        storage: 'Local File / Dev Persistence',
      });
    }
  } catch (error) {
    console.error(`[AUTH-LOGIN] Exception: ${error.message}`);
    console.log(`[AUTH-LOGIN] Authentication result: FAILED (Server Error)`);
    console.log('====================================================');
    return res.status(500).json({ error: error.message || 'Server error during login.' });
  }
};

// Endpoints
router.post('/register', handleRegister);
router.post('/signup', handleRegister); // Alias for /signup
router.post('/login', handleLogin);

module.exports = router;

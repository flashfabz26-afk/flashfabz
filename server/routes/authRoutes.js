const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

const router = express.Router();

// Local dev fallback persistence file
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

function getFirestoreDb() {
  try {
    if (admin.apps.length > 0) {
      return admin.firestore();
    }
  } catch (err) {
    console.warn('[AUTH-FIRESTORE] Firestore not initialized:', err.message);
  }
  return null;
}

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
    const devUsers = loadDevUsers();
    const db = getFirestoreDb();

    // Check if user already exists in local store
    if (devUsers.has(normalizedEmail)) {
      console.log(`[AUTH-SIGNUP] User already exists in local dev store: "${normalizedEmail}"`);
      return res.status(409).json({ error: 'An account with this email address already exists.' });
    }

    // Also check Firebase Firestore if connected
    if (db) {
      const userRef = db.collection('users').where('email', '==', normalizedEmail);
      const snapshot = await userRef.get();
      if (!snapshot.empty) {
        console.log(`[AUTH-SIGNUP] User already exists in Firebase Firestore: "${normalizedEmail}"`);
        return res.status(409).json({ error: 'An account with this email address already exists.' });
      }
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);
    const userId = 'user_' + Date.now();

    // 1. Save to local dev persistence file (users.json)
    const userObj = { id: userId, name: trimmedName, email: normalizedEmail, password: hashedPassword };
    devUsers.set(normalizedEmail, userObj);
    saveDevUsers(devUsers);
    console.log(`[AUTH-SIGNUP] Account saved to local users.json (ID: ${userId})`);

    // 2. Also save to Firebase Firestore if connected
    let firebaseSaved = false;
    if (db) {
      try {
        await db.collection('users').doc(userId).set({
          id: userId,
          name: trimmedName,
          email: normalizedEmail,
          password: hashedPassword,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        firebaseSaved = true;
        console.log(`[AUTH-SIGNUP] Account saved to Firebase Firestore successfully: ID ${userId}`);
      } catch (err) {
        console.warn(`[AUTH-SIGNUP] Warning: Failed to save to Firestore, but saved locally: ${err.message}`);
      }
    }

    // 3. Generate JWT Token
    const token = jwt.sign(
      { id: userId, email: normalizedEmail },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '30d' }
    );

    console.log(`[AUTH-SIGNUP] Result: SUCCESS (Account registered)`);
    console.log('====================================================');

    return res.status(201).json({
      message: 'Account created permanently.',
      token,
      user: { id: userId, name: trimmedName, email: normalizedEmail },
      storage: firebaseSaved ? 'Firebase Firestore & Local JSON' : 'Local JSON File',
    });
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
    console.log(`[AUTH-LOGIN] Authentication result: FAILED (Missing credentials)`);
    console.log('====================================================');
    return res.status(400).json({ error: 'Please enter both email and password.' });
  }

  try {
    let foundUser = null;
    let authSource = '';
    const db = getFirestoreDb();

    // 1. Search Firebase Firestore if connected
    if (db) {
      try {
        const snapshot = await db.collection('users').where('email', '==', normalizedEmail).get();
        if (!snapshot.empty) {
          const docData = snapshot.docs[0].data();
          foundUser = {
            id: snapshot.docs[0].id,
            name: docData.name,
            email: docData.email,
            password: docData.password,
          };
          authSource = 'Firebase Firestore';
          console.log(`[AUTH-LOGIN] Account found in Firestore (ID: ${foundUser.id})`);
        }
      } catch (err) {
        console.warn(`[AUTH-LOGIN] Firestore query error, falling back to local file store: ${err.message}`);
      }
    }

    // 2. If not found in Firestore, search local JSON file store (users.json)
    if (!foundUser) {
      const devUsers = loadDevUsers();
      const devUser = devUsers.get(normalizedEmail);
      if (devUser) {
        foundUser = devUser;
        authSource = 'Local JSON File';
        console.log(`[AUTH-LOGIN] Account found in local users.json store (ID: ${foundUser.id})`);
      }
    }

    if (!foundUser) {
      console.log(`[AUTH-LOGIN] Authentication result: FAILED (Account Not Found)`);
      console.log('====================================================');
      return res.status(401).json({ error: 'No account found with this email address. Please sign up first.' });
    }

    // 3. Compare Password
    const isMatch = await bcrypt.compare(password, foundUser.password);
    console.log(`[AUTH-LOGIN] Password comparison result: ${isMatch ? 'MATCH' : 'MISMATCH'}`);

    if (!isMatch) {
      console.log(`[AUTH-LOGIN] Authentication result: FAILED (Incorrect Password)`);
      console.log('====================================================');
      return res.status(401).json({ error: 'Incorrect password. Please try again.' });
    }

    // 4. Generate JWT Token
    const token = jwt.sign(
      { id: foundUser.id, email: foundUser.email },
      process.env.JWT_SECRET || 'fallback_secret',
      { expiresIn: '30d' }
    );

    console.log(`[AUTH-LOGIN] Authentication result: SUCCESS (via ${authSource})`);
    console.log('====================================================');

    return res.json({
      message: 'Login successful.',
      token,
      user: { id: foundUser.id, name: foundUser.name, email: foundUser.email },
      storage: authSource,
    });
  } catch (error) {
    console.error(`[AUTH-LOGIN] Exception: ${error.message}`);
    console.log(`[AUTH-LOGIN] Authentication result: FAILED (Server Error)`);
    console.log('====================================================');
    return res.status(500).json({ error: error.message || 'Server error during login.' });
  }
};

// Endpoints
router.post('/register', handleRegister);
router.post('/signup', handleRegister);
router.post('/login', handleLogin);

module.exports = router;

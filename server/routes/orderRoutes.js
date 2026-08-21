const express = require('express');
const admin = require('firebase-admin');

const router = express.Router();

function getFirestoreDb() {
  try {
    if (admin.apps.length > 0) {
      return admin.firestore();
    }
  } catch (err) {
    console.warn('[ORDERS-FIRESTORE] Firestore not initialized:', err.message);
  }
  return null;
}

// Create new order
router.post('/', async (req, res) => {
  try {
    const { userEmail, fileName, layerCount, boardWidth, boardHeight, quantity, totalPrice } = req.body;

    if (!userEmail || !fileName || !totalPrice) {
      return res.status(400).json({ error: 'Missing required order details.' });
    }

    const orderData = {
      userEmail: userEmail.toLowerCase(),
      fileName,
      layerCount: layerCount || 2,
      boardWidth: boardWidth || 100,
      boardHeight: boardHeight || 100,
      quantity: quantity || 5,
      totalPrice,
      status: 'Pending',
      createdAt: new Date().toISOString(),
    };

    const db = getFirestoreDb();
    if (db) {
      const docRef = await db.collection('orders').add({
        ...orderData,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      orderData.id = docRef.id;
    }

    return res.status(201).json({ message: 'Order created successfully.', order: orderData });
  } catch (error) {
    console.error('Order creation error:', error);
    return res.status(500).json({ error: 'Failed to create order.' });
  }
});

// Get orders by user email
router.get('/user/:email', async (req, res) => {
  try {
    const email = req.params.email.toLowerCase();
    const db = getFirestoreDb();
    const orders = [];

    if (db) {
      const snapshot = await db.collection('orders').where('userEmail', '==', email).get();
      snapshot.forEach((doc) => {
        orders.push({ id: doc.id, ...doc.data() });
      });
    }

    return res.json({ orders });
  } catch (error) {
    console.error('Fetch orders error:', error);
    return res.status(500).json({ error: 'Failed to fetch orders.' });
  }
});

module.exports = router;

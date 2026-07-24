const express = require('express');
const Order = require('../models/Order');

const router = express.Router();

// Create new order
router.post('/', async (req, res) => {
  try {
    const { userEmail, fileName, layerCount, boardWidth, boardHeight, quantity, totalPrice } = req.body;

    if (!userEmail || !fileName || !totalPrice) {
      return res.status(400).json({ error: 'Missing required order details.' });
    }

    const order = new Order({
      userEmail,
      fileName,
      layerCount,
      boardWidth,
      boardHeight,
      quantity,
      totalPrice,
    });

    await order.save();
    return res.status(201).json({ message: 'Order created successfully.', order });
  } catch (error) {
    console.error('Order creation error:', error);
    return res.status(500).json({ error: 'Failed to create order.' });
  }
});

// Get orders by user email
router.get('/user/:email', async (req, res) => {
  try {
    const orders = await Order.find({ userEmail: req.params.email.toLowerCase() }).sort({ createdAt: -1 });
    return res.json({ orders });
  } catch (error) {
    console.error('Fetch orders error:', error);
    return res.status(500).json({ error: 'Failed to fetch orders.' });
  }
});

module.exports = router;

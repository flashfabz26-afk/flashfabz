const mongoose = require('mongoose');

const orderSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: false,
  },
  userEmail: {
    type: String,
    required: true,
  },
  fileName: {
    type: String,
    required: true,
  },
  layerCount: {
    type: Number,
    default: 2,
  },
  boardWidth: {
    type: Number,
    default: 100,
  },
  boardHeight: {
    type: Number,
    default: 100,
  },
  quantity: {
    type: Number,
    default: 5,
  },
  totalPrice: {
    type: Number,
    required: true,
  },
  status: {
    type: String,
    enum: ['Pending', 'Processing', 'Completed', 'Cancelled'],
    default: 'Pending',
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

module.exports = mongoose.model('Order', orderSchema);

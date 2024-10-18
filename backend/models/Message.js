const mongoose = require('mongoose');

const MessageSchema = new mongoose.Schema({
  senderId: { type: String, required: true },
  receiverId: { type: String, required: true },
  content: { type: String, required: true },
}, { timestamps: true });

module.exports = mongoose.model('Message', MessageSchema);
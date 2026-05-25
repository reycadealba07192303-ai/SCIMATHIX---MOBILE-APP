const mongoose = require('mongoose');

const NotificationSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true
  },
  message: {
    type: String,
    required: true
  },
  target: {
    type: String,
    enum: ['OVERALL', 'STUDENT ONLY', 'TEACHER ONLY', 'SPECIFIC_USER'],
    default: 'OVERALL'
  },
  recipientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  isRead: {
    type: Boolean,
    default: false
  },
  type: {
    type: String,
    default: 'system' // 'announcement', 'alert', 'system'
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Notification', NotificationSchema);

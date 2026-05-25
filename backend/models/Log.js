const mongoose = require('mongoose');

const LogSchema = new mongoose.Schema({
  user: {
    type: String,
    required: true
  },
  role: {
    type: String,
    required: true
  },
  action: {
    type: String,
    required: true
  },
  icon: {
    type: String,
    default: 'info'
  },
  color: {
    type: String,
    default: 'blue'
  },
  timestamp: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Log', LogSchema);

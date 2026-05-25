const Log = require('../models/Log');

/**
 * Creates a log entry and emits it via Socket.io
 * @param {Object} req - The Express request object to access app.get('io')
 * @param {Object} logData - { user, role, action, icon, color }
 */
const createLog = async (req, logData) => {
    try {
        const newLog = new Log(logData);
        await newLog.save();

        const io = req.app.get('io');
        if (io) {
            io.emit('new_log', newLog);
        }
    } catch (err) {
        console.error('Error creating log:', err);
    }
};

module.exports = { createLog };

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const app = express();

// Middleware
app.use(express.json());
app.use('/uploads', express.static('uploads'));
app.use(cors());

// Routes
app.use('/api/auth', require('./routes/auth_routes'));
app.use('/api/lessons', require('./routes/lesson_routes'));
app.use('/api/quizzes', require('./routes/quiz_routes'));
app.use('/api/analytics', require('./routes/analytics_routes'));
app.use('/api/academic', require('./routes/academic_routes'));
app.use('/api/chat', require('./routes/chat_routes'));
app.use('/api/announcements', require('./routes/announcement_routes'));
app.use('/api/users', require('./routes/user_routes'));
app.use('/api/logs', require('./routes/log_routes'));
app.use('/api/notifications', require('./routes/notification_routes'));

// Basic Route
app.get('/', (req, res) => {
    res.json({ message: "Welcome to SCIMATHNIX API" });
});

// Database Connection
const PORT = process.env.PORT || 5000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/scimathix';

const http = require('http');
const { Server } = require('socket.io');

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE"]
  }
});

// Attach io to the app so routes can use it via req.app.get('io')
app.set('io', io);

io.on('connection', (socket) => {
  console.log('A user connected via socket.io:', socket.id);
  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

mongoose.connect(MONGO_URI)
    .then(() => {
        console.log('Connected to MongoDB');
        server.listen(PORT, () => {
            console.log(`Server is running on port ${PORT}`);
        });
    })
    .catch(err => {
        console.error('Database connection error:', err);
    });

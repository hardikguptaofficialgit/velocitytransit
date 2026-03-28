require('dotenv').config();

const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');

// ── Firebase init (must be before route imports) ──
require('./config/firebase');

// ── Express setup ──
const app = express();
const server = http.createServer(app);

// ── CORS ──
const corsOrigin = process.env.CORS_ORIGIN || 'http://localhost:5173';
app.use(cors({
  origin: corsOrigin.split(',').map(s => s.trim()),
  credentials: true,
}));
app.use(express.json());

// ── Socket.io ──
const io = new Server(server, {
  cors: {
    origin: corsOrigin.split(',').map(s => s.trim()),
    methods: ['GET', 'POST'],
    credentials: true,
  },
});
app.set('io', io); // Make io accessible in route handlers

// ── Socket.io tracking ──
const { setupTracking } = require('./socket/tracking');
setupTracking(io);

// ── REST Routes ──
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/buses', require('./routes/buses'));
app.use('/api/routes', require('./routes/routes'));
app.use('/api/assignments', require('./routes/assignments'));
app.use('/api/tracking', require('./routes/tracking'));
app.use('/api/notifications', require('./routes/notifications'));
app.use('/api/copilot', require('./routes/copilot'));

// ── Health check ──
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    service: 'VelocityTransit Backend',
  });
});

// ── Start server ──
const PORT = process.env.PORT || 4000;
server.listen(PORT, () => {
  console.log(`
  ╔══════════════════════════════════════╗
  ║   VelocityTransit Backend Server     ║
  ║   Running on port ${PORT}               ║
  ║   Socket.io: enabled                 ║
  ║   Firebase: connected                ║
  ╚══════════════════════════════════════╝
  `);
});

const { auth, db } = require('../config/firebase');
const { getDemoLivePositions } = require('../services/demoTransit');

/**
 * Socket.io real-time tracking handler.
 * 
 * Flow:
 * 1. Driver connects with Firebase token
 * 2. Server verifies token + checks active assignment
 * 3. Driver sends GPS coordinates via 'driver:location'
 * 4. Server broadcasts to all passengers via 'bus:position'
 * 5. Server stores location in Firestore (liveLocations + locationLogs)
 */
function setupTracking(io) {
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token;
      if (!token) {
        return next(new Error('Authentication token required'));
      }
      
      const decoded = await auth.verifyIdToken(token);
      const userDoc = await db.collection('users').doc(decoded.uid).get();
      
      socket.user = {
        uid: decoded.uid,
        email: decoded.email,
        name: decoded.name || decoded.email,
        role: userDoc.exists ? userDoc.data().role : 'passenger',
      };
      
      next();
    } catch (err) {
      next(new Error('Invalid authentication token'));
    }
  });

  io.on('connection', (socket) => {
    const { uid, role, name } = socket.user;
    console.log(`[Socket] ${role} connected: ${name} (${uid})`);

    // ── Room routing based on role ──
    // Admin: sees everything (fleet dashboard + passenger broadcasts)
    if (role === 'admin') {
      socket.join('admins');
      socket.join('passengers');  // Admins also receive bus position updates
    }
    // Passenger: receives bus position broadcasts only
    else if (role === 'passenger') {
      socket.join('passengers');
    }

    // ── Driver: join their own room and handle location updates ──
    if (role === 'driver') {
      socket.join(`driver:${uid}`);

      // Track which assignment this driver has
      let activeAssignment = null;

      socket.on('driver:start', async () => {
        try {
          const snapshot = await db.collection('assignments')
            .where('driverId', '==', uid)
            .where('isActive', '==', true)
            .limit(1)
            .get();

          if (snapshot.empty) {
            socket.emit('error', { message: 'No active assignment found' });
            return;
          }

          activeAssignment = { id: snapshot.docs[0].id, ...snapshot.docs[0].data() };
          socket.emit('driver:assignment', activeAssignment);
          console.log(`[Tracking] Driver ${name} started tracking bus ${activeAssignment.busNumber}`);
        } catch (err) {
          socket.emit('error', { message: err.message });
        }
      });

      socket.on('driver:location', async (data) => {
        if (!activeAssignment) {
          socket.emit('error', { message: 'Call driver:start first' });
          return;
        }

        const { lat, lng, speed, heading } = data;
        const now = new Date().toISOString();

        const locationData = {
          busId: activeAssignment.busId,
          busNumber: activeAssignment.busNumber,
          driverId: uid,
          routeId: activeAssignment.routeId,
          isOnline: true,
          lat,
          lng,
          speed: speed || 0,
          heading: heading || 0,
          lastUpdated: now,
        };

        try {
          // Update live location in Firestore
          await db.collection('liveLocations')
            .doc(activeAssignment.busId)
            .set(locationData, { merge: true });

          // Save to location log (for history)
          await db.collection('locationLogs').add({
            ...locationData,
            timestamp: now,
          });

          // Broadcast to all passengers
          io.to('passengers').emit('bus:position', locationData);

          // Send fleet update to admins
          io.to('admins').emit('fleet:update', locationData);
        } catch (err) {
          console.error('[Tracking] Error saving location:', err.message);
        }
      });
    }

    // ── Passenger: subscribe to specific bus updates ──
    socket.on('track:bus', (busId) => {
      socket.join(`bus:${busId}`);
      console.log(`[Socket] ${name} now tracking bus ${busId}`);
    });

    socket.on('untrack:bus', (busId) => {
      socket.leave(`bus:${busId}`);
    });

    // ── Request all live positions ──
    socket.on('get:live', async () => {
      try {
        const snapshot = await db.collection('liveLocations')
          .where('isOnline', '==', true)
          .get();
        const positions = [
          ...getDemoLivePositions(),
          ...snapshot.docs.map(doc => ({ id: doc.id, source: 'real', isDemo: false, ...doc.data() })),
        ];
        socket.emit('live:positions', positions);
      } catch (err) {
        socket.emit('error', { message: err.message });
      }
    });

    socket.on('disconnect', () => {
      console.log(`[Socket] ${role} disconnected: ${name}`);
    });
  });
}

module.exports = { setupTracking };

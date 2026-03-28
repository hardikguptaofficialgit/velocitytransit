const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { roleCheck } = require('../middleware/roleCheck');
const { sendTransitNotification } = require('../services/notifications');


/**
 * GET /api/assignments — List all assignments (Admin only)
 * Query: ?active=true for only active ones
 */
router.get('/', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    let query = db.collection('assignments');
    if (req.query.active === 'true') {
      query = query.where('isActive', '==', true);
    }
    const snapshot = await query.get();
    const assignments = snapshot.docs
      .map(doc => ({ id: doc.id, ...doc.data() }))
      .sort((a, b) => {
        const aTime = Date.parse(a.startedAt || '') || 0;
        const bTime = Date.parse(b.startedAt || '') || 0;
        return bTime - aTime;
      });
    res.json({ assignments });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/assignments/active — List currently active assignments (Any user)
 */
router.get('/active', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('assignments')
      .where('isActive', '==', true)
      .get();
    const assignments = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ assignments });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/assignments/my — Get current driver's active assignment
 */
router.get('/my', verifyToken, roleCheck('driver', 'admin'), async (req, res) => {
  try {
    const snapshot = await db.collection('assignments')
      .where('driverId', '==', req.user.uid)
      .where('isActive', '==', true)
      .limit(1)
      .get();

    if (snapshot.empty) {
      return res.json({ assignment: null });
    }

    const doc = snapshot.docs[0];
    res.json({ assignment: { id: doc.id, ...doc.data() } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/assignments — Assign a bus to a driver (Admin only)
 * This STARTS location tracking for that bus.
 * Body: { busId, driverId, busNumber, driverName, routeId }
 */
router.post('/', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const { busId, driverId, busNumber, driverName, routeId } = req.body;

    if (!busId || !driverId) {
      return res.status(400).json({ error: 'busId and driverId are required' });
    }

    // Check if bus is already assigned
    const existingBus = await db.collection('assignments')
      .where('busId', '==', busId)
      .where('isActive', '==', true)
      .get();

    if (!existingBus.empty) {
      return res.status(409).json({ error: 'Bus is already assigned to a driver' });
    }

    // Check if driver already has an active assignment
    const existingDriver = await db.collection('assignments')
      .where('driverId', '==', driverId)
      .where('isActive', '==', true)
      .get();

    if (!existingDriver.empty) {
      return res.status(409).json({ error: 'Driver already has an active assignment' });
    }

    const assignmentData = {
      busId,
      driverId,
      busNumber: busNumber || '',
      driverName: driverName || '',
      routeId: routeId || null,
      assignedBy: req.user.uid,
      isActive: true,
      startedAt: new Date().toISOString(),
      endedAt: null,
    };

    const docRef = await db.collection('assignments').add(assignmentData);

    // Also update the live tracking collection to mark bus as online
    await db.collection('liveLocations').doc(busId).set({
      busId,
      busNumber: busNumber || '',
      driverId,
      routeId: routeId || null,
      isOnline: true,
      lat: 0,
      lng: 0,
      speed: 0,
      heading: 0,
      lastUpdated: new Date().toISOString(),
    });

    await sendTransitNotification({
      type: 'trip_started',
      title: 'Trip Started',
      body: `${busNumber || busId} is now live${routeId ? ` on route ${routeId}` : ''}.`,
      routeId: routeId || null,
      busId,
      audience: 'passenger',
      dedupeKey: `assignment:start:${busId}:${driverId}`,
    });

    res.status(201).json({ id: docRef.id, ...assignmentData });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PATCH /api/assignments/:id/deactivate — Remove assignment (Admin only)
 * This STOPS location tracking for that bus.
 */
router.patch('/:id/deactivate', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const assignmentDoc = await db.collection('assignments').doc(req.params.id).get();
    
    if (!assignmentDoc.exists) {
      return res.status(404).json({ error: 'Assignment not found' });
    }

    const assignment = assignmentDoc.data();

    // Deactivate assignment
    await db.collection('assignments').doc(req.params.id).update({
      isActive: false,
      endedAt: new Date().toISOString(),
    });

    // Remove from live tracking
    await db.collection('liveLocations').doc(assignment.busId).delete();

    // Notify via Socket.io (handled in socket/tracking.js)
    const io = req.app.get('io');
    if (io) {
      io.emit('bus:offline', { busId: assignment.busId });
    }

    await sendTransitNotification({
      type: 'trip_completed',
      title: 'Trip Completed',
      body: `${assignment.busNumber || assignment.busId} has completed the current trip.`,
      routeId: assignment.routeId || null,
      busId: assignment.busId,
      audience: 'passenger',
      dedupeKey: `assignment:stop:${assignment.busId}:${req.params.id}`,
    });

    res.json({ message: 'Assignment deactivated, tracking stopped' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

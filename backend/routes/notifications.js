const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { roleCheck } = require('../middleware/roleCheck');
const { sendTransitNotification } = require('../services/notifications');

router.post('/token', verifyToken, async (req, res) => {
  try {
    const { token, role, platform } = req.body;
    if (!token) {
      return res.status(400).json({ error: 'token is required' });
    }

    await db.collection('notificationTokens').doc(token).set({
      token,
      uid: req.user.uid,
      role: role || req.user.role,
      platform: platform || 'flutter',
      isActive: true,
      updatedAt: new Date().toISOString(),
    }, { merge: true });

    res.json({ message: 'Token synced' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/token', verifyToken, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ error: 'token is required' });
    }

    await db.collection('notificationTokens').doc(token).set({
      isActive: false,
      updatedAt: new Date().toISOString(),
    }, { merge: true });

    res.json({ message: 'Token removed' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/history', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('alerts').orderBy('timestamp', 'desc').limit(50).get();
    const alerts = snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    res.json({ alerts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/trip-event', verifyToken, roleCheck('driver', 'admin'), async (req, res) => {
  try {
    const { type, busId, busNumber, routeId, routeName, nextStop, etaMinutes } = req.body;
    if (!type || !busId || !busNumber || !routeId || !routeName) {
      return res.status(400).json({ error: 'type, busId, busNumber, routeId and routeName are required' });
    }

    let title = 'Transit Update';
    let body = `${routeName} is updating live.`;
    let audience = 'passenger';

    switch (type) {
      case 'trip_started':
        title = 'Trip Started';
        body = `${routeName} (${busNumber}) is now live${nextStop ? `. Next stop: ${nextStop}` : ''}.`;
        break;
      case 'upcoming_stop':
        title = 'Upcoming Stop';
        body = `${routeName} (${busNumber}) approaching ${nextStop || 'the next stop'}${etaMinutes ? ` in ${etaMinutes} min` : ''}.`;
        break;
      case 'delay':
        title = 'Trip Delay';
        body = `${routeName} (${busNumber}) is delayed${etaMinutes ? ` by about ${etaMinutes} min` : ''}${nextStop ? `. Next stop: ${nextStop}` : ''}.`;
        break;
      case 'trip_completed':
        title = 'Trip Completed';
        body = `${routeName} (${busNumber}) has completed its trip.`;
        break;
      default:
        break;
    }

    const result = await sendTransitNotification({
      type,
      title,
      body,
      routeId,
      busId,
      etaMinutes: etaMinutes || null,
      nextStop: nextStop || null,
      audience,
      dedupeKey: `${type}:${busId}:${nextStop || 'none'}:${etaMinutes || 'na'}`,
    });

    await db.collection('tripEvents').add({
      uid: req.user.uid,
      type,
      busId,
      busNumber,
      routeId,
      routeName,
      nextStop: nextStop || null,
      etaMinutes: etaMinutes || null,
      createdAt: new Date().toISOString(),
    });

    res.json({ message: 'Trip event sent', result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/broadcast', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const {
      title,
      body,
      audience = 'all',
      type = 'service_update',
      routeId = null,
      busId = null,
    } = req.body;

    if (!title || !body) {
      return res.status(400).json({ error: 'title and body are required' });
    }

    if (!['all', 'passenger', 'driver', 'admin'].includes(audience)) {
      return res.status(400).json({ error: 'audience must be all, passenger, driver, or admin' });
    }

    const result = await sendTransitNotification({
      type,
      title,
      body,
      routeId,
      busId,
      audience,
      dedupeKey: `admin:broadcast:${audience}:${title}:${body}:${routeId || 'none'}:${busId || 'none'}`,
    });

    await db.collection('adminBroadcasts').add({
      title,
      body,
      audience,
      type,
      routeId,
      busId,
      createdBy: req.user.uid,
      createdAt: new Date().toISOString(),
    });

    res.json({ message: 'Broadcast sent', result });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

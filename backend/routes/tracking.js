const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { roleCheck } = require('../middleware/roleCheck');

/**
 * GET /api/tracking/live — Get all active bus positions (Any user)
 */
router.get('/live', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('liveLocations')
      .where('isOnline', '==', true)
      .get();
    const positions = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ positions });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/tracking/bus/:busId — Get specific bus position
 */
router.get('/bus/:busId', verifyToken, async (req, res) => {
  try {
    const doc = await db.collection('liveLocations').doc(req.params.busId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Bus not currently tracked' });
    }
    res.json({ position: doc.data() });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/tracking/history/:busId — Location history (Admin only)
 */
router.get('/history/:busId', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const snapshot = await db.collection('locationLogs')
      .where('busId', '==', req.params.busId)
      .orderBy('timestamp', 'desc')
      .limit(100)
      .get();
    const logs = snapshot.docs.map(doc => doc.data());
    res.json({ history: logs });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

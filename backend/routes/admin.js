const express = require('express');

const router = express.Router();

const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { roleCheck } = require('../middleware/roleCheck');
const {
  getDemoAssignments,
  getDemoBuses,
  getDemoLivePositions,
  getDemoRoutes,
} = require('../services/demoTransit');

router.get('/dashboard', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const [busSnapshot, routeSnapshot, userSnapshot, assignmentSnapshot, alertSnapshot, liveSnapshot] =
      await Promise.all([
        db.collection('buses').get(),
        db.collection('routes').get(),
        db.collection('users').get(),
        db.collection('assignments').where('isActive', '==', true).get(),
        db.collection('alerts').orderBy('timestamp', 'desc').limit(5).get().catch(() => ({ docs: [] })),
        db.collection('liveLocations').where('isOnline', '==', true).get(),
      ]);

    const realBuses = busSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    const realRoutes = routeSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    const users = userSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    const realAssignments = assignmentSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    const realLive = liveSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
    const recentAlerts = (alertSnapshot.docs || []).map((doc) => ({ id: doc.id, ...doc.data() }));

    const demoBuses = getDemoBuses();
    const demoRoutes = getDemoRoutes();
    const demoAssignments = getDemoAssignments();
    const demoLive = getDemoLivePositions();

    res.json({
      summary: {
        totalBuses: realBuses.filter((bus) => bus.status !== 'inactive').length + demoBuses.length,
        realBuses: realBuses.filter((bus) => bus.status !== 'inactive').length,
        demoBuses: demoBuses.length,
        totalRoutes: realRoutes.filter((route) => route.isActive !== false).length + demoRoutes.length,
        drivers: users.filter((user) => user.role === 'driver' && user.isActive !== false).length,
        passengers: users.filter((user) => user.role === 'passenger' && user.isActive !== false).length,
        admins: users.filter((user) => user.role === 'admin' && user.isActive !== false).length,
        activeAssignments: realAssignments.length + demoAssignments.length,
        liveBuses: realLive.length + demoLive.length,
        recentAlerts,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

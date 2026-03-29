const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { roleCheck } = require('../middleware/roleCheck');
const { getDemoRoutes, mergeRecords } = require('../services/demoTransit');

/**
 * GET /api/routes — List all transit routes (any authenticated user)
 */
router.get('/', verifyToken, async (req, res) => {
  try {
    const includeInactive = req.query.includeInactive === 'true';
    const includeDemo = req.query.includeDemo !== 'false';
    const snapshot = await db.collection('routes')
      .get();

    const realRoutes = snapshot.docs
      .map(doc => ({ id: doc.id, source: 'real', isDemo: false, readOnly: false, ...doc.data() }))
      .filter((route) => includeInactive || route.isActive !== false);

    const routes = includeDemo
      ? mergeRecords(realRoutes, getDemoRoutes())
      : realRoutes;

    res.json({ routes });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/routes — Create a route (Admin only)
 */
router.post('/', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const { name, shortName, colorIndex, stops, pathPoints } = req.body;

    if (!name || !shortName) {
      return res.status(400).json({ error: 'name and shortName are required' });
    }

    const routeData = {
      name,
      shortName,
      colorIndex: colorIndex || 0,
      stops: stops || [],
      pathPoints: pathPoints || [],
      isActive: true,
      createdAt: new Date().toISOString(),
    };

    const docRef = await db.collection('routes').add(routeData);
    res.status(201).json({ id: docRef.id, ...routeData });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PATCH /api/routes/:id — Update route (Admin only)
 */
router.patch('/:id', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    if (req.params.id.startsWith('demo_')) {
      return res.status(400).json({ error: 'Demo routes are read-only' });
    }

    const updates = {};
    const allowed = ['name', 'shortName', 'colorIndex', 'stops', 'pathPoints', 'isActive'];
    allowed.forEach(field => {
      if (req.body[field] !== undefined) updates[field] = req.body[field];
    });
    updates.updatedAt = new Date().toISOString();

    await db.collection('routes').doc(req.params.id).update(updates);
    res.json({ message: 'Route updated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:id', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    if (req.params.id.startsWith('demo_')) {
      return res.status(400).json({ error: 'Demo routes cannot be deleted' });
    }

    await db.collection('routes').doc(req.params.id).update({
      isActive: false,
      updatedAt: new Date().toISOString(),
    });
    res.json({ message: 'Route archived' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

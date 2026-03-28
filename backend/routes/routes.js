const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { roleCheck } = require('../middleware/roleCheck');

/**
 * GET /api/routes — List all transit routes (any authenticated user)
 */
router.get('/', verifyToken, async (req, res) => {
  try {
    const snapshot = await db.collection('routes')
      .where('isActive', '==', true)
      .get();
    const routes = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
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

module.exports = router;

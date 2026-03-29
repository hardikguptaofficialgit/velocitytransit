const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { roleCheck } = require('../middleware/roleCheck');
const { getDemoBuses, mergeRecords } = require('../services/demoTransit');


/**
 * GET /api/buses — List all buses
 */
router.get('/', verifyToken, async (req, res) => {
  try {
    const includeInactive = req.query.includeInactive === 'true';
    const includeDemo = req.query.includeDemo !== 'false';

    const snapshot = await db.collection('buses').get();
    const realBuses = snapshot.docs
      .map(doc => ({ id: doc.id, source: 'real', isDemo: false, readOnly: false, ...doc.data() }))
      .filter((bus) => includeInactive || bus.status !== 'inactive');

    const buses = includeDemo
      ? mergeRecords(realBuses, getDemoBuses())
      : realBuses;

    res.json({ buses });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/buses — Create a bus (Admin only)
 */
router.post('/', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const { busNumber, routeId, capacity } = req.body;

    if (!busNumber) {
      return res.status(400).json({ error: 'busNumber is required' });
    }

    const busData = {
      busNumber,
      routeId: routeId || null,
      capacity: capacity || 40,
      status: 'active',
      createdAt: new Date().toISOString(),
    };

    const docRef = await db.collection('buses').add(busData);
    res.status(201).json({ id: docRef.id, ...busData });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PATCH /api/buses/:id — Update a bus (Admin only)
 */
router.patch('/:id', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const { id } = req.params;
    if (id.startsWith('demo_')) {
      return res.status(400).json({ error: 'Demo buses are read-only' });
    }

    const updates = {};
    
    const allowed = ['busNumber', 'routeId', 'capacity', 'status'];
    allowed.forEach(field => {
      if (req.body[field] !== undefined) updates[field] = req.body[field];
    });
    updates.updatedAt = new Date().toISOString();

    await db.collection('buses').doc(id).update(updates);
    res.json({ message: 'Bus updated', id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * DELETE /api/buses/:id — Deactivate a bus (Admin only)
 */
router.delete('/:id', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    if (req.params.id.startsWith('demo_')) {
      return res.status(400).json({ error: 'Demo buses cannot be deactivated' });
    }

    await db.collection('buses').doc(req.params.id).update({ 
      status: 'inactive',
      updatedAt: new Date().toISOString(),
    });
    res.json({ message: 'Bus deactivated' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

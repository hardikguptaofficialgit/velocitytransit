const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { roleCheck } = require('../middleware/roleCheck');


/**
 * GET /api/users — List all users (Admin only)
 * Query: ?role=driver to filter by role
 */
router.get('/', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    let query = db.collection('users');
    if (req.query.role) {
      query = query.where('role', '==', req.query.role);
    }
    const snapshot = await query.get();
    const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ users });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * PATCH /api/users/:uid/role — Change user role (Admin only)
 * Body: { role: 'driver' | 'passenger' }
 */
router.patch('/:uid/role', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const { uid } = req.params;
    const { role } = req.body;

    if (!['passenger', 'driver'].includes(role)) {
      return res.status(400).json({ error: 'Role must be passenger or driver' });
    }

    await db.collection('users').doc(uid).update({ 
      role, 
      updatedAt: new Date().toISOString() 
    });

    res.json({ message: `User ${uid} role updated to ${role}` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/users/drivers — List all drivers (Admin only)
 */
router.get('/drivers', verifyToken, roleCheck('admin'), async (req, res) => {
  try {
    const snapshot = await db.collection('users')
      .where('role', '==', 'driver')
      .where('isActive', '==', true)
      .get();
    const drivers = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    res.json({ drivers });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/me', verifyToken, async (req, res) => {
  try {
    const updates = {};
    if (req.body.name !== undefined) updates.name = req.body.name;
    if (req.body.phone !== undefined) updates.phone = req.body.phone;
    updates.updatedAt = new Date().toISOString();

    await db.collection('users').doc(req.user.uid).set(updates, { merge: true });
    const updated = await db.collection('users').doc(req.user.uid).get();
    res.json({ user: { id: updated.id, ...updated.data() } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

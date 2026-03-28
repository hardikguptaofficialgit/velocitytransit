const express = require('express');
const router = express.Router();
const { db, auth } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');

/**
 * ROLE RULES (STRICT):
 * ═══════════════════
 * 1. Web UI users → ALWAYS 'admin'
 *    - The admin_web sends source=admin_web when calling /api/auth/me
 *    - If a user logs in via the web panel, they are auto-promoted to admin
 *
 * 2. Mobile App users → DEFAULT 'passenger'
 *    - All app logins default to 'passenger'
 *    - Only an admin (via the web panel) can promote them to 'driver'
 *
 * 3. Role hierarchy: admin > driver > passenger
 *    - Admins can manage buses, drivers, and assignments
 *    - Drivers can receive assignments and send GPS data
 *    - Passengers can view live bus positions
 */

/**
 * POST /api/auth/register
 * Register a new user. Firebase Auth handles the actual creation on the client side.
 * This endpoint creates the Firestore user profile doc.
 * Query: ?source=admin_web → registers as admin
 *        default           → registers as passenger
 */
router.post('/register', verifyToken, async (req, res) => {
  try {
    const { uid, email, name } = req.user;
    const { phone } = req.body;
    const source = req.query.source || req.body.source || '';

    const userRef = db.collection('users').doc(uid);
    const existing = await userRef.get();

    if (existing.exists) {
      const existingData = existing.data();
      // If logging in from admin_web and role isn't already admin, upgrade
      if (source === 'admin_web' && existingData.role !== 'admin') {
        await userRef.update({ role: 'admin', updatedAt: new Date().toISOString() });
        return res.json({ user: { ...existingData, role: 'admin' }, message: 'Upgraded to admin' });
      }
      return res.json({ user: existingData, message: 'User already exists' });
    }

    // Determine role based on source
    const role = source === 'admin_web' ? 'admin' : 'passenger';

    const userData = {
      uid,
      email,
      name: name || email.split('@')[0],
      phone: phone || '',
      role,
      avatar: req.user.picture || '',
      isActive: true,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    await userRef.set(userData);
    res.status(201).json({ user: userData });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: err.message });
  }
});

/**
 * GET /api/auth/me
 * Get current user's profile from Firestore.
 * Query: ?source=admin_web → auto-creates/upgrades as admin
 *        default           → auto-creates as passenger
 */
router.get('/me', verifyToken, async (req, res) => {
  try {
    const source = req.query.source || '';
    const userDoc = await db.collection('users').doc(req.user.uid).get();
    
    if (!userDoc.exists) {
      // Auto-create profile on first login
      // Role depends on WHERE they're logging in from
      const role = source === 'admin_web' ? 'admin' : 'passenger';

      const userData = {
        uid: req.user.uid,
        email: req.user.email,
        name: req.user.name || req.user.email.split('@')[0],
        phone: '',
        role,
        avatar: req.user.picture || '',
        isActive: true,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      await db.collection('users').doc(req.user.uid).set(userData);
      console.log(`[Auth] New ${role} created: ${userData.name} (${userData.uid})`);
      return res.json({ user: userData });
    }

    const existingData = userDoc.data();

    // If logging in from admin_web and user isn't already admin, auto-upgrade
    if (source === 'admin_web' && existingData.role !== 'admin') {
      const previousRole = existingData.role;
      await db.collection('users').doc(req.user.uid).update({ 
        role: 'admin', 
        updatedAt: new Date().toISOString() 
      });
      console.log(`[Auth] ${existingData.name} upgraded: ${previousRole} → admin (logged in via web panel)`);
      return res.json({ user: { ...existingData, role: 'admin' } });
    }

    res.json({ user: existingData });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

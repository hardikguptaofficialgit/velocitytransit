const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');
const { verifyToken } = require('../middleware/auth');
const { isAdminEmail, resolveDefaultRole } = require('../config/access');

function buildUserProfile(req, role, options = {}) {
  const { phone = '', name } = options;
  return {
    uid: req.user.uid,
    email: req.user.email,
    name: name || req.user.name || req.user.email.split('@')[0],
    phone,
    role,
    avatar: req.user.picture || '',
    isActive: true,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  };
}

function canAccessAdminWeb(profile, source) {
  if (source !== 'admin_web') return true;
  return profile.role === 'admin';
}

router.post('/register', verifyToken, async (req, res) => {
  try {
    const source = req.query.source || req.body.source || '';
    const { uid, email } = req.user;
    const { phone, name } = req.body;

    const userRef = db.collection('users').doc(uid);
    const existing = await userRef.get();

    if (existing.exists) {
      const existingData = existing.data();
      if (!canAccessAdminWeb(existingData, source)) {
        return res.status(403).json({ error: 'Admin access required' });
      }
      return res.json({ user: existingData, message: 'User already exists' });
    }

    const role = resolveDefaultRole({ email, source });
    if (source === 'admin_web' && role !== 'admin') {
      return res.status(403).json({
        error: 'Admin access required. Add this email to ADMIN_EMAILS to allow admin web login.',
      });
    }

    const userData = buildUserProfile(req, role, { phone: phone || '', name });
    await userRef.set(userData);

    res.status(201).json({ user: userData });
  } catch (err) {
    console.error('Registration error:', err);
    res.status(500).json({ error: err.message });
  }
});

router.get('/me', verifyToken, async (req, res) => {
  try {
    const source = req.query.source || '';
    const userRef = db.collection('users').doc(req.user.uid);
    const userDoc = await userRef.get();

    if (!userDoc.exists) {
      const role = resolveDefaultRole({ email: req.user.email, source });
      if (source === 'admin_web' && role !== 'admin') {
        return res.status(403).json({
          error: 'Admin access required. Add this email to ADMIN_EMAILS to allow admin web login.',
        });
      }

      const userData = buildUserProfile(req, role);
      await userRef.set(userData);
      return res.json({ user: userData });
    }

    const existingData = userDoc.data();
    if (existingData.role !== 'admin' && isAdminEmail(req.user.email)) {
      const upgradedUser = {
        ...existingData,
        role: 'admin',
        updatedAt: new Date().toISOString(),
      };
      await userRef.set(upgradedUser, { merge: true });
      return res.json({ user: upgradedUser });
    }

    if (!canAccessAdminWeb(existingData, source)) {
      return res.status(403).json({ error: 'Admin access required' });
    }

    res.json({ user: existingData });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

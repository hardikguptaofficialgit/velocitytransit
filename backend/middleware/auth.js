const { auth, db } = require('../config/firebase');

/**
 * Verify Firebase ID token from Authorization header.
 * Attaches decoded user info + Firestore role to req.user
 */
async function verifyToken(req, res, next) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = header.split('Bearer ')[1];
  try {
    const decoded = await auth.verifyIdToken(token);
    
    // Fetch user role from Firestore
    const userDoc = await db.collection('users').doc(decoded.uid).get();
    
    req.user = {
      uid: decoded.uid,
      email: decoded.email,
      name: decoded.name || decoded.email,
      role: userDoc.exists ? userDoc.data().role : 'passenger',
      ...decoded,
    };
    
    next();
  } catch (err) {
    console.error('Token verification failed:', err.message);
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = { verifyToken };

const { admin, db } = require('../config/firebase');

async function saveAlert({
  type,
  title,
  body,
  routeId = null,
  busId = null,
  etaMinutes = null,
  nextStop = null,
  audience = 'all',
  dedupeKey = null,
}) {
  if (dedupeKey) {
    const existing = await db.collection('alerts').where('dedupeKey', '==', dedupeKey).limit(1).get();
    if (!existing.empty) {
      return existing.docs[0].id;
    }
  }

  const doc = await db.collection('alerts').add({
    type,
    title,
    body,
    routeId,
    busId,
    etaMinutes,
    nextStop,
    audience,
    dedupeKey,
    isRead: false,
    timestamp: new Date().toISOString(),
  });
  return doc.id;
}

async function sendTransitNotification({
  type,
  title,
  body,
  routeId = null,
  busId = null,
  etaMinutes = null,
  nextStop = null,
  audience = 'all',
  dedupeKey = null,
}) {
  const alertId = await saveAlert({
    type,
    title,
    body,
    routeId,
    busId,
    etaMinutes,
    nextStop,
    audience,
    dedupeKey,
  });

  const tokensSnapshot = await db.collection('notificationTokens').where('isActive', '==', true).get();
  const tokens = tokensSnapshot.docs
    .map((doc) => ({ id: doc.id, ...doc.data() }))
    .filter((entry) => {
      if (audience === 'all') return true;
      return entry.role === audience;
    })
    .map((entry) => entry.token)
    .filter(Boolean);

  if (!tokens.length) {
    return { alertId, sentCount: 0 };
  }

  const message = {
    notification: { title, body },
    data: {
      alertId,
      type,
      routeId: routeId || '',
      busId: busId || '',
      etaMinutes: etaMinutes == null ? '' : String(etaMinutes),
      nextStop: nextStop || '',
      title,
      body,
      clickAction: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'trip_updates',
        priority: 'max',
      },
    },
    apns: {
      headers: {
        'apns-priority': '10',
      },
      payload: {
        aps: {
          sound: 'default',
          contentAvailable: true,
        },
      },
    },
    tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    return { alertId, sentCount: response.successCount };
  } catch (error) {
    console.error('[Notifications] send failure:', error.message);
    return { alertId, sentCount: 0, error: error.message };
  }
}

module.exports = {
  saveAlert,
  sendTransitNotification,
};

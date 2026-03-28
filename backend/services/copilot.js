const { db } = require('../config/firebase');

const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

function resolveGeminiApiKey() {
  return (
    process.env.GEMINI_API_KEY ||
    process.env.GOOGLE_GEMINI_API_KEY ||
    process.env.GOOGLE_API_KEY ||
    ''
  ).trim();
}

async function loadTransitContext() {
  const [routesSnapshot, busesSnapshot, assignmentsSnapshot, liveSnapshot] =
    await Promise.all([
      db.collection('routes').limit(8).get(),
      db.collection('buses').limit(12).get(),
      db.collection('assignments').where('isActive', '==', true).limit(12).get(),
      db.collection('liveLocations').limit(12).get(),
    ]);

  const routes = routesSnapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      name: data.name || '',
      shortName: data.shortName || '',
      stopsCount: Array.isArray(data.stops) ? data.stops.length : 0,
      isActive: data.isActive !== false,
    };
  });

  const buses = busesSnapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      busNumber: data.busNumber || doc.id,
      routeId: data.routeId || '',
      status: data.status || 'active',
      capacity: data.capacity || null,
    };
  });

  const assignments = assignmentsSnapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      busId: data.busId || '',
      busNumber: data.busNumber || '',
      driverName: data.driverName || '',
      routeId: data.routeId || '',
    };
  });

  const liveLocations = liveSnapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      busId: doc.id,
      busNumber: data.busNumber || '',
      routeId: data.routeId || '',
      speed: typeof data.speed === 'number' ? data.speed : 0,
      isOnline: data.isOnline === true,
      lastUpdated: data.lastUpdated || null,
    };
  });

  return {
    routes,
    buses,
    assignments,
    liveLocations,
  };
}

function buildSystemPrompt({ context, question, history, user }) {
  const compactHistory = history
    .slice(-6)
    .map((message) => ({
      role: message.role,
      text: message.text,
    }));

  return `
You are Velocity Copilot, a transit assistant inside the VelocityTransit app.

Your job:
- Answer clearly and practically for bus riders and drivers.
- Use the provided transit context when it is relevant.
- If live data is missing, say so briefly instead of inventing facts.
- Prefer actionable answers: nearby options, likely next steps, tradeoffs, short comparisons.
- Keep answers concise but useful.
- If the user asks something unrelated to transit, maps, buses, routes, ETAs, tracking, or the app, politely redirect back to transit help.

Current authenticated user:
- uid: ${user.uid}
- email: ${user.email || 'unknown'}
- role: ${user.role || 'passenger'}

Recent conversation:
${JSON.stringify(compactHistory, null, 2)}

Transit context:
${JSON.stringify(context, null, 2)}

Latest user question:
${question}
  `.trim();
}

async function generateCopilotReply({ question, history = [], user }) {
  const apiKey = resolveGeminiApiKey();
  if (!apiKey) {
    throw new Error('Gemini API key is missing on the backend.');
  }

  const trimmedQuestion = `${question || ''}`.trim();
  if (!trimmedQuestion) {
    throw new Error('Question is required.');
  }

  const context = await loadTransitContext();
  const prompt = buildSystemPrompt({
    context,
    question: trimmedQuestion,
    history,
    user,
  });

  const response = await fetch(`${GEMINI_API_URL}?key=${encodeURIComponent(apiKey)}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: {
        temperature: 0.4,
        topP: 0.9,
        maxOutputTokens: 500,
      },
    }),
  });

  const payload = await response.json();
  if (!response.ok) {
    const apiMessage =
      payload?.error?.message || 'Gemini request failed on the backend.';
    throw new Error(apiMessage);
  }

  const text =
    payload?.candidates?.[0]?.content?.parts
      ?.map((part) => part.text || '')
      .join('')
      .trim() || '';

  if (!text) {
    throw new Error('Gemini returned an empty response.');
  }

  return {
    answer: text,
    contextSummary: {
      routes: context.routes.length,
      buses: context.buses.length,
      activeAssignments: context.assignments.length,
      liveLocations: context.liveLocations.length,
    },
  };
}

module.exports = {
  generateCopilotReply,
  resolveGeminiApiKey,
};

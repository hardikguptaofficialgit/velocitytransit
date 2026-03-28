const express = require('express');

const { verifyToken } = require('../middleware/auth');
const { generateCopilotReply } = require('../services/copilot');

const router = express.Router();

router.post('/chat', verifyToken, async (req, res) => {
  try {
    const { question, history } = req.body || {};
    const reply = await generateCopilotReply({
      question,
      history: Array.isArray(history) ? history : [],
      user: req.user,
    });

    res.json(reply);
  } catch (error) {
    console.error('[Copilot] chat failed:', error.message);
    res.status(500).json({
      error: error.message || 'Copilot is unavailable right now.',
    });
  }
});

module.exports = router;

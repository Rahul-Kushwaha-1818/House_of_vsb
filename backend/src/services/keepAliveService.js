// keep render free server awake by pinging under 5 minutes
const https = require('https');
const http = require('http');

let timer = null;

// ping every 4 minutes (under 5 mins) so render doesn't sleep
const startKeepAlive = (intervalMs = 4 * 60 * 1000) => {
  const targetUrl = process.env.RENDER_EXTERNAL_URL || process.env.SERVER_URL || 'https://house-of-vsb.onrender.com';
  const cleanUrl = targetUrl.replace(/\/+$/, '');
  const healthUrl = cleanUrl + '/health';

  console.log('[Keep-Alive] Self-ping started for ' + healthUrl + ' (every ' + (intervalMs / 60000) + ' mins)');

  const doPing = () => {
    try {
      const client = healthUrl.startsWith('https') ? https : http;
      const req = client.get(healthUrl, (res) => {
        if (res.statusCode === 200) {
          console.log('[Keep-Alive] Ping ok at ' + new Date().toLocaleTimeString() + ' - server awake');
        } else {
          console.log('[Keep-Alive] Ping status: ' + res.statusCode);
        }
      });

      req.on('error', (err) => {
        // don't crash on network hiccup
        console.log('[Keep-Alive] Ping notice: ' + err.message);
      });

      req.setTimeout(15000, () => {
        req.destroy();
      });
    } catch (e) {
      console.log('[Keep-Alive] Ping error: ' + e.message);
    }
  };

  // first ping after 20 seconds
  setTimeout(doPing, 20000);

  // repeat every 4 minutes
  timer = setInterval(doPing, intervalMs);
};

const stopKeepAlive = () => {
  if (timer) {
    clearInterval(timer);
    timer = null;
    console.log('[Keep-Alive] Self-ping stopped');
  }
};

module.exports = { startKeepAlive, stopKeepAlive };
